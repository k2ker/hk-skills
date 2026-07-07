# Mutation & Cache Patterns

## useMutation 패턴

### 기본 패턴 + invalidateQueries

```typescript
export const usePostItem = () => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (data: ItemRequest) => postItem(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: itemKeys.all })
    },
  })
}
```

### 여러 쿼리 무효화

```typescript
export const usePatchUserSettings = () => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: patchUserSettings,
    onSuccess: () => {
      // 연관된 모든 데이터 갱신
      queryClient.invalidateQueries({ queryKey: userKeys.all })
      queryClient.invalidateQueries({ queryKey: pageKeys.home() })
    },
  })
}
```

---

## 캐시 갱신 전략

### 선택 기준

| 상황                            | 방식                | 이유                   |
| ------------------------------- | ------------------- | ---------------------- |
| 토글/스위치 (단일 필드)         | `setQueryData`      | 새 값을 이미 알고 있음 |
| 서버 계산 필요 (포인트 차감 등) | `invalidateQueries` | 서버 응답값 필요       |
| 여러 필드 연쇄 변경             | `invalidateQueries` | 전체 데이터 다시 받기  |
| 목록에서 항목 삭제              | `setQueryData`      | filter로 직접 제거     |
| 실시간 이벤트 (WebSocket)       | `setQueryData`      | 네트워크 효율적        |

### setQueryData 패턴

```typescript
// 단일 필드 업데이트
queryClient.setQueryData(userKeys.me(), (old: User | undefined) =>
  old ? { ...old, isEnabled: newValue } : old,
)

// 목록에서 항목 제거
queryClient.setQueryData(itemKeys.list(), (old: Item[] | undefined) =>
  old ? old.filter((item) => item.id !== deletedId) : old,
)
```

### setQueryData + invalidateQueries 복합 패턴

```typescript
const mutation = useMutation({
  mutationFn: patchUserSettings,
  onSuccess: (_, newSettings) => {
    // 1. 즉시 캐시 갱신 (UI 빠른 반영)
    queryClient.setQueryData(userKeys.me(), (old: User | undefined) =>
      old ? { ...old, settings: newSettings } : old,
    )

    // 2. 연관 데이터 무효화 (백그라운드 갱신)
    queryClient.invalidateQueries({ queryKey: pageKeys.home() })
    queryClient.invalidateQueries({ queryKey: itemKeys.lists() })
  },
})
```

---

## Optimistic Update 패턴

```typescript
export const useToggleFavorite = () => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: toggleFavorite,
    onMutate: async (itemId) => {
      // 진행 중인 쿼리 취소
      await queryClient.cancelQueries({ queryKey: itemKeys.detail(itemId) })

      // 이전 값 저장
      const previousItem = queryClient.getQueryData(itemKeys.detail(itemId))

      // 낙관적 업데이트
      queryClient.setQueryData(itemKeys.detail(itemId), (old: Item | undefined) =>
        old ? { ...old, isFavorite: !old.isFavorite } : old,
      )

      return { previousItem }
    },
    onError: (err, itemId, context) => {
      // 에러 시 롤백
      queryClient.setQueryData(itemKeys.detail(itemId), context?.previousItem)
    },
    onSettled: (_, __, itemId) => {
      // 성공/실패 상관없이 재조회
      queryClient.invalidateQueries({ queryKey: itemKeys.detail(itemId) })
    },
  })
}
```

---

## 삭제 Mutation 패턴

```typescript
export const useDeleteItem = () => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: string) => deleteItem(id),
    onSuccess: (_, deletedId) => {
      // 목록에서 즉시 제거
      queryClient.setQueryData(itemKeys.list(), (old: Item[] | undefined) =>
        old ? old.filter((item) => item.id !== deletedId) : old,
      )

      // 상세 캐시도 제거
      queryClient.removeQueries({ queryKey: itemKeys.detail(deletedId) })
    },
  })
}
```

---

## 생성 후 목록 갱신 패턴

```typescript
export const usePostItem = () => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: postItem,
    onSuccess: (newItem) => {
      // 방법 1: 목록에 추가
      queryClient.setQueryData(itemKeys.list(), (old: Item[] | undefined) =>
        old ? [newItem, ...old] : [newItem],
      )

      // 방법 2: 전체 목록 무효화 (정렬/필터 있을 경우)
      queryClient.invalidateQueries({ queryKey: itemKeys.lists() })
    },
  })
}
```
