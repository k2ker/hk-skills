# useMemo 필터 체인 패턴

useMemo를 활용한 필터링 및 계산된 값 최적화 패턴.

## 기본 개념

### 왜 useMemo를 사용하는가?

**문제:** 렌더링마다 반복 계산

```tsx
// ❌ 매 렌더마다 필터링 실행
const published = characters.filter((c) => c.status === 'published')
const draft = characters.filter((c) => c.status === 'draft')
// characters가 같아도 매번 새 배열 생성!
```

**해결:** useMemo로 메모이제이션

```tsx
// ✅ characters가 변경될 때만 재계산
const published = useMemo(() => characters.filter((c) => c.status === 'published'), [characters])

const draft = useMemo(() => characters.filter((c) => c.status === 'draft'), [characters])
```

---

### 언제 사용하는가?

**✅ useMemo 사용이 적합한 경우:**

- 배열 필터링/정렬
- 객체 계산 (통계, 합계 등)
- 복잡한 연산 (시간 복잡도 O(n) 이상)
- Context 값으로 전달할 때

**❌ useMemo 불필요한 경우:**

- 단순 변수 할당 (`const x = y;`)
- Primitive 값 계산 (`const sum = a + b;`)
- 함수 호출 결과 (이미 메모이제이션됨)

---

## 필터 체인 패턴

### 패턴 1: 통계 계산 → 필터링

```typescript
const useMyFeature = () => {
  const { data: characters } = useMyCharacters()
  const [filter, setFilter] = useState<'all' | 'published' | 'draft'>('all')

  // 1단계: 통계 계산
  const stats = useMemo(
    () => ({
      total: characters.length,
      published: characters.filter((c) => c.status === 'published').length,
      draft: characters.filter((c) => c.status === 'draft').length,
    }),
    [characters],
  )

  // 2단계: 필터링 (filter 클릭 시 재계산)
  const filteredCharacters = useMemo(() => {
    if (filter === 'all') return characters
    return characters.filter((c) => c.status === filter)
  }, [characters, filter])

  return useMemo(
    () => ({
      state: { characters, stats, filter, filteredCharacters },
      actions: { setFilter },
    }),
    [characters, stats, filter, filteredCharacters],
  )
}
```

**동작:**

1. `characters` 변경 → `stats`, `filteredCharacters` 재계산
2. `filter` 변경 → `filteredCharacters`만 재계산 (stats는 그대로)
3. Stats 클릭 → `setFilter` 호출 → `filteredCharacters` 자동 업데이트

---

### 패턴 2: 다단계 필터링

```typescript
const useProductList = () => {
  const { data: products } = useProducts()
  const [category, setCategory] = useState('all')
  const [priceRange, setPriceRange] = useState<[number, number]>([0, 1000])
  const [searchQuery, setSearchQuery] = useState('')

  // 1단계: 카테고리 필터
  const categoryFiltered = useMemo(() => {
    if (category === 'all') return products
    return products.filter((p) => p.category === category)
  }, [products, category])

  // 2단계: 가격 필터 (카테고리 필터 결과에서)
  const priceFiltered = useMemo(() => {
    return categoryFiltered.filter((p) => p.price >= priceRange[0] && p.price <= priceRange[1])
  }, [categoryFiltered, priceRange])

  // 3단계: 검색 필터 (가격 필터 결과에서)
  const searchFiltered = useMemo(() => {
    if (!searchQuery) return priceFiltered
    return priceFiltered.filter((p) => p.name.toLowerCase().includes(searchQuery.toLowerCase()))
  }, [priceFiltered, searchQuery])

  return useMemo(
    () => ({
      state: {
        products,
        filteredProducts: searchFiltered,
        category,
        priceRange,
        searchQuery,
      },
      actions: {
        setCategory,
        setPriceRange,
        setSearchQuery,
      },
    }),
    [products, searchFiltered, category, priceRange, searchQuery],
  )
}
```

**장점:**

- 단계별로 의존성 명확
- 중간 결과 재사용
- 최소한의 재계산

---

### 패턴 3: 정렬 + 필터링

```typescript
const useMyFeature = () => {
  const { data: items } = useItems()
  const [sortBy, setSortBy] = useState<'name' | 'date' | 'status'>('date')
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc')
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'inactive'>('all')

  // 1단계: 필터링
  const filtered = useMemo(() => {
    if (statusFilter === 'all') return items
    return items.filter((item) => item.status === statusFilter)
  }, [items, statusFilter])

  // 2단계: 정렬 (필터 결과에서)
  const sorted = useMemo(() => {
    return [...filtered].sort((a, b) => {
      let comparison = 0

      if (sortBy === 'name') {
        comparison = a.name.localeCompare(b.name)
      } else if (sortBy === 'date') {
        comparison = new Date(a.date).getTime() - new Date(b.date).getTime()
      } else if (sortBy === 'status') {
        comparison = a.status.localeCompare(b.status)
      }

      return sortOrder === 'asc' ? comparison : -comparison
    })
  }, [filtered, sortBy, sortOrder])

  return useMemo(
    () => ({
      state: {
        items,
        filteredItems: sorted,
        sortBy,
        sortOrder,
        statusFilter,
      },
      actions: {
        setSortBy,
        setSortOrder,
        setStatusFilter,
      },
    }),
    [items, sorted, sortBy, sortOrder, statusFilter],
  )
}
```

---

## 실전 예시

### Dashboard 통계 (web-almigo)

```typescript
const useCreatorDashboardPage = () => {
  const { data: characters } = useMyCharactersSuspense()
  const [filter, setFilter] = useState<CharacterFilter>('all')

  // 통계 계산
  const stats = useMemo(
    () => ({
      total: characters.length,
      registered: characters.filter(
        (c) => c.status === 'PUBLISHED' || c.status === 'PRIVATE_BY_CREATOR',
      ).length,
      draft: characters.filter((c) => c.status === 'DRAFT').length,
      error: characters.filter((c) => c.status === 'VIDEO_FAILED' || c.status === 'VIDEO_ERROR')
        .length,
      banned: characters.filter((c) => c.status === 'BANNED_BY_ADMIN').length,
    }),
    [characters],
  )

  // 필터링된 목록
  const filteredCharacters = useMemo(() => {
    switch (filter) {
      case 'registered':
        return characters.filter(
          (c) => c.status === 'PUBLISHED' || c.status === 'PRIVATE_BY_CREATOR',
        )
      case 'draft':
        return characters.filter((c) => c.status === 'DRAFT')
      case 'error':
        return characters.filter((c) => c.status === 'VIDEO_FAILED' || c.status === 'VIDEO_ERROR')
      case 'banned':
        return characters.filter((c) => c.status === 'BANNED_BY_ADMIN')
      default:
        return characters
    }
  }, [characters, filter])

  return useMemo(
    () => ({
      state: { characters, stats, filter, filteredCharacters },
      actions: { setFilter },
    }),
    [characters, stats, filter, filteredCharacters],
  )
}
```

---

### 검색 + 필터 조합

```typescript
const useSearchableList = () => {
  const { data: items } = useItems()
  const [searchQuery, setSearchQuery] = useState('')
  const [categoryFilter, setCategoryFilter] = useState<string>('all')

  // 1단계: 카테고리 필터
  const categoryFiltered = useMemo(() => {
    if (categoryFilter === 'all') return items
    return items.filter((item) => item.category === categoryFilter)
  }, [items, categoryFilter])

  // 2단계: 검색 필터
  const searchFiltered = useMemo(() => {
    if (!searchQuery.trim()) return categoryFiltered

    const query = searchQuery.toLowerCase()
    return categoryFiltered.filter(
      (item) =>
        item.name.toLowerCase().includes(query) || item.description.toLowerCase().includes(query),
    )
  }, [categoryFiltered, searchQuery])

  // 통계
  const stats = useMemo(
    () => ({
      total: items.length,
      filtered: searchFiltered.length,
    }),
    [items.length, searchFiltered.length],
  )

  return useMemo(
    () => ({
      state: {
        items,
        filteredItems: searchFiltered,
        searchQuery,
        categoryFilter,
        stats,
      },
      actions: {
        setSearchQuery,
        setCategoryFilter,
      },
    }),
    [items, searchFiltered, searchQuery, categoryFilter, stats],
  )
}
```

---

### 페이지네이션

```typescript
const usePaginatedList = () => {
  const { data: items } = useItems()
  const [currentPage, setCurrentPage] = useState(1)
  const [filter, setFilter] = useState<'all' | 'active'>('all')
  const itemsPerPage = 10

  // 필터링
  const filtered = useMemo(() => {
    if (filter === 'all') return items
    return items.filter((item) => item.status === 'active')
  }, [items, filter])

  // 총 페이지 수
  const totalPages = useMemo(() => Math.ceil(filtered.length / itemsPerPage), [filtered.length])

  // 현재 페이지 아이템
  const paginatedItems = useMemo(() => {
    const startIndex = (currentPage - 1) * itemsPerPage
    const endIndex = startIndex + itemsPerPage
    return filtered.slice(startIndex, endIndex)
  }, [filtered, currentPage])

  // 페이지 변경
  const goToPage = useCallback(
    (page: number) => {
      if (page < 1 || page > totalPages) return
      setCurrentPage(page)
    },
    [totalPages],
  )

  return useMemo(
    () => ({
      state: {
        items: paginatedItems,
        currentPage,
        totalPages,
        totalItems: filtered.length,
        filter,
      },
      actions: {
        goToPage,
        nextPage: () => goToPage(currentPage + 1),
        prevPage: () => goToPage(currentPage - 1),
        setFilter,
      },
    }),
    [paginatedItems, currentPage, totalPages, filtered.length, filter, goToPage],
  )
}
```

---

## 성능 고려사항

### 의존성 배열 최적화

```typescript
// ❌ 불필요한 의존성
const filtered = useMemo(() => {
  return items.filter((item) => item.status === status)
}, [items, status, someUnrelatedValue]) // someUnrelatedValue 불필요!

// ✅ 필요한 의존성만
const filtered = useMemo(() => {
  return items.filter((item) => item.status === status)
}, [items, status])
```

---

### 과도한 메모이제이션 주의

```typescript
// ❌ 과도함: 단순 계산도 useMemo
const sum = useMemo(() => a + b, [a, b]) // 불필요
const doubled = useMemo(() => value * 2, [value]) // 불필요

// ✅ 적절함: 복잡한 계산만
const sum = a + b // 그냥 계산
const doubled = value * 2 // 그냥 계산

const filtered = useMemo(
  () => items.filter((item) => item.price > 100), // 필요 (O(n))
  [items],
)
```

---

### useMemo 체인 의존성 관리

```typescript
// ✅ 올바른 체인
const filtered = useMemo(() => {
  return items.filter((item) => item.category === category)
}, [items, category])

const sorted = useMemo(() => {
  return [...filtered].sort((a, b) => a.price - b.price)
}, [filtered]) // filtered에만 의존

const final = useMemo(() => {
  return sorted.slice(0, 10)
}, [sorted]) // sorted에만 의존

// ❌ 잘못된 체인
const sorted = useMemo(() => {
  return [...filtered].sort((a, b) => a.price - b.price)
}, [items, category, filtered]) // 불필요한 의존성 (items, category)
```

---

## 클릭 가능한 Stats 패턴

### Stats UI + 필터 연동

```tsx
// components/Stats.tsx
'use client'
import { useMyFeatureSelector } from '../providers/MyFeatureProvider'
import type { CharacterFilter } from '../hooks/useMyFeature'

export default function Stats() {
  const stats = useMyFeatureSelector((ctx) => ctx.state.stats)
  const filter = useMyFeatureSelector((ctx) => ctx.state.filter)
  const setFilter = useMyFeatureSelector((ctx) => ctx.actions.setFilter)

  const statItems: { key: CharacterFilter; label: string; color: string }[] = [
    { key: 'all', label: '전체', color: 'text-common-100' },
    { key: 'published', label: '발행됨', color: 'text-blue-50' },
    { key: 'draft', label: '임시저장', color: 'text-yellow-50' },
  ]

  return (
    <div className="flex gap-2">
      {statItems.map((item) => (
        <button
          key={item.key}
          type="button"
          onClick={() => setFilter(item.key)}
          className={`flex items-center gap-2 rounded-lg px-2 py-1 ${
            filter === item.key ? 'bg-gray-26' : 'hover:bg-gray-20'
          }`}
        >
          <span className={filter === item.key ? 'text-common-100' : 'text-gray-50'}>
            {item.label}
          </span>
          <span className={item.color}>{stats[item.key]}</span>
        </button>
      ))}
    </div>
  )
}
```

**핵심:**

- Stats 클릭 → `setFilter` 호출
- `filter` 변경 → `filteredCharacters` 자동 재계산
- UI 업데이트

---

## 복잡한 필터 예시

### 여러 조건 조합

```typescript
const useAdvancedFilter = () => {
  const { data: items } = useItems()
  const [filters, setFilters] = useState({
    status: 'all' as 'all' | 'active' | 'inactive',
    minPrice: 0,
    maxPrice: 1000,
    tags: [] as string[],
    searchQuery: '',
  })

  // 필터 적용 (모든 조건 체크)
  const filtered = useMemo(() => {
    return items.filter((item) => {
      // 상태 필터
      if (filters.status !== 'all' && item.status !== filters.status) {
        return false
      }

      // 가격 필터
      if (item.price < filters.minPrice || item.price > filters.maxPrice) {
        return false
      }

      // 태그 필터 (하나라도 일치)
      if (filters.tags.length > 0) {
        const hasTag = filters.tags.some((tag) => item.tags.includes(tag))
        if (!hasTag) return false
      }

      // 검색 필터
      if (filters.searchQuery) {
        const query = filters.searchQuery.toLowerCase()
        const matchesSearch =
          item.name.toLowerCase().includes(query) || item.description.toLowerCase().includes(query)
        if (!matchesSearch) return false
      }

      return true
    })
  }, [items, filters])

  // 필터 업데이트 헬퍼
  const updateFilter = useCallback(
    <K extends keyof typeof filters>(key: K, value: (typeof filters)[K]) => {
      setFilters((prev) => ({ ...prev, [key]: value }))
    },
    [],
  )

  return useMemo(
    () => ({
      state: { items, filteredItems: filtered, filters },
      actions: { updateFilter, resetFilters: () => setFilters({ ...initialFilters }) },
    }),
    [items, filtered, filters, updateFilter],
  )
}
```

---

## 체크리스트

필터 패턴 구현 시:

- [ ] useMemo로 필터링/정렬 메모이제이션
- [ ] 의존성 배열에 필요한 값만 포함
- [ ] 필터 체인 시 중간 결과 재사용
- [ ] 통계는 원본 데이터에서 계산 (필터 결과 아님)
- [ ] 과도한 useMemo 사용 지양 (단순 계산은 그냥)
- [ ] filter 상태 변경 함수는 useCallback

---

## 결론

**핵심 요약:**

- useMemo로 필터링/계산 최적화
- 체인 패턴으로 단계별 처리
- 의존성 최소화
- Stats 클릭 → 필터 자동 업데이트

**금지:** 렌더마다 배열 필터링
**권장:** useMemo 체인 + selector 조합
