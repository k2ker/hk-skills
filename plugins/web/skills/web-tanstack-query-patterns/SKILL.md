---
name: web-tanstack-query-patterns
description: TanStack Query + Axios 팀 컨벤션. Query Key 팩토리, queryOptions, Mutation, 캐시 갱신, Infinite Query, SSR Prefetch, Axios Instance 패턴. API/Query 작성 시 참조.
metadata:
  author: klleon
---

# TanStack Query 팀 컨벤션

## 최신 API 확인

코드 작성 전 Context7으로 최신 문서 확인:

```
mcp__context7__query-docs(libraryId="/tanstack/query", query="useQuery options")
mcp__context7__query-docs(libraryId="/tanstack/query", query="useMutation onSuccess")
```

---

## 상세 문서

| 문서                                                                 | 용도                                              |
| -------------------------------------------------------------------- | ------------------------------------------------- |
| [references/query-patterns.md](references/query-patterns.md)         | useQuery, useSuspenseQuery, useInfiniteQuery 상세 |
| [references/mutation-cache.md](references/mutation-cache.md)         | useMutation, 캐시 갱신 전략                       |
| [references/axios-architecture.md](references/axios-architecture.md) | Axios Instance, API Layer 구조                    |

---

## Query Key 팩토리 패턴

```typescript
// constants/queryKeys.ts
export const userKeys = {
  all: ['user'] as const,
  me: () => [...userKeys.all, 'me'] as const,
} as const

// 계층형 키 (상세 조회용)
export const itemKeys = {
  all: ['item'] as const,
  lists: () => [...itemKeys.all, 'list'] as const,
  list: (filters?: ItemFilters) => [...itemKeys.lists(), filters] as const,
  details: () => [...itemKeys.all, 'detail'] as const,
  detail: (id: string | undefined) => [...itemKeys.details(), id] as const,
} as const
```

### 규칙

- `as const` 필수 사용
- 계층 구조로 invalidation 범위 제어
- `undefined` 파라미터도 타입에 포함

---

## queryOptions 팩토리 패턴

```typescript
import { queryOptions } from '@tanstack/react-query'

export const userQueryOptions = {
  me: () =>
    queryOptions({
      queryKey: userKeys.me(),
      queryFn: async () => {
        const response = await getUser()
        return response.data
      },
      staleTime: 1000 * 60 * 5,
    }),

  detail: (id: string) =>
    queryOptions({
      queryKey: userKeys.detail(id),
      queryFn: () => getUserDetail(id),
    }),
}

// 사용 예시
const { data } = useQuery(userQueryOptions.me())
const { data } = useSuspenseQuery(userQueryOptions.me())
await queryClient.prefetchQuery(userQueryOptions.me())
queryClient.setQueryData(userQueryOptions.me().queryKey, newData)
```

### 장점

- **DRY**: queryKey, queryFn, options를 한 곳에서 관리
- **타입 안전**: queryKey와 queryFn이 항상 동기화
- **재사용**: useQuery, prefetch, setQueryData 등에서 동일 options 사용

---

## Hook 네이밍 컨벤션

```typescript
// useQuery: use + Get + 대상
export const useGetUser = () => { ... };
export const useGetItems = (params?: ListParams) => { ... };

// useInfiniteQuery: use + GetInfinite + 대상
export const useGetInfiniteMessages = () => { ... };

// useMutation: use + HTTP메서드 + 대상
export const usePostItem = () => { ... };        // POST (생성)
export const usePutUserProfile = () => { ... };  // PUT (전체 수정)
export const usePatchUserSettings = () => { ... };  // PATCH (부분 수정)
export const useDeleteItem = () => { ... };      // DELETE (삭제)
```

---

## 파일 구조

```
src/api/{domain}/
├── {domain}.api.ts       # API 함수 (Client)
├── {domain}.server.ts    # API 함수 (Server)
├── {domain}.hooks.ts     # useQuery/useMutation 훅
├── {domain}.queries.ts   # queryOptions 팩토리
└── {domain}.types.ts     # 도메인 타입
```

---

## 캐시 갱신 전략 (요약)

| 상황                    | 방식                |
| ----------------------- | ------------------- |
| 토글/스위치 (단일 필드) | `setQueryData`      |
| 서버 계산 필요          | `invalidateQueries` |
| 여러 필드 연쇄 변경     | `invalidateQueries` |
| 목록에서 항목 삭제      | `setQueryData`      |

```typescript
// setQueryData
queryClient.setQueryData(userKeys.me(), (old: User | undefined) =>
  old ? { ...old, isEnabled: newValue } : old,
)

// invalidateQueries
queryClient.invalidateQueries({ queryKey: itemKeys.all })
```
