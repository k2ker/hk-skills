# Server Component 패턴

Next.js App Router에서 async Server Component와 TanStack Query SSR 패턴.

## Async Server Component

### 기본 패턴

```tsx
// app/users/page.tsx (Server Component)
import { getQueryClient } from '@/lib/react-query'
import { userQueryOptions } from '@/api/user/user.queries'
import { HydrationBoundary, dehydrate } from '@tanstack/react-query'
import { UserList } from '@/components/UserList'

export default async function UsersPage() {
  const queryClient = getQueryClient()

  // ✅ 서버에서 데이터 페칭
  await queryClient.fetchQuery(userQueryOptions.list())

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <UserList />
    </HydrationBoundary>
  )
}
```

**핵심:**

- `async function` 사용
- `await queryClient.fetchQuery()` 호출
- `HydrationBoundary`로 상태 전달
- `UserList`는 Client Component

---

### 에러 처리

```tsx
export default async function UsersPage() {
  const queryClient = getQueryClient()

  // ❌ 금지: 에러 핸들링 없음
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

**중요:** `prefetchQuery`는 에러를 throw하지 않으므로 `fetchQuery` + try/catch 사용.

---

## TanStack Query SSR

### fetchQuery vs prefetchQuery

| 비교          | fetchQuery            | prefetchQuery        |
| ------------- | --------------------- | -------------------- |
| **에러 처리** | ✅ throw (catch 가능) | ❌ 무시 (catch 불가) |
| **반환값**    | ✅ data 반환          | ❌ void (반환 없음)  |
| **사용 권장** | ✅ SSR에 권장         | ❌ SSR에 비권장      |

**예시:**

```tsx
// ❌ prefetchQuery: 에러 catch 불가
await queryClient.prefetchQuery(userQueryOptions.list())
// 에러 발생 시 아무 일도 안 일어남 (조용히 실패)

// ✅ fetchQuery: 에러 catch 가능
try {
  await queryClient.fetchQuery(userQueryOptions.list())
} catch (error) {
  // 에러 핸들링 가능
  console.error(error)
}
```

---

### HydrationBoundary 패턴

**역할:** 서버에서 페칭한 데이터를 클라이언트로 전달.

```tsx
// Server Component
import { HydrationBoundary, dehydrate } from '@tanstack/react-query'

export default async function Page() {
  const queryClient = getQueryClient()

  await queryClient.fetchQuery(userQueryOptions.list())

  // dehydrate: 캐시 상태를 직렬화
  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      {/* 클라이언트에서 캐시 복원 */}
      <UserList />
    </HydrationBoundary>
  )
}
```

---

```tsx
// Client Component
'use client'

import { useQuery } from '@tanstack/react-query'
import { userQueryOptions } from '@/api/user/user.queries'

export function UserList() {
  // ✅ 서버에서 페칭한 데이터가 자동으로 캐시에 있음
  const { data, isLoading } = useQuery(userQueryOptions.list())

  if (isLoading) return <div>Loading...</div>

  return (
    <ul>
      {data?.map((user) => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  )
}
```

---

### 에러 바운더리

```tsx
// app/users/error.tsx
'use client'

export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div>
      <h2>Something went wrong!</h2>
      <p>{error.message}</p>
      <button onClick={reset}>Try again</button>
    </div>
  )
}
```

**동작:**

- Server Component에서 에러 발생 시 자동으로 `error.tsx` 표시
- `reset()` 호출 시 페이지 재시도

---

## getQueryClient 구현

### 싱글톤 패턴

```typescript
// lib/react-query.ts
import { QueryClient } from '@tanstack/react-query'
import { cache } from 'react'

// ✅ React cache로 싱글톤 보장
export const getQueryClient = cache(
  () =>
    new QueryClient({
      defaultOptions: {
        queries: {
          staleTime: 60 * 1000, // 1분
          gcTime: 5 * 60 * 1000, // 5분 (구 cacheTime)
        },
      },
    }),
)
```

**중요:** `cache()`로 감싸서 요청당 하나의 QueryClient만 생성.

---

## 실전 예시

### 목록 페이지

```tsx
// app/users/page.tsx
import { Suspense } from 'react'
import { getQueryClient } from '@/lib/react-query'
import { userQueryOptions } from '@/api/user/user.queries'
import { HydrationBoundary, dehydrate } from '@tanstack/react-query'
import { UserList } from '@/features/users/UserList'
import { UserListSkeleton } from '@/features/users/UserListSkeleton'
import { Header } from '@/components/Header'

export default async function UsersPage() {
  return (
    <div>
      {/* 정적 헤더 */}
      <Header title="Users" />

      {/* 동적 목록 (Suspense) */}
      <Suspense fallback={<UserListSkeleton />}>
        <UsersContent />
      </Suspense>
    </div>
  )
}

async function UsersContent() {
  const queryClient = getQueryClient()

  try {
    await queryClient.fetchQuery(userQueryOptions.list())
  } catch (error) {
    console.error('Failed to fetch users:', error)
  }

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <UserList />
    </HydrationBoundary>
  )
}
```

---

### 상세 페이지

```tsx
// app/users/[id]/page.tsx
import { getQueryClient } from '@/lib/react-query'
import { userQueryOptions } from '@/api/user/user.queries'
import { HydrationBoundary, dehydrate } from '@tanstack/react-query'
import { UserProfile } from '@/features/users/UserProfile'
import { notFound } from 'next/navigation'

interface Props {
  params: { id: string }
}

export default async function UserDetailPage({ params }: Props) {
  const queryClient = getQueryClient()

  try {
    // 사용자 정보 페칭
    await queryClient.fetchQuery(userQueryOptions.detail(params.id))
  } catch (error) {
    // 404 처리
    if (error.response?.status === 404) {
      notFound()
    }
    throw error
  }

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <UserProfile userId={params.id} />
    </HydrationBoundary>
  )
}
```

---

### 중첩 레이아웃

```tsx
// app/dashboard/layout.tsx
import { getQueryClient } from '@/lib/react-query'
import { userQueryOptions } from '@/api/user/user.queries'
import { HydrationBoundary, dehydrate } from '@tanstack/react-query'
import { Sidebar } from '@/features/dashboard/Sidebar'

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const queryClient = getQueryClient()

  // 레이아웃에서 공통 데이터 페칭
  try {
    await queryClient.fetchQuery(userQueryOptions.me())
  } catch (error) {
    console.error('Failed to fetch user:', error)
  }

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <div className="flex">
        {/* 사이드바에서 user 데이터 사용 */}
        <Sidebar />

        {/* 페이지 컨텐츠 */}
        <main className="flex-1">{children}</main>
      </div>
    </HydrationBoundary>
  )
}
```

---

```tsx
// app/dashboard/stats/page.tsx
import { getQueryClient } from '@/lib/react-query'
import { statsQueryOptions } from '@/api/stats/stats.queries'
import { HydrationBoundary, dehydrate } from '@tanstack/react-query'
import { StatsDisplay } from '@/features/dashboard/StatsDisplay'

export default async function StatsPage() {
  const queryClient = getQueryClient()

  // 페이지별 데이터 추가 페칭
  try {
    await queryClient.fetchQuery(statsQueryOptions.summary())
  } catch (error) {
    console.error('Failed to fetch stats:', error)
  }

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      {/* user + stats 데이터 모두 사용 가능 */}
      <StatsDisplay />
    </HydrationBoundary>
  )
}
```

**장점:** 레이아웃에서 공통 데이터 한 번만 페칭, 하위 페이지에서 재사용.

---

## 체크리스트

Server Component 작업 시 확인:

- [ ] `async function` 사용
- [ ] `fetchQuery` (prefetchQuery 아님)
- [ ] try/catch 에러 처리
- [ ] `HydrationBoundary`로 상태 전달
- [ ] `getQueryClient`는 `cache()` 싱글톤
- [ ] `error.tsx` 에러 바운더리 구현

---

## 추가 팁

### 1. Parallel Queries

여러 쿼리를 동시에 실행:

```tsx
export default async function Page() {
  const queryClient = getQueryClient()

  // ✅ 병렬 실행
  await Promise.all([
    queryClient.fetchQuery(userQueryOptions.me()),
    queryClient.fetchQuery(statsQueryOptions.summary()),
    queryClient.fetchQuery(notificationsQueryOptions.list()),
  ])

  // ...
}
```

---

### 2. Conditional Fetching

조건에 따라 페칭:

```tsx
export default async function Page({ params }: Props) {
  const queryClient = getQueryClient()

  // 항상 페칭
  await queryClient.fetchQuery(userQueryOptions.me())

  // 조건부 페칭
  if (params.includeDrafts === 'true') {
    await queryClient.fetchQuery(draftsQueryOptions.list())
  }

  // ...
}
```

---

### 3. 캐시 무효화

```tsx
// Server Action에서
'use server'

import { revalidatePath } from 'next/cache'

export async function updateUser(userId: string, data: UserData) {
  await api.updateUser(userId, data)

  // ✅ 캐시 무효화
  revalidatePath(`/users/${userId}`)
  revalidatePath('/users') // 목록도 무효화
}
```

---

## 결론

**핵심 요약:**

- async Server Component + fetchQuery
- try/catch 에러 처리 필수
- HydrationBoundary로 상태 전달
- getQueryClient는 cache() 싱글톤

**금지:** prefetchQuery (에러 무시)
**권장:** fetchQuery + try/catch
