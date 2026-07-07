# SSR + Hydration 패턴

Server-Side Rendering과 Hydration 에러를 안전하게 처리하는 패턴.

## SSR + Suspense 분리

### 핵심 원칙

**정적 컨텐츠**: 즉시 렌더링 (SSR)
**데이터 페칭**: Suspense로 스트리밍

**장점:**

- 빠른 First Contentful Paint (FCP)
- 점진적 렌더링
- 더 나은 사용자 경험

---

### 패턴 1: 정적 헤더 + 동적 컨텐츠

```tsx
// app/dashboard/page.tsx
import { Suspense } from 'react'
import { Header } from '@/components/Header'
import { DashboardContent } from '@/components/DashboardContent'
import { DashboardSkeleton } from '@/components/DashboardSkeleton'

export default async function DashboardPage() {
  return (
    <>
      {/* ✅ 정적 헤더: 즉시 표시 */}
      <Header />

      {/* ✅ 동적 컨텐츠: 스트리밍 */}
      <Suspense fallback={<DashboardSkeleton />}>
        <DashboardContent />
      </Suspense>
    </>
  )
}
```

**DashboardContent (Server Component):**

```tsx
// components/DashboardContent.tsx
import { getQueryClient } from '@/lib/react-query'
import { statsQueryOptions } from '@/api/stats/stats.queries'
import { HydrationBoundary, dehydrate } from '@tanstack/react-query'
import { StatsDisplay } from './StatsDisplay'

export async function DashboardContent() {
  const queryClient = getQueryClient()

  // 서버에서 데이터 페칭
  await queryClient.fetchQuery(statsQueryOptions.summary())

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <StatsDisplay />
    </HydrationBoundary>
  )
}
```

---

### 패턴 2: 중첩 Suspense

```tsx
// app/dashboard/page.tsx
import { Suspense } from 'react'

export default async function DashboardPage() {
  return (
    <div>
      <Header />

      {/* 각 영역을 독립적으로 스트리밍 */}
      <div className="grid grid-cols-2 gap-4">
        <Suspense fallback={<CardSkeleton />}>
          <StatsCard />
        </Suspense>

        <Suspense fallback={<CardSkeleton />}>
          <RecentActivity />
        </Suspense>
      </div>

      <Suspense fallback={<TableSkeleton />}>
        <UserTable />
      </Suspense>
    </div>
  )
}
```

**장점:**

- 각 영역이 준비되는 대로 표시
- 느린 쿼리가 전체 페이지를 막지 않음

---

## Hydration 안전 처리

### 문제: Hydration Mismatch

**발생 원인:**

- 서버 렌더링과 클라이언트 렌더링 결과가 다름
- 브라우저 전용 API 사용 (localStorage, window 등)
- 랜덤 값, 현재 시간 등 동적 값

**에러 예시:**

```
Warning: Text content did not match. Server: "Loading..." Client: "User: John"
Warning: Prop `className` did not match. Server: "theme-light" Client: "theme-dark"
```

---

### ❌ 잘못된 방법: isMounted 직접 구현

```tsx
// ❌ 금지: 모든 컴포넌트에서 반복
const [isMounted, setIsMounted] = useState(false)

useEffect(() => {
  setIsMounted(true)
}, [])

if (!isMounted) {
  return <div>Loading...</div>
}

return <div>{localStorage.getItem('theme')}</div>
```

**문제점:**

- 보일러플레이트 코드 반복
- 일관성 없음
- SSR 이점 상실

---

### ✅ 올바른 방법: Client 컴포넌트

**Step 1: Client 컴포넌트 구현**

```tsx
// components/Client.tsx
'use client'

import { useEffect, useState, type ReactNode } from 'react'

interface ClientProps {
  children: ReactNode
  fallback?: ReactNode
}

export default function Client({ children, fallback = null }: ClientProps) {
  const [isMounted, setIsMounted] = useState(false)

  useEffect(() => {
    setIsMounted(true)
  }, [])

  if (!isMounted) {
    return <>{fallback}</>
  }

  return <>{children}</>
}
```

---

**Step 2: 사용**

```tsx
// page.tsx (Server Component)
import Client from '@/components/Client'
import { ThemeSwitcher } from '@/components/ThemeSwitcher'

export default function SettingsPage() {
  return (
    <div>
      <h1>Settings</h1>

      {/* ✅ 클라이언트 전용 컴포넌트를 Client로 감싸기 */}
      <Client fallback={<div className="h-10 w-32 bg-gray-200 animate-pulse" />}>
        <ThemeSwitcher />
      </Client>
    </div>
  )
}
```

---

**Step 3: ThemeSwitcher 구현**

```tsx
// components/ThemeSwitcher.tsx
'use client'

export function ThemeSwitcher() {
  // ✅ 이제 안전하게 브라우저 API 사용 가능
  const [theme, setTheme] = useState(() => localStorage.getItem('theme') || 'light')

  const handleToggle = () => {
    const newTheme = theme === 'light' ? 'dark' : 'light'
    setTheme(newTheme)
    localStorage.setItem('theme', newTheme)
  }

  return <button onClick={handleToggle}>{theme === 'light' ? '🌙 Dark' : '☀️ Light'}</button>
}
```

---

### useEffect vs Client 컴포넌트 비교

| 항목          | useEffect 직접 사용 | Client 컴포넌트 |
| ------------- | ------------------- | --------------- |
| **코드 반복** | ❌ 매번 작성        | ✅ 한 번 구현   |
| **일관성**    | ❌ 팀마다 다름      | ✅ 표준화       |
| **fallback**  | ❌ 수동 관리        | ✅ 자동 처리    |
| **SSR 이점**  | ⚠️ 부분 상실        | ✅ 최대한 활용  |
| **유지보수**  | ❌ 어려움           | ✅ 쉬움         |

---

## 실전 예시

### 대시보드 페이지

```tsx
// app/dashboard/page.tsx
import { Suspense } from 'react'
import { Header } from '@/components/Header'
import { Navigation } from '@/components/Navigation'
import { StatsGrid } from '@/features/dashboard/StatsGrid'
import { RecentActivity } from '@/features/dashboard/RecentActivity'
import { UserSettings } from '@/features/dashboard/UserSettings'
import Client from '@/components/Client'
import { StatsGridSkeleton, RecentActivitySkeleton } from '@/features/dashboard/Skeletons'

export default async function DashboardPage() {
  return (
    <div className="min-h-screen">
      {/* 정적 헤더/네비게이션: 즉시 표시 */}
      <Header />
      <Navigation />

      <main className="container mx-auto p-6">
        {/* Stats Grid: 독립적으로 스트리밍 */}
        <Suspense fallback={<StatsGridSkeleton />}>
          <StatsGrid />
        </Suspense>

        {/* Recent Activity: 독립적으로 스트리밍 */}
        <Suspense fallback={<RecentActivitySkeleton />}>
          <RecentActivity />
        </Suspense>

        {/* 클라이언트 전용: localStorage 사용 */}
        <Client fallback={<div className="h-40 bg-gray-100 animate-pulse" />}>
          <UserSettings />
        </Client>
      </main>
    </div>
  )
}
```

---

### 프로필 페이지 (인증 필요)

```tsx
// app/profile/page.tsx
import { Suspense } from 'react'
import { redirect } from 'next/navigation'
import { getServerSession } from '@/lib/auth'
import { ProfileHeader } from '@/features/profile/ProfileHeader'
import { ProfileContent } from '@/features/profile/ProfileContent'
import { ProfileSkeleton } from '@/features/profile/ProfileSkeleton'
import Client from '@/components/Client'
import { ThemeSettings } from '@/features/profile/ThemeSettings'

export default async function ProfilePage() {
  // 서버에서 인증 체크
  const session = await getServerSession()

  if (!session) {
    redirect('/login')
  }

  return (
    <div>
      {/* 정적 헤더: 즉시 표시 */}
      <ProfileHeader user={session.user} />

      {/* 프로필 데이터: 스트리밍 */}
      <Suspense fallback={<ProfileSkeleton />}>
        <ProfileContent userId={session.user.id} />
      </Suspense>

      {/* 테마 설정: 클라이언트 전용 (localStorage) */}
      <Client>
        <ThemeSettings />
      </Client>
    </div>
  )
}
```

---

## 체크리스트

SSR/Hydration 작업 시 확인:

- [ ] 정적 컨텐츠와 동적 컨텐츠 분리
- [ ] 데이터 페칭이 필요한 부분 Suspense로 감싸기
- [ ] 브라우저 API 사용 시 Client 컴포넌트로 감싸기
- [ ] isMounted 직접 구현 안함
- [ ] Skeleton/Fallback UI 제공
- [ ] 중첩 Suspense로 독립적 스트리밍

---

## 추가 팁

### 1. Skeleton UI 디자인

```tsx
// components/Skeletons.tsx
export function CardSkeleton() {
  return (
    <div className="rounded-lg border p-4">
      <div className="h-6 w-32 bg-gray-200 animate-pulse rounded mb-2" />
      <div className="h-4 w-48 bg-gray-200 animate-pulse rounded" />
    </div>
  )
}

export function TableSkeleton() {
  return (
    <div className="space-y-2">
      {Array.from({ length: 5 }).map((_, i) => (
        <div key={i} className="h-12 bg-gray-200 animate-pulse rounded" />
      ))}
    </div>
  )
}
```

---

### 2. 로딩 상태 테스트

개발 중 느린 네트워크 시뮬레이션:

```tsx
// Server Component에서 지연 추가
await new Promise((resolve) => setTimeout(resolve, 2000)) // 2초 지연

// 이렇게 하면 Skeleton UI를 확인할 수 있음
```

---

### 3. Suspense 경계 설정

**너무 작은 Suspense:**

```tsx
// ❌ 모든 컴포넌트마다 Suspense (과도함)
<Suspense fallback={<Skeleton />}><Text /></Suspense>
<Suspense fallback={<Skeleton />}><Image /></Suspense>
<Suspense fallback={<Skeleton />}><Button /></Suspense>
```

**적절한 Suspense:**

```tsx
// ✅ 의미있는 단위로 그룹화
<Suspense fallback={<CardSkeleton />}>
  <Card>
    <Text />
    <Image />
    <Button />
  </Card>
</Suspense>
```

---

## 결론

**핵심 요약:**

- 정적 컨텐츠 = 즉시 표시 (SSR)
- 동적 컨텐츠 = Suspense 스트리밍
- 클라이언트 전용 = Client 컴포넌트

**금지:** isMounted 직접 구현
**권장:** Client 컴포넌트 재사용
