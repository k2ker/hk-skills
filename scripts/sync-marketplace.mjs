#!/usr/bin/env node
// hk-skills 마켓플레이스 파생 파일 동기화 + 구조 검증 (zero-dep, node 18+).
//
// SSOT(원본):
//   - plugins/<bundle>/skills/<skill>/SKILL.md  ← 스킬 존재/이름/설명
//   - plugins/<bundle>/.claude-plugin/plugin.json ← 번들 설명(description)
// 파생(이 스크립트가 재생성):
//   - .claude-plugin/marketplace.json  ← plugins[] name/source/description
//   - README.md                        ← 번들 표(마커 사이)
//
// 사용:
//   node scripts/sync-marketplace.mjs         # check: 드리프트/위반이면 exit 1 (파일 변경 안 함)
//   node scripts/sync-marketplace.mjs --fix   # 파생 파일 재작성 + git add
//
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

const FIX = process.argv.includes('--fix');
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const PLUGINS_DIR = path.join(ROOT, 'plugins');
const MARKETPLACE = path.join(ROOT, '.claude-plugin', 'marketplace.json');
const README = path.join(ROOT, 'README.md');
const README_START = '<!-- BUNDLES:START (auto: scripts/sync-marketplace.mjs) -->';
const README_END = '<!-- BUNDLES:END -->';

const errors = [];
const warnings = [];
const written = [];

const unquote = (s) => (s == null ? s : s.replace(/^["']|["']$/g, '').trim());

// front-matter의 key 값 추출. 세 형태 모두 지원:
//   key: value                 (인라인)
//   key: |  /  key: >          (블록 스칼라)
//   key:\n  indented lines...  (plain 멀티라인 스칼라)
function fmValue(fmLines, key) {
  const idx = fmLines.findIndex((l) => new RegExp(`^${key}:`).test(l));
  if (idx === -1) return null;
  const rest = fmLines[idx].slice(fmLines[idx].indexOf(':') + 1).trim();
  if (rest && !['|', '>', '|-', '>-', '|+', '>+'].includes(rest)) return unquote(rest);
  // 콜론 뒤가 비었거나 블록 지시자 → 들여쓴 연속줄을 수집(다음 top-level key에서 중단)
  const collected = [];
  for (let i = idx + 1; i < fmLines.length; i++) {
    const l = fmLines[i];
    if (l.trim() === '') { if (collected.length) collected.push(''); continue; }
    if (/^\S/.test(l)) break; // 들여쓰기 없음 = 다음 키
    collected.push(l.trim());
  }
  const joined = collected.join(' ').replace(/\s+/g, ' ').trim();
  return joined || null;
}

function readFrontmatter(md) {
  const m = md.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!m) return {};
  const fmLines = m[1].split('\n');
  return { name: fmValue(fmLines, 'name'), desc: fmValue(fmLines, 'description') };
}

function git(cmd) {
  try {
    return execSync(cmd, { cwd: ROOT, stdio: ['ignore', 'pipe', 'ignore'] }).toString();
  } catch {
    return null;
  }
}

// ---- 1. 파일시스템에서 번들/스킬 수집 + 검증 --------------------------------
if (!fs.existsSync(PLUGINS_DIR)) {
  console.error('plugins/ 디렉터리가 없다. hk-skills 루트에서 실행하라.');
  process.exit(1);
}

const bundleNames = fs
  .readdirSync(PLUGINS_DIR, { withFileTypes: true })
  .filter((d) => d.isDirectory())
  .map((d) => d.name)
  .sort();

const bundles = []; // { name, description, version, skills:[{dir,name,desc}] }
const skillNameOwners = new Map(); // skillName -> [bundle,...] (중복 검출)

for (const name of bundleNames) {
  const bdir = path.join(PLUGINS_DIR, name);
  const pjPath = path.join(bdir, '.claude-plugin', 'plugin.json');
  let description = '', version;
  if (!fs.existsSync(pjPath)) {
    errors.push(`[${name}] plugin.json 없음 (${path.relative(ROOT, pjPath)})`);
  } else {
    try {
      const pj = JSON.parse(fs.readFileSync(pjPath, 'utf8'));
      description = pj.description || '';
      version = pj.version;
      if (pj.name !== name) errors.push(`[${name}] plugin.json name="${pj.name}"이 디렉터리명과 불일치`);
      if (!description) warnings.push(`[${name}] plugin.json description 비어있음`);
    } catch (e) {
      errors.push(`[${name}] plugin.json 파싱 실패: ${e.message}`);
    }
  }

  const skillsDir = path.join(bdir, 'skills');
  const skills = [];
  if (fs.existsSync(skillsDir)) {
    for (const d of fs.readdirSync(skillsDir, { withFileTypes: true })) {
      if (!d.isDirectory()) continue;
      const smd = path.join(skillsDir, d.name, 'SKILL.md');
      if (!fs.existsSync(smd)) continue; // .gitkeep 등 placeholder는 스킬 아님
      const { name: fmName, desc } = readFrontmatter(fs.readFileSync(smd, 'utf8'));
      if (!fmName) errors.push(`[${name}/${d.name}] SKILL.md front-matter에 name 없음`);
      else if (fmName !== d.name) errors.push(`[${name}/${d.name}] front-matter name="${fmName}"이 디렉터리명과 불일치`);
      if (!desc) warnings.push(`[${name}/${d.name}] SKILL.md description 없음(스킬 매칭에 필요)`);
      const key = fmName || d.name;
      skillNameOwners.set(key, [...(skillNameOwners.get(key) || []), name]);
      skills.push({ dir: d.name, name: key, desc: desc || '' });
    }
  }
  skills.sort((a, b) => a.dir.localeCompare(b.dir));
  bundles.push({ name, description, version, skills });
}

for (const [skill, owners] of skillNameOwners) {
  if (owners.length > 1) errors.push(`스킬명 "${skill}" 중복(번들 ${owners.join(', ')}) — 마켓플레이스 전역에서 스킬명은 유일해야 함`);
}

// ---- 2. 파생 콘텐츠 생성 ----------------------------------------------------
// marketplace.json: 상위(name/owner)는 보존, plugins[]만 재생성(기존 순서 유지 + 신규 뒤에)
let marketplace;
try {
  marketplace = JSON.parse(fs.readFileSync(MARKETPLACE, 'utf8'));
} catch (e) {
  errors.push(`marketplace.json 읽기/파싱 실패: ${e.message}`);
  marketplace = { name: 'hk-skills', owner: { name: 'hk' }, plugins: [] };
}
const prevOrder = (marketplace.plugins || []).map((p) => p.name);
const orderedBundles = [
  ...prevOrder.filter((n) => bundleNames.includes(n)),
  ...bundleNames.filter((n) => !prevOrder.includes(n)),
];
marketplace.plugins = orderedBundles.map((n) => {
  const b = bundles.find((x) => x.name === n);
  return { name: n, source: `./plugins/${n}`, description: b.description };
});
const marketplaceOut = JSON.stringify(marketplace, null, 2) + '\n';

// README 번들 표
const tableRows = orderedBundles.map((n) => {
  const b = bundles.find((x) => x.name === n);
  return `| \`${n}\` | ${b.skills.length} | ${b.description} |`;
});
const tableBlock = [
  README_START,
  '| 번들(플러그인) | 스킬 수 | 설명 |',
  '|---|---|---|',
  ...tableRows,
  README_END,
].join('\n');

let readme = fs.readFileSync(README, 'utf8');
let readmeOut = readme;
const startIdx = readme.indexOf(README_START);
const endIdx = readme.indexOf(README_END);
if (startIdx === -1 || endIdx === -1) {
  errors.push(`README.md에 번들 표 마커(${README_START} / ${README_END})가 없다. 표를 이 마커로 감싸라.`);
} else {
  readmeOut = readme.slice(0, startIdx) + tableBlock + readme.slice(endIdx + README_END.length);
}

// ---- 3. 이전 커밋 대비 추가/수정/삭제 리포트 --------------------------------
const skillOf = (p) => {
  const m = p.match(/^plugins\/([^/]+)\/skills\/([^/]+)\/SKILL\.md$/);
  return m ? `${m[1]}:${m[2]}` : null;
};
const headList = git('git ls-tree -r --name-only HEAD -- plugins');
let diffReport = null;
if (headList != null) {
  const headSkills = new Set(headList.split('\n').map(skillOf).filter(Boolean));
  const curSkills = new Set(bundles.flatMap((b) => b.skills.map((s) => `${b.name}:${s.dir}`)));
  const added = [...curSkills].filter((x) => !headSkills.has(x)).sort();
  const removed = [...headSkills].filter((x) => !curSkills.has(x)).sort();
  const modFiles = (git('git diff --name-only HEAD -- plugins') || '').split('\n');
  const modified = [...new Set(modFiles.map(skillOf).filter(Boolean))]
    .filter((x) => headSkills.has(x) && curSkills.has(x))
    .sort();
  diffReport = { added, removed, modified };
}

// ---- 4. 적용/보고 -----------------------------------------------------------
const files = [
  { path: MARKETPLACE, next: marketplaceOut },
  { path: README, next: readmeOut },
];
const drifted = [];
for (const f of files) {
  const cur = fs.existsSync(f.path) ? fs.readFileSync(f.path, 'utf8') : null;
  if (cur !== f.next) drifted.push(f);
}

function rel(p) { return path.relative(ROOT, p); }

if (diffReport) {
  const { added, removed, modified } = diffReport;
  if (added.length || removed.length || modified.length) {
    console.log('이전 커밋(HEAD) 대비 스킬 변화:');
    if (added.length) console.log('  + 추가: ' + added.join(', '));
    if (removed.length) console.log('  - 삭제: ' + removed.join(', '));
    if (modified.length) console.log('  ~ 수정: ' + modified.join(', '));
  } else {
    console.log('이전 커밋 대비 스킬 추가/삭제/수정 없음.');
  }
}

if (warnings.length) {
  console.log('\n경고:');
  for (const w of warnings) console.log('  ! ' + w);
}

if (errors.length) {
  console.error('\n구조 검증 실패 — 커밋 중단:');
  for (const e of errors) console.error('  ✗ ' + e);
  process.exit(1);
}

if (drifted.length === 0) {
  console.log('\n파생 파일 동기화 상태 OK (marketplace.json / README.md).');
  process.exit(0);
}

if (!FIX) {
  console.error('\n파생 파일이 SSOT와 어긋남(드리프트):');
  for (const f of drifted) console.error('  ✗ ' + rel(f.path));
  console.error('→ `node scripts/sync-marketplace.mjs --fix`로 갱신하라.');
  process.exit(1);
}

for (const f of drifted) {
  fs.writeFileSync(f.path, f.next);
  written.push(rel(f.path));
}
const added = git(`git add ${written.map((p) => `"${p}"`).join(' ')}`);
console.log('\n파생 파일 갱신 + 스테이징:');
for (const p of written) console.log('  ✓ ' + p);
process.exit(0);
