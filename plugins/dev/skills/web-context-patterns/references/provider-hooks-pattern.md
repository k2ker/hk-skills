# Provider/Hooks 분리 패턴

Provider는 단순하게, 로직은 hooks로 분리하는 핵심 패턴.

## 핵심 원칙

**Provider는 단순하게, 로직은 hooks로 분리!**

**장점:**

- **테스트 용이성**: hooks를 독립적으로 테스트 가능
- **로직 재사용**: 다른 Provider에서도 같은 hooks 사용 가능
- **타입 추론 개선**: `ReturnType<typeof useHook>`로 자동 타입 추론
- **코드 가독성**: Provider는 단순히 "연결" 역할만

---

## 안티패턴: Provider에 로직 작성 (❌)

```typescript
// ❌ 금지: Provider에 모든 로직
export const MyProvider = ({ children }) => {
  const router = useRouter();
  const [value, setValue] = useState(0);
  const [deleteTarget, setDeleteTarget] = useState(null);

  const { data: characters } = useMyCharacters();
  const deleteMutation = useDeleteCharacter();

  const stats = useMemo(() => ({
    total: characters.length,
    published: characters.filter(c => c.status === 'published').length,
  }), [characters]);

  const handleClick = useCallback(() => {
    router.push('/dashboard');
  }, [router]);

  const openDeleteModal = useCallback((char) => {
    setDeleteTarget(char);
  }, []);

  const confirmDelete = useCallback(async () => {
    if (!deleteTarget) return;
    await deleteMutation.mutateAsync(deleteTarget.id);
    setDeleteTarget(null);
  }, [deleteTarget, deleteMutation]);

  // 100줄의 로직...

  return (
    <MyContext.Provider value={{ value, characters, stats, handleClick, openDeleteModal, confirmDelete }}>
      {children}
    </MyContext.Provider>
  );
};
```

**문제점:**

- Provider 파일이 비대해짐 (100+ 줄)
- 테스트하기 어려움 (Provider를 렌더링해야 함)
- 로직 재사용 불가능
- 타입 관리 복잡

---

## 권장 패턴: hooks에 로직 분리 (✅)

### Step 1: hooks 파일에 모든 로직 작성

```typescript
// hooks/useMyFeature.ts
'use client'
import { useState, useCallback, useMemo } from 'react'
import { useRouter } from '@/i18n/navigation'
import { useMyCharacters } from '@/api/character/character.queries'
import { useDeleteCharacter } from '@/api/character/character.mutations'

const useMyFeature = () => {
  const router = useRouter()
  const [value, setValue] = useState(0)
  const [deleteTarget, setDeleteTarget] = useState<Character | null>(null)

  // API 호출
  const { data: characters } = useMyCharacters()
  const deleteMutation = useDeleteCharacter()

  // 계산된 값
  const stats = useMemo(
    () => ({
      total: characters.length,
      published: characters.filter((c) => c.status === 'published').length,
    }),
    [characters],
  )

  // 액션들
  const handleClick = useCallback(() => {
    router.push('/dashboard')
  }, [router])

  const openDeleteModal = useCallback((char: Character) => {
    setDeleteTarget(char)
  }, [])

  const confirmDelete = useCallback(async () => {
    if (!deleteTarget) return
    await deleteMutation.mutateAsync(deleteTarget.id)
    setDeleteTarget(null)
  }, [deleteTarget, deleteMutation])

  // state/actions 분리하여 반환
  return useMemo(
    () => ({
      state: {
        value,
        characters,
        stats,
        deleteTarget,
        isDeleting: deleteMutation.isPending,
      },
      actions: {
        setValue,
        handleClick,
        openDeleteModal,
        closeDeleteModal: () => setDeleteTarget(null),
        confirmDelete,
      },
    }),
    [
      value,
      characters,
      stats,
      deleteTarget,
      deleteMutation.isPending,
      handleClick,
      openDeleteModal,
      confirmDelete,
    ],
  )
}

export default useMyFeature
```

---

### Step 2: Provider는 단순하게

```typescript
// providers/MyFeatureProvider.tsx
'use client';
import { ReactNode } from 'react';
import { createContext, useContextSelector } from 'use-context-selector';
import useMyFeature from '../hooks/useMyFeature';

// ✅ ReturnType으로 자동 타입 추론
type MyFeatureCtx = ReturnType<typeof useMyFeature>;

const MyFeatureContext = createContext<MyFeatureCtx>(
  undefined as unknown as MyFeatureCtx
);

// Selector hook export
export const useMyFeatureSelector = <T,>(
  selector: (ctx: MyFeatureCtx) => T
) => {
  return useContextSelector(MyFeatureContext, (context) => {
    if (process.env.NODE_ENV !== 'production' && context === undefined) {
      throw new Error('MyFeatureContext.Provider 안에서만 사용하세요.');
    }
    return selector(context);
  });
};

// Provider - 단순히 hook 사용만!
export const MyFeatureProvider = ({ children }: { children: ReactNode }) => {
  const value = useMyFeature();  // 모든 로직은 hook에서
  return (
    <MyFeatureContext.Provider value={value}>
      {children}
    </MyFeatureContext.Provider>
  );
};
```

**특징:**

- Provider 파일이 짧고 단순함 (~40줄)
- 타입은 `ReturnType<typeof useMyFeature>`로 자동
- 로직 변경은 hooks 파일만 수정

---

## hooks 파일 구성

### 기본 템플릿

```typescript
// hooks/useFeature.ts
'use client';
import { useState, useCallback, useMemo } from 'react';

const useFeature = () => {
  // 1. Local state
  const [localState, setLocalState] = useState<Type>(initialValue);

  // 2. React Query hooks
  const { data } = useQuery(...);
  const mutation = useMutation(...);

  // 3. 계산된 값 (useMemo)
  const computedValue = useMemo(() => {
    // 복잡한 계산...
    return result;
  }, [dependencies]);

  // 4. 액션 함수 (useCallback)
  const handleAction = useCallback(() => {
    // 로직...
  }, [dependencies]);

  // 5. 반환 (state/actions 분리)
  return useMemo(() => ({
    state: {
      localState,
      data,
      computedValue,
      isLoading: mutation.isPending,
    },
    actions: {
      setLocalState,
      handleAction,
      mutate: mutation.mutate,
    },
  }), [localState, data, computedValue, mutation.isPending, handleAction]);
};

export default useFeature;
```

---

### state/actions 분리의 중요성

```typescript
// ✅ 명확한 구조
return useMemo(
  () => ({
    state: {
      characters, // 데이터
      stats, // 계산된 값
      deleteTarget, // UI 상태
      isDeleting, // 로딩 상태
    },
    actions: {
      setFilter, // 상태 변경
      openModal, // UI 액션
      confirmDelete, // 비즈니스 로직
    },
  }),
  [
    /* 의존성 */
  ],
)
```

**장점:**

- selector 사용 시 명확: `ctx.state.characters`, `ctx.actions.setFilter`
- 코드 의도 파악 용이
- IDE 자동완성 개선

---

## Provider 파일 구성

### 기본 템플릿

```typescript
// providers/FeatureProvider.tsx
'use client';
import { ReactNode } from 'react';
import { createContext, useContextSelector } from 'use-context-selector';
import useFeature from '../hooks/useFeature';

// 타입 정의
type FeatureCtx = ReturnType<typeof useFeature>;

// Context 생성
const FeatureContext = createContext<FeatureCtx>(
  undefined as unknown as FeatureCtx
);

// Selector hook (export)
export const useFeatureSelector = <T,>(
  selector: (ctx: FeatureCtx) => T
) => {
  return useContextSelector(FeatureContext, (context) => {
    // 개발 환경에서 에러 체크
    if (process.env.NODE_ENV !== 'production' && context === undefined) {
      throw new Error('FeatureContext.Provider 안에서만 사용하세요.');
    }
    return selector(context);
  });
};

// Provider (export)
export const FeatureProvider = ({ children }: { children: ReactNode }) => {
  const value = useFeature();
  return (
    <FeatureContext.Provider value={value}>
      {children}
    </FeatureContext.Provider>
  );
};
```

---

## 실제 예시: Dashboard

### 폴더 구조

```
features/CreatorPage/CreatorDashboardPage/
├── CreatorDashboardPage.tsx              # 메인 컴포넌트
├── providers/
│   └── CreatorDashboardPageProvider.tsx  # Provider
├── hooks/
│   └── useCreatorDashboardPage.ts        # 모든 로직
└── components/
    ├── DashboardContent.tsx
    └── DashboardSkeleton.tsx
```

---

### hooks/useCreatorDashboardPage.ts

```typescript
'use client'
import { useState, useCallback, useMemo } from 'react'
import { useRouter } from '@/i18n/navigation'
import { useMyCharactersSuspense } from '@/api/character/character.queries'
import { useDeleteCharacter } from '@/api/character/character.mutations'

export type CharacterFilter = 'all' | 'registered' | 'draft' | 'error' | 'banned'

const useCreatorDashboardPage = () => {
  const router = useRouter()
  const [filter, setFilter] = useState<CharacterFilter>('all')
  const [deleteTarget, setDeleteTarget] = useState<Character | null>(null)

  // API 호출
  const { data: characters } = useMyCharactersSuspense()
  const deleteMutation = useDeleteCharacter()

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

  // 액션들
  const openDeleteModal = useCallback((char: Character) => {
    setDeleteTarget(char)
  }, [])

  const confirmDelete = useCallback(async () => {
    if (!deleteTarget) return
    await deleteMutation.mutateAsync(deleteTarget.id)
    setDeleteTarget(null)
  }, [deleteTarget, deleteMutation])

  const handleCreateNew = useCallback(() => {
    router.push('/creator/new')
  }, [router])

  // 반환
  return useMemo(
    () => ({
      state: {
        characters,
        stats,
        filter,
        filteredCharacters,
        deleteTarget,
        isDeleting: deleteMutation.isPending,
      },
      actions: {
        setFilter,
        openDeleteModal,
        closeDeleteModal: () => setDeleteTarget(null),
        confirmDelete,
        handleCreateNew,
      },
    }),
    [
      characters,
      stats,
      filter,
      filteredCharacters,
      deleteTarget,
      deleteMutation.isPending,
      openDeleteModal,
      confirmDelete,
      handleCreateNew,
    ],
  )
}

export default useCreatorDashboardPage
```

---

### providers/CreatorDashboardPageProvider.tsx

```typescript
'use client';
import { ReactNode } from 'react';
import { createContext, useContextSelector } from 'use-context-selector';
import useCreatorDashboardPage from '../hooks/useCreatorDashboardPage';

type CreatorDashboardPageCtx = ReturnType<typeof useCreatorDashboardPage>;

const CreatorDashboardPageContext = createContext<CreatorDashboardPageCtx>(
  undefined as unknown as CreatorDashboardPageCtx
);

// Selector hook
export const useCreatorDashboardPageSelector = <T,>(
  selector: (ctx: CreatorDashboardPageCtx) => T
) => {
  return useContextSelector(CreatorDashboardPageContext, (context) => {
    if (process.env.NODE_ENV !== 'production' && context === undefined) {
      throw new Error('CreatorDashboardPageContext.Provider 안에서만 사용하세요.');
    }
    return selector(context);
  });
};

// Provider
export const CreatorDashboardPageProvider = ({
  children,
}: {
  children: ReactNode;
}) => {
  const value = useCreatorDashboardPage();
  return (
    <CreatorDashboardPageContext.Provider value={value}>
      {children}
    </CreatorDashboardPageContext.Provider>
  );
};
```

---

## 장점

### 1. 테스트 용이성

```typescript
// hooks 단독 테스트 가능
import { renderHook } from '@testing-library/react'
import useMyFeature from './useMyFeature'

test('stats 계산', () => {
  const { result } = renderHook(() => useMyFeature())

  expect(result.current.state.stats.total).toBe(5)
  expect(result.current.state.stats.published).toBe(3)
})
```

**Provider 방식이었다면:**

```typescript
// Provider 전체를 렌더링해야 함 (복잡함)
render(
  <QueryClientProvider client={queryClient}>
    <MyProvider>
      <TestComponent />
    </MyProvider>
  </QueryClientProvider>
);
```

---

### 2. 로직 재사용

```typescript
// hooks/useDashboard.ts
const useDashboard = () => {
  const { data: characters } = useMyCharacters();
  // 로직...
  return useMemo(() => ({ state, actions }), [...]);
};

// 여러 Provider에서 재사용 가능!
// providers/DashboardProvider.tsx
export const DashboardProvider = ({ children }) => {
  const value = useDashboard();
  return <Context.Provider value={value}>{children}</Context.Provider>;
};

// providers/CreatorProvider.tsx (다른 Provider)
export const CreatorProvider = ({ children }) => {
  const dashboardData = useDashboard();  // 같은 hook 재사용!
  const creatorSpecific = useCreatorLogic();

  const value = useMemo(() => ({
    ...dashboardData,
    ...creatorSpecific,
  }), [dashboardData, creatorSpecific]);

  return <Context.Provider value={value}>{children}</Context.Provider>;
};
```

---

### 3. 타입 추론 개선

```typescript
// ✅ 자동 타입 추론
type MyFeatureCtx = ReturnType<typeof useMyFeature>

// TypeScript가 자동으로 추론:
// {
//   state: {
//     characters: Character[];
//     stats: { total: number; published: number; };
//     ...
//   };
//   actions: {
//     setFilter: (filter: CharacterFilter) => void;
//     ...
//   };
// }
```

**Provider 방식이었다면:**

```typescript
// ❌ 수동으로 타입 정의해야 함
interface MyFeatureCtx {
  characters: Character[]
  stats: { total: number; published: number }
  setFilter: (filter: CharacterFilter) => void
  // ...100줄...
}
```

---

## 네이밍 컨벤션

| 항목         | 패턴                 | 예시                                             |
| ------------ | -------------------- | ------------------------------------------------ |
| **폴더**     | `{Page}Page/`        | `CreatorNewPage/`, `CreatorDashboardPage/`       |
| **Hook**     | `use{Page}.ts`       | `useCreatorNewPage.ts`, `useCreatorDashboard.ts` |
| **Provider** | `{Page}Provider.tsx` | `CreatorNewPageProvider.tsx`                     |
| **Selector** | `use{Page}Selector`  | `useCreatorNewPageSelector`                      |
| **Context**  | `{Page}Context`      | `CreatorNewPageContext`                          |

**중요:**

- Page 이름에 "Page" 포함 (예: `CreatorDashboardPage`, 아님 `CreatorDashboard`)
- Selector는 Provider 파일에서 export
- Context는 Provider 파일 내부에서만 사용 (export 안함)

---

## 실제 예시: Creator New Page

### hooks/useCreatorNewPage.ts

```typescript
'use client'
import { useCallback, useMemo } from 'react'
import { useRouter } from '@/i18n/navigation'
import { useForm } from '@tanstack/react-form'
import { useCreateCharacter } from '@/api/character/character.mutations'

const useCreatorNewPage = () => {
  const router = useRouter()
  const createMutation = useCreateCharacter()

  // 폼 초기화
  const form = useForm({
    defaultValues: {
      name: '',
      description: '',
      tags: [],
    },
    onSubmit: async ({ value }) => {
      const result = await createMutation.mutateAsync(value)
      router.push(`/creator/edit/${result.data.data.id}`)
    },
  })

  // 액션들
  const handleCancel = useCallback(() => {
    router.back()
  }, [router])

  return useMemo(
    () => ({
      state: {
        form,
        isSubmitting: createMutation.isPending,
      },
      actions: {
        handleCancel,
      },
    }),
    [form, createMutation.isPending, handleCancel],
  )
}

export default useCreatorNewPage
```

---

### providers/CreatorNewPageProvider.tsx

```typescript
'use client';
import { ReactNode } from 'react';
import { createContext, useContextSelector } from 'use-context-selector';
import useCreatorNewPage from '../hooks/useCreatorNewPage';

type CreatorNewPageCtx = ReturnType<typeof useCreatorNewPage>;

const CreatorNewPageContext = createContext<CreatorNewPageCtx>(
  undefined as unknown as CreatorNewPageCtx
);

export const useCreatorNewPageSelector = <T,>(
  selector: (ctx: CreatorNewPageCtx) => T
) => {
  return useContextSelector(CreatorNewPageContext, (context) => {
    if (process.env.NODE_ENV !== 'production' && context === undefined) {
      throw new Error('CreatorNewPageContext.Provider 안에서만 사용하세요.');
    }
    return selector(context);
  });
};

export const CreatorNewPageProvider = ({
  children,
}: {
  children: ReactNode;
}) => {
  const value = useCreatorNewPage();
  return (
    <CreatorNewPageContext.Provider value={value}>
      {children}
    </CreatorNewPageContext.Provider>
  );
};
```

---

### 사용 예시

```tsx
// CreatorNewPage.tsx
'use client'
import { useCreatorNewPageSelector } from './providers/CreatorNewPageProvider'
import Button from '@/components/ui/button/Button'

export default function CreatorNewPage() {
  // ✅ selector로 필요한 값만 구독
  const form = useCreatorNewPageSelector((ctx) => ctx.state.form)
  const isSubmitting = useCreatorNewPageSelector((ctx) => ctx.state.isSubmitting)
  const handleCancel = useCreatorNewPageSelector((ctx) => ctx.actions.handleCancel)

  return (
    <div>
      <h1>새 캐릭터 만들기</h1>

      <form.Field name="name">
        {(field) => (
          <Input value={field.state.value} onChange={(e) => field.handleChange(e.target.value)} />
        )}
      </form.Field>

      <div className="flex gap-2">
        <Button variant="tertiary" onClick={handleCancel}>
          취소
        </Button>
        <Button onClick={form.handleSubmit} isLoading={isSubmitting}>
          생성
        </Button>
      </div>
    </div>
  )
}
```

---

## 마이그레이션 가이드

### Before: Provider에 로직 작성 (기존)

```typescript
// ❌ 기존 방식
const MyProvider = ({ children }) => {
  const [state, setState] = useState(0);
  const handleClick = () => setState(state + 1);

  return (
    <MyContext.Provider value={{ state, handleClick }}>
      {children}
    </MyContext.Provider>
  );
};
```

---

### After: hooks로 로직 분리 (새 패턴)

**Step 1: hooks 파일 생성**

```typescript
// hooks/useMyFeature.ts
const useMyFeature = () => {
  const [state, setState] = useState(0)

  const handleClick = useCallback(() => {
    setState((prev) => prev + 1)
  }, [])

  return useMemo(
    () => ({
      state: { state },
      actions: { handleClick },
    }),
    [state, handleClick],
  )
}

export default useMyFeature
```

---

**Step 2: Provider 수정**

```typescript
// providers/MyFeatureProvider.tsx
import useMyFeature from '../hooks/useMyFeature';

type MyFeatureCtx = ReturnType<typeof useMyFeature>;
const MyFeatureContext = createContext<MyFeatureCtx>(undefined!);

export const useMyFeatureSelector = <T,>(selector: (ctx: MyFeatureCtx) => T) => {
  return useContextSelector(MyFeatureContext, selector);
};

export const MyFeatureProvider = ({ children }) => {
  const value = useMyFeature();  // ✅ hook 사용만!
  return <MyFeatureContext.Provider value={value}>{children}</MyFeatureContext.Provider>;
};
```

---

**Step 3: 사용 코드 수정**

```typescript
// ❌ 기존
const { state, handleClick } = useContext(MyContext)

// ✅ 새 패턴
const state = useMyFeatureSelector((ctx) => ctx.state.state)
const handleClick = useMyFeatureSelector((ctx) => ctx.actions.handleClick)
```

---

## 체크리스트

Provider/hooks 분리 작업 시 확인:

- [ ] hooks 파일에 모든 로직 작성했는가?
- [ ] Provider는 단순히 hook 반환값을 감싸는가?
- [ ] state/actions가 명확히 분리되었는가?
- [ ] useMemo로 반환값을 최적화했는가?
- [ ] `ReturnType<typeof useHook>`로 타입 정의했는가?
- [ ] Selector hook을 Provider 파일에서 export했는가?
- [ ] Context는 Provider 파일 내부에서만 사용하는가?
- [ ] 네이밍 컨벤션을 준수했는가?

---

## 결론

**핵심 요약:**

- Provider는 단순하게 (hook 사용만)
- 로직은 hooks로 분리
- state/actions 명확히 구분
- ReturnType으로 타입 자동 추론

**금지:** Provider에 useState, useCallback, useMemo 직접 작성
**권장:** hooks 파일에 모든 로직 작성
