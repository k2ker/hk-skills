# 009 — 기록 컨벤션 구조 개선 (hk 0.18.0, 2026-09-08)

사용자 지적 4건을 반영한 재설계. **미커밋 — git-sync-guard 처분과 함께 랜딩 예정.**

## 지적된 결함과 수정

1. **v1/v2 분기가 우연한 과거 형태에 하드코딩** — "v1 = MEMORY.md + tech-notes"는 이 repo·gamescom의 형태였을 뿐 일반 개념이 아니다. `NOTES.md`만 있는 프로젝트는 "v1 아님 → 신규"로 오판돼 뼈대만 깔리고 원본이 방치되는 반쪽 상태가 됐다. → **판정을 `docs/log` 유무 하나로**, 라벨은 `active`/`legacy`.
2. **init·migrate 이원화** — 사용자가 두 번 실행하는 경험. → **`/hk:record:setup` 하나**로 통합, 내부에서 보충/적용 2모드 분기.
3. **MEMORY가 todolist화** — 내장 메모리 명세는 user·feedback·project·reference 4종인데 project(미결)만 담고 있었다. → 템플릿을 **미결 / 사용자·작업 방식 / 제약·함정 / 참조 / 인덱스** 5섹션으로.
4. **DECISIONS 필수 규정** — 결정도 조각(`type: decision`)으로 충분하고, D번호 참조 체계를 쓰는 프로젝트(gamescom)만 필요. → **선택으로 강등**, 기본은 MEMORY + 조각 2개.

## 재실행 안전성 (신규 명세)

`docs/log` 존재 = 적용 확정 → **조각은 절대 재처리하지 않는다**(박제 원칙 연장). 보충 모드가 하는 일은 비파괴뿐: 빠진 뼈대 추가, MEMORY에 없는 섹션 추가, **미이관 잔여는 보고만 하고 승인 후에만 처리**. 파괴적 작업은 명시 승인 + clean tree 전제.

## 실측 — 이미 적용된 프로젝트 현황(2026-09-08 스캔)

| 프로젝트 | 상태 |
|---|---|
| sdk(조각 25) · weblanding(7) | 깔끔 — tech-notes 0 |
| **gamescom develop(조각 66)** | **혼재** — tech-notes 314·memory/·archive/ 잔존, MEMORY 36KB |
| 워크트리 record-pilot(39) · test-sandbox(375) | 미커밋 파일럿 |

혼재가 생긴 이유: 구판 절차엔 "조각만 추가하고 레거시는 방치"를 막는 규칙이 없었다. 신규 명세의 보충 모드가 이 상태를 감지해 보고한다.

## 검증

plugin validate · sync · git-sync-guard 32/32 · 게이트 스모크(active/legacy/none 3분기) 전부 통과.
