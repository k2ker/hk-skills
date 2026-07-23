# Middleware Deprecated 패턴

Next.js 16에서 middleware.ts가 deprecated되고 proxy.ts로 대체되었습니다.

## Next.js 16 변경사항

### middleware.ts가 deprecated된 이유

**문제점:**

1. **네이밍 충돌:** `middleware.ts`라는 이름이 너무 일반적
2. **스코프 불명확:** 프로젝트 전체에 영향을 미치는지 불분명
3. **커스터마이징 어려움:** next-intl 같은 라이브러리와 통합 시 제약

**해결:**

- Next.js 16부터 `proxy.ts`로 변경
- 명확한 네이밍 + 확장 가능한 구조

---

## proxy.ts 마이그레이션

### Before: middleware.ts (❌ Deprecated)

```typescript
// middleware.ts
import createMiddleware from 'next-intl/middleware'

export default createMiddleware({
  locales: ['ko', 'en', 'ja'],
  defaultLocale: 'ko',
})

export const config = {
  matcher: ['/((?!api|_next|.*\\..*).*)'],
}
```

---

### After: proxy.ts (✅ 권장)

```typescript
// proxy.ts
import { NextRequest } from 'next/server'
import createMiddleware from 'next-intl/middleware'

const intl = createMiddleware({
  locales: ['ko', 'en', 'ja'],
  defaultLocale: 'ko',
  localePrefix: 'always', // URL에 항상 locale 포함
  localeDetection: true, // 브라우저 언어 자동 감지
})

export function proxy(request: NextRequest) {
  const response = intl(request)

  // 커스텀 로직 추가 가능
  const locale = request.nextUrl.pathname.split('/')[1]

  // locale 쿠키 설정
  if (['ko', 'en', 'ja'].includes(locale)) {
    response.cookies.set('NEXT_LOCALE', locale, {
      path: '/',
      maxAge: 60 * 60 * 24 * 365, // 1년
      sameSite: 'lax',
    })
  }

  // 응답 헤더 추가 (선택적)
  response.headers.set('X-Current-Locale', locale)

  return response
}

export const config = {
  // API, 정적 파일, 이미지 제외
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico|robots.txt|sitemap.xml).*)'],
}
```

**주요 변경:**

- `export default` → `export function proxy`
- 함수 내부에서 커스텀 로직 추가 가능
- 더 명확한 matcher 패턴

---

## 설정 파일 수정

### next.config.ts 업데이트

```typescript
// next.config.ts
import createNextIntlPlugin from 'next-intl/plugin'

// ❌ 기존: middleware.ts 참조
// const withNextIntl = createNextIntlPlugin('./i18n/request.ts');

// ✅ 변경: proxy.ts와 함께 사용
const withNextIntl = createNextIntlPlugin('./i18n/request.ts')

const nextConfig = {
  // 기타 설정...
}

export default withNextIntl(nextConfig)
```

**참고:** `createNextIntlPlugin`은 middleware/proxy 파일과 독립적으로 작동합니다. 설정 자체는 변경 불필요합니다.

---

### i18n/request.ts (변경 없음)

```typescript
// i18n/request.ts
import { getRequestConfig } from 'next-intl/server'
import { notFound } from 'next/navigation'

export const locales = ['ko', 'en', 'ja']

export default getRequestConfig(async ({ locale }) => {
  if (!locales.includes(locale as any)) notFound()

  return {
    messages: (await import(`../../messages/${locale}.json`)).default,
  }
})
```

**변경 사항:** 없음 (middleware/proxy와 독립적)

---

## 마이그레이션 체크리스트

### Step 1: 파일 생성 및 삭제

```bash
# 1. proxy.ts 생성
touch proxy.ts

# 2. middleware.ts 삭제 (백업 권장)
mv middleware.ts middleware.ts.backup
# 또는 완전 삭제
rm middleware.ts
```

---

### Step 2: proxy.ts 작성

위의 "After: proxy.ts" 코드를 복사하여 작성.

---

### Step 3: 코드베이스 검증

```bash
# middleware.ts import 검색 (있으면 안됨)
grep -r "from './middleware'" src/

# 결과가 없어야 정상
```

---

### Step 4: 빌드 및 테스트

```bash
# 빌드
npm run build

# 로컬 실행
npm run dev

# i18n 라우팅 테스트
# - /ko/dashboard 접속
# - /en/dashboard 접속
# - /ja/dashboard 접속
```

---

### Step 5: 체크리스트

- [ ] `middleware.ts` 파일 삭제
- [ ] `proxy.ts` 파일 생성
- [ ] proxy 함수 구현 (next-intl 통합)
- [ ] config.matcher 업데이트
- [ ] 빌드 에러 없음
- [ ] locale 라우팅 정상 작동
- [ ] 쿠키/헤더 로직 정상 작동 (커스텀 로직 있는 경우)

---

## Before/After 전체 비교

### Before (middleware.ts 사용)

**파일 구조:**

```
project/
├── middleware.ts          ← deprecated
├── i18n/
│   ├── navigation.ts
│   └── request.ts
└── next.config.ts
```

**middleware.ts:**

```typescript
import createMiddleware from 'next-intl/middleware'

export default createMiddleware({
  locales: ['ko', 'en', 'ja'],
  defaultLocale: 'ko',
})

export const config = {
  matcher: ['/((?!api|_next|.*\\..*).*)'],
}
```

**문제점:**

- 커스텀 로직 추가 어려움
- 네이밍이 모호함
- Next.js 16에서 deprecated

---

### After (proxy.ts 사용)

**파일 구조:**

```
project/
├── proxy.ts               ← 권장
├── i18n/
│   ├── navigation.ts
│   └── request.ts
└── next.config.ts
```

**proxy.ts:**

```typescript
import { NextRequest } from 'next/server'
import createMiddleware from 'next-intl/middleware'

const intl = createMiddleware({
  locales: ['ko', 'en', 'ja'],
  defaultLocale: 'ko',
  localePrefix: 'always',
})

export function proxy(request: NextRequest) {
  const response = intl(request)

  // 커스텀 로직
  const locale = request.nextUrl.pathname.split('/')[1]
  if (['ko', 'en', 'ja'].includes(locale)) {
    response.cookies.set('NEXT_LOCALE', locale, { path: '/' })
  }

  return response
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
}
```

**장점:**

- 커스텀 로직 추가 용이
- 명확한 네이밍
- Next.js 16 권장 패턴

---

## 추가 커스터마이징 예시

### 인증 체크 추가

```typescript
export function proxy(request: NextRequest) {
  const response = intl(request)

  // 로그인 필요 페이지 체크
  const protectedPaths = ['/dashboard', '/settings', '/profile']
  const { pathname } = request.nextUrl

  const isProtected = protectedPaths.some((path) => pathname.includes(path))

  if (isProtected) {
    const token = request.cookies.get('auth_token')

    if (!token) {
      // 로그인 페이지로 리다이렉트
      const locale = pathname.split('/')[1]
      return NextResponse.redirect(new URL(`/${locale}/login`, request.url))
    }
  }

  return response
}
```

---

### A/B 테스트 헤더 추가

```typescript
export function proxy(request: NextRequest) {
  const response = intl(request)

  // A/B 테스트 그룹 할당
  const abGroup = request.cookies.get('ab_test_group')?.value || (Math.random() > 0.5 ? 'A' : 'B')

  response.cookies.set('ab_test_group', abGroup, { path: '/' })
  response.headers.set('X-AB-Test-Group', abGroup)

  return response
}
```

---

## 주의사항

### 1. matcher 패턴

**잘못된 matcher:**

```typescript
// ❌ 너무 광범위 (API 포함)
matcher: ['/*']

// ❌ 정적 파일 포함
matcher: ['/(.*)']
```

**올바른 matcher:**

```typescript
// ✅ API, 정적 파일 제외
matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)']
```

---

### 2. 성능

proxy 함수는 모든 요청에서 실행되므로 **무거운 로직은 피하세요:**

```typescript
// ❌ 금지: 무거운 연산
export function proxy(request: NextRequest) {
  const data = await fetch('https://api.example.com/config') // 느림!
  // ...
}

// ✅ 권장: 가벼운 로직만
export function proxy(request: NextRequest) {
  const locale = request.nextUrl.pathname.split('/')[1] // 빠름
  // ...
}
```

---

## 결론

**핵심 요약:**

- Next.js 16: middleware.ts → proxy.ts
- 커스텀 로직 추가 가능
- 명확한 네이밍 + 확장성

**마이그레이션 필수!** Next.js 16 사용 시 middleware.ts는 작동하지 않습니다.
