# Query Patterns

## useQuery 옵션 패턴

### 기본 패턴

```typescript
export const useGetUser = () => {
  return useQuery({
    queryKey: userKeys.me(),
    queryFn: async () => {
      const response = await getUser()
      return response.data
    },
  })
}
```

### enabled (조건부 실행)

```typescript
export const useGetUser = () => {
  return useQuery({
    queryKey: userKeys.me(),
    queryFn: async () => {
      const response = await getUser()
      return response.data
    },
    enabled: !!getAccessToken(), // 토큰 있을 때만 실행
    retry: false,
  })
}
```

### select (데이터 변환)

```typescript
export const useGetItems = (params?: ListParams) => {
  return useQuery({
    queryKey: itemKeys.list(params),
    queryFn: () => getItems(params),
    select: (data) => data.data.contents, // 필요한 데이터만 추출
    staleTime: 1000 * 60 * 10, // 10분
  })
}
```

### staleTime / gcTime

```typescript
// 자주 변하지 않는 데이터
staleTime: 1000 * 60 * 10,  // 10분간 fresh
gcTime: 1000 * 60 * 30,     // 30분간 캐시 유지

// 자주 변하는 데이터
staleTime: 0,  // 항상 stale (기본값)
```

### refetchInterval (폴링)

```typescript
export const useGetProgressPolling = (id: string, enabled: boolean) => {
  return useQuery({
    queryKey: resourceKeys.progress(id),
    queryFn: () => getProgress(id),
    enabled: !!id && enabled,
    refetchInterval: (query) => {
      const status = query.state.data?.data?.status
      if (status === 'PROCESSING') return 3000 // 3초 간격
      return false // 완료 시 폴링 중단
    },
  })
}
```

---

## useSuspenseQuery 패턴

```typescript
// Suspense와 함께 사용
export const useGetItemDetail = (id: string) => {
  return useSuspenseQuery({
    queryKey: itemKeys.detail(id),
    queryFn: () => getItemDetail(id),
  });
};

// 사용처
<Suspense fallback={<ItemSkeleton />}>
  <ItemDetail id={id} />
</Suspense>
```

### 규칙

- `enabled` 옵션 사용 불가
- 반드시 `Suspense` 경계 필요
- 로딩 상태 직접 관리 불필요 (`isLoading` 항상 false)

---

## useInfiniteQuery 패턴

### 커서 기반 (page_token)

```typescript
export const useGetInfiniteMessages = (pageSize = 20) => {
  return useInfiniteQuery({
    queryKey: messageKeys.list(),
    queryFn: ({ pageParam }) =>
      getMessages({
        page_size: pageSize,
        page_token: pageParam,
      }),
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (lastPage) => (lastPage.data.has_next ? lastPage.data.page_token : undefined),
    select: (data) => ({
      pages: data.pages,
      pageParams: data.pageParams,
      items: data.pages.flatMap((page) => page.data.contents), // 평탄화
    }),
  })
}
```

### 오프셋 기반 (offset)

```typescript
const PAGE_SIZE = 20

export const useGetInfiniteHistory = (enabled: boolean) => {
  return useInfiniteQuery({
    queryKey: historyKeys.list(),
    queryFn: async ({ pageParam = 0 }) => {
      const response = await getHistory({
        size: PAGE_SIZE,
        offset: pageParam,
      })
      return response.data
    },
    initialPageParam: 0,
    getNextPageParam: (lastPage, allPages) => {
      if (!lastPage.has_next_page) return undefined
      return allPages.length * PAGE_SIZE
    },
    enabled,
  })
}
```

### keepPreviousData (검색 UX 개선)

```typescript
import { keepPreviousData } from '@tanstack/react-query'

export const useGetInfiniteSearch = (params: SearchParams) => {
  return useInfiniteQuery({
    queryKey: searchKeys.results(params),
    queryFn: async ({ pageParam }) => {
      const response = await search({
        ...params,
        page_token: pageParam,
      })
      return response.data
    },
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (lastPage) => (lastPage.has_next ? lastPage.page_token : undefined),
    placeholderData: keepPreviousData, // 검색어 변경 시 이전 데이터 유지
  })
}
```

### IntersectionObserver 연동 (무한스크롤)

```typescript
const { data, fetchNextPage, hasNextPage, isFetchingNextPage } = useGetInfiniteMessages();

const observerRef = useRef<IntersectionObserver | null>(null);

const lastItemRef = useCallback(
  (node: HTMLDivElement | null) => {
    if (isFetchingNextPage) return;
    if (observerRef.current) observerRef.current.disconnect();

    observerRef.current = new IntersectionObserver((entries) => {
      if (entries[0].isIntersecting && hasNextPage) {
        fetchNextPage();
      }
    });

    if (node) observerRef.current.observe(node);
  },
  [isFetchingNextPage, hasNextPage, fetchNextPage],
);

// 사용
{items.map((item, index) => (
  <div
    key={item.id}
    ref={index === items.length - 1 ? lastItemRef : undefined}
  >
    {/* content */}
  </div>
))}
```

### 규칙

- `initialPageParam` 필수 (타입 명시)
- `getNextPageParam`에서 `undefined` 반환 시 `hasNextPage = false`
- `select`로 pages 평탄화하여 사용 편의성 향상
- 검색 UI에서는 `keepPreviousData`로 깜빡임 방지

---

## meta.errorHandlers (에러 핸들링)

```typescript
// 특정 에러 무시
export const useGetItems = () => {
  return useQuery({
    queryKey: itemKeys.list(),
    queryFn: () => getItems(),
    meta: {
      errorHandlers: {
        TERMS_NOT_ACCEPTED: () => {}, // 이 에러는 무시
        UNAUTHORIZED: () => {
          // 커스텀 처리
          router.push('/login')
        },
      },
    },
  })
}
```

### 규칙

- 글로벌 에러 핸들러가 기본 처리
- `meta.errorHandlers`로 쿼리별 커스텀 처리
- 빈 함수 `() => {}`로 특정 에러 무시

---

## SSR Prefetch 패턴

### Server Component에서 fetchQuery

```typescript
// app/layout.tsx (Server Component)
import { getQueryClient } from '@/lib/queryClient';
import { HydrationBoundary, dehydrate } from '@tanstack/react-query';

export default async function RootLayout({ children }: Props) {
  const queryClient = getQueryClient();

  try {
    await queryClient.fetchQuery({
      queryKey: pageKeys.home(),
      queryFn: getHomeDataServer,  // Server 전용 API 함수
    });
  } catch {
    // 에러 시 클라이언트에서 재시도
  }

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      {children}
    </HydrationBoundary>
  );
}
```

### 규칙

- `fetchQuery` 사용 (`prefetchQuery`는 에러 throw 안 함)
- `try-catch`로 감싸서 에러 시 클라이언트 폴백
- `HydrationBoundary`로 캐시 전달
- Server 전용 API 함수 사용
