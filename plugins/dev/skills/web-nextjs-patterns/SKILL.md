---
name: web-nextjs-patterns
description: Next.js App Router 컨벤션. SSR/Hydration, Suspense 분리, Server Component, Client 컴포넌트, 환경변수 설정. Next.js 작업 시 참조. (web-almigo에서 이식, 프로젝트 특화 부분 제거됨)
metadata:
  author: klleon
---

# Next.js 팀 컨벤션

Next.js 16 + React 19 프로젝트의 필수 패턴 및 안티패턴.

## 최신 API 확인

Next.js는 빠르게 진화하므로 작업 전 최신 문서를 확인하세요:

```
mcp__plugin_context7_context7__query-docs(libraryId="/vercel/next.js", query="App Router routing")
mcp__plugin_context7_context7__query-docs(libraryId="/vercel/next.js", query="Server Components data fetching")
mcp__plugin_context7_context7__query-docs(libraryId="/vercel/next.js", query="middleware")
```

---

## 상세 문서

| 문서                                                                       | 용도                                               |
| -------------------------------------------------------------------------- | -------------------------------------------------- |
| [references/routing-i18n.md](references/routing-i18n.md)                   | i18n 라우팅, next-intl, Link/useRouter/usePathname |
| [references/i18n-translation-keys.md](references/i18n-translation-keys.md) | 번역 키 네이밍 규칙, 네임스페이스, 타입 안전성     |
| [references/middleware-deprecated.md](references/middleware-deprecated.md) | middleware.ts → proxy.ts 마이그레이션              |
| [references/ssr-hydration.md](references/ssr-hydration.md)                 | SSR + Suspense 분리, Client 컴포넌트               |
| [references/server-components.md](references/server-components.md)         | async Server Component, fetchQuery 패턴            |
| [references/environment-variables.md](references/environment-variables.md) | next.config.ts env 설정                            |

---

## 금지 패턴 (Do/Don't)

| ❌ 금지                           | ✅ 권장                           | 이유                      |
| --------------------------------- | --------------------------------- | ------------------------- |
| `middleware.ts` 사용              | `proxy.ts` + next-intl            | Next.js 16에서 deprecated |
| `isMounted` 직접 구현             | `Client` 컴포넌트                 | Hydration 안전성          |
| `prefetchQuery` (SSR)             | `fetchQuery` + try/catch          | 에러 처리 안정성          |
| `import from 'next/link'`         | `import from '@/i18n/navigation'` | locale 유실 방지          |
| `import from 'next/navigation'`   | `import from '@/i18n/navigation'` | locale 유실 방지          |
| `process.env.NEW_KEY` (API Route) | `next.config.ts` env 추가         | 빌드 타임 주입 필수       |
| `__DEV__` (React Native 스타일)   | `process.env.NODE_ENV`            | Node.js 표준              |
| `router.push()` (로그아웃)        | `window.location.replace()`       | 캐시 완전 제거            |

---

## 추천 패턴 (Quick Reference)

### 1. SSR + Suspense 분리

```tsx
// app/dashboard/page.tsx
import { Suspense } from 'react'
import { Header } from '@/components/Header'
import { DashboardContent } from '@/components/DashboardContent'
import { DashboardSkeleton } from '@/components/DashboardSkeleton'

export default async function DashboardPage() {
  return (
    <>
      {/* 정적 헤더: 즉시 렌더링 (SSR) */}
      <Header />

      {/* 데이터 영역: 스트리밍으로 분리 (Suspense) */}
      <Suspense fallback={<DashboardSkeleton />}>
        <DashboardContent />
      </Suspense>
    </>
  )
}
```

**핵심:** 정적 컨텐츠는 즉시 표시, 데이터 페칭은 Suspense로 감싸 스켈레톤 표시.

---

### 2. Hydration 처리 (Client 컴포넌트)

```tsx
// ❌ 금지: isMounted 직접 구현
const [isMounted, setIsMounted] = useState(false)
useEffect(() => {
  setIsMounted(true)
}, [])

if (!isMounted) return null

// ✅ 권장: Client 컴포넌트 사용
import Client from '@/components/Client'

// page.tsx에서 클라이언트 전용 컴포넌트 감싸기
;<Client fallback={<LoadingSpinner />}>
  <ClientOnlyComponent />
</Client>
```

**핵심:** SSR/클라이언트 mismatch를 `Client` 컴포넌트로 추상화.

---

### 3. i18n 네비게이션

```tsx
// ❌ 금지: locale 유실
import Link from 'next/link'
import { useRouter } from 'next/navigation'

// ✅ 권장: locale 보존
import { Link } from '@/i18n/navigation'
import { useRouter } from '@/i18n/navigation'

function Navigation() {
  const router = useRouter()

  return (
    <>
      <Link href="/about">About</Link>
      <button onClick={() => router.push('/contact')}>Contact</button>
    </>
  )
}
```

**핵심:** `@/i18n/navigation`에서 import하여 locale 자동 처리.

---

### 4. Server Component 데이터 페칭

```tsx
// app/users/page.tsx
import { getQueryClient } from '@/lib/react-query'
import { userQueryOptions } from '@/api/user/user.queries'
import { HydrationBoundary, dehydrate } from '@tanstack/react-query'
import { UserList } from '@/components/UserList'

export default async function UsersPage() {
  const queryClient = getQueryClient()

  // ❌ 금지: prefetchQuery (에러 처리 없음)
  // await queryClient.prefetchQuery(userQueryOptions.list());

  // ✅ 권장: fetchQuery + try/catch
  try {
    await queryClient.fetchQuery(userQueryOptions.list())
  } catch (error) {
    console.error('Failed to fetch users:', error)
    // 에러는 클라이언트에서 처리 (error.tsx)
  }

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <UserList />
    </HydrationBoundary>
  )
}
```

**핵심:** `fetchQuery` + try/catch로 에러 안전성 확보.

---

### 5. proxy.ts 미들웨어

```tsx
// proxy.ts (middleware.ts 대체)
import { NextRequest } from 'next/server'
import createMiddleware from 'next-intl/middleware'

const intl = createMiddleware({
  locales: ['ko', 'en', 'ja'],
  defaultLocale: 'ko',
})

export function proxy(request: NextRequest) {
  const response = intl(request)

  // locale 쿠키 설정
  const locale = request.nextUrl.pathname.split('/')[1]
  if (['ko', 'en', 'ja'].includes(locale)) {
    response.cookies.set('NEXT_LOCALE', locale, { path: '/' })
  }

  return response
}

// next.config.ts에서 proxy 함수 사용
export default {
  experimental: {
    serverActions: {
      bodySizeLimit: '2mb',
    },
  },
}
```

**핵심:** Next.js 16에서 `middleware.ts` 대신 `proxy.ts` + next-intl 사용.

---

### 6. 환경변수 설정

```typescript
// next.config.ts
const nextConfig = {
  env: {
    API_BASE_URL: process.env.API_BASE_URL,
    ANALYTICS_ID: process.env.ANALYTICS_ID,
    // ⚠️ 새 환경변수 추가 시 반드시 여기 등록!
  },
}

export default nextConfig

// app/api/data/route.ts
export async function GET() {
  // ✅ next.config.ts에 등록된 변수만 사용 가능
  const apiUrl = process.env.API_BASE_URL

  const response = await fetch(`${apiUrl}/data`)
  return Response.json(await response.json())
}
```

**핵심:** API Route에서 환경변수 사용 시 `next.config.ts` env 객체 등록 필수.

---

## 개발환경 전용 기능

Next.js에서 개발환경에서만 기능을 노출하려면:

```tsx
// ✅ 올바른 방법
const isDev = process.env.NODE_ENV === 'development';

// 조건부 배열 요소 (nav items 등)
const navItems = [
  { id: 'home', label: '홈', href: '/' },
  ...(isDev ? [{ id: 'creator', label: '창작', href: '/creator' }] : []),
  { id: 'service', label: '고객센터', href: '/service' },
];

// 조건부 렌더링
{isDev && <DevOnlyComponent />}

// ❌ 금지: React Native 스타일 (Next.js에서 미지원)
if (__DEV__) { ... }
```

---

## 로그아웃 패턴

로그아웃 시 캐시된 상태를 완전히 제거하려면:

```tsx
import { useRouter } from '@/i18n/navigation'

function LogoutButton() {
  const router = useRouter()

  const handleLogout = async () => {
    await logout() // API 호출

    // ❌ 금지: router.push (캐시된 상태 남음)
    // router.push('/home');

    // ✅ 권장: 하드 리셋 (모든 상태 초기화)
    window.location.replace('/home')
  }

  return <button onClick={handleLogout}>로그아웃</button>
}
```

---

## 파일 구조

권장 Next.js 프로젝트 구조:

```
src/
├── app/[locale]/         # Next.js App Router with i18n
│   ├── layout.tsx        # Root layout
│   ├── page.tsx          # Home page
│   ├── dashboard/
│   │   ├── layout.tsx    # Dashboard layout
│   │   └── page.tsx      # Dashboard page
│   └── api/              # API Routes
├── components/
│   ├── ui/               # 재사용 UI 컴포넌트
│   └── Client.tsx        # Hydration wrapper
├── features/             # 기능 기반 모듈
├── i18n/
│   └── navigation.ts     # next-intl 라우팅 설정
├── lib/
│   └── react-query.ts    # TanStack Query 설정
└── proxy.ts              # next-intl 미들웨어
```

---

## 버전 확인

Next.js 버전 확인:

```bash
npm list next
# 또는
cat package.json | grep '"next"'
```

**중요:** 이 스킬은 Next.js 16+ 기준입니다. 15 이하 버전은 패턴이 다를 수 있습니다.

---

## 체크리스트

작업 전 확인:

- [ ] Next.js 16+ 사용 중인가?
- [ ] i18n 라우팅 필요한가? → `@/i18n/navigation` 설정
- [ ] SSR 최적화 필요한가? → Suspense 분리 패턴
- [ ] Hydration 에러 있나? → Client 컴포넌트
- [ ] 새 환경변수 추가했나? → next.config.ts env 등록
- [ ] middleware.ts 사용 중인가? → proxy.ts로 마이그레이션
