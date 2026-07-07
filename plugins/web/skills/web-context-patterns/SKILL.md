---
name: web-context-patterns
description: React Context + use-context-selector 팀 컨벤션. Provider/hooks 분리, selector 최적화, useMemo 필터 체인. Context/Provider 설계 시 참조.
metadata:
  author: klleon
---

# React Context 팀 컨벤션

React Context + use-context-selector를 사용한 상태 관리 패턴.

## 최신 API 확인

use-context-selector 라이브러리는 빠르게 진화하므로 최신 문서를 확인하세요:

```bash
# 설치
npm install use-context-selector

# 버전 확인
npm list use-context-selector
```

**참고 문서:**

- [use-context-selector GitHub](https://github.com/dai-shi/use-context-selector)
- [React Context API 공식 문서](https://react.dev/reference/react/createContext)

---

## 상세 문서

| 문서                                                                         | 용도                                         |
| ---------------------------------------------------------------------------- | -------------------------------------------- |
| [references/provider-hooks-pattern.md](references/provider-hooks-pattern.md) | Provider/hooks 분리 핵심 패턴, 네이밍 컨벤션 |
| [references/use-context-selector.md](references/use-context-selector.md)     | Selector 최적화, 성능, 디버깅                |
| [references/filter-patterns.md](references/filter-patterns.md)               | useMemo 필터 체인 설계                       |
| [references/real-world-examples.md](references/real-world-examples.md)       | Dashboard/Creator 완전한 구현 예시           |
| [references/anti-patterns.md](references/anti-patterns.md)                   | 금지 패턴 및 마이그레이션                    |

---

## 금지 패턴 (Do/Don't)

| ❌ 금지                 | ✅ 권장                   | 이유                    |
| ----------------------- | ------------------------- | ----------------------- |
| Provider에 로직 작성    | hooks에 로직 분리         | 테스트 용이성, 재사용성 |
| 전체 context 구독       | selector로 필요한 값만    | 불필요한 리렌더 방지    |
| state/actions 분리 없이 | state/actions 명확히 분리 | 코드 가독성             |
| Context 직접 export     | useSelector hook export   | 일관된 사용 패턴        |

---

## 핵심 패턴 (Quick Reference)

### 1. Provider/hooks 분리 패턴

```typescript
// ✅ 올바른 구조
// hooks/useDashboard.ts
import { useMemo } from 'react';
import { useMyCharacters } from '@/api/character/character.queries';

const useDashboard = () => {
  const { data: characters } = useMyCharacters();

  const stats = useMemo(() => ({
    total: characters.length,
    published: characters.filter(c => c.status === 'published').length,
  }), [characters]);

  return useMemo(() => ({
    state: { characters, stats },
    actions: { /* 액션 함수들 */ },
  }), [characters, stats]);
};

// providers/DashboardProvider.tsx
import { createContext } from 'use-context-selector';
import { useDashboard } from '../hooks/useDashboard';

type DashboardCtx = ReturnType<typeof useDashboard>;
const DashboardContext = createContext<DashboardCtx>(undefined!);

export const DashboardProvider = ({ children }) => {
  const value = useDashboard();  // 로직은 hook에서!
  return <DashboardContext.Provider value={value}>{children}</DashboardContext.Provider>;
};
```

---

### 2. use-context-selector 사용법

```typescript
import { useContextSelector } from 'use-context-selector'
import { DashboardContext } from '../providers/DashboardProvider'

// ❌ 금지: 전체 context 구독
const { characters, stats, handleEdit } = useContext(DashboardContext)

// ✅ 권장: selector로 필요한 값만
const characters = useContextSelector(DashboardContext, (ctx) => ctx.state.characters)

const handleEdit = useContextSelector(DashboardContext, (ctx) => ctx.actions.handleEdit)
```

**장점:** `handleEdit`만 변경되어도 `characters`를 사용하는 컴포넌트는 리렌더 안됨!

---

### 3. useMemo 필터 체인

```typescript
const useDashboard = () => {
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

  // 2단계: 필터링 (stats 클릭 시 filter 변경 → 자동 재계산)
  const filteredCharacters = useMemo(() => {
    if (filter === 'all') return characters
    return characters.filter((c) => c.status === filter)
  }, [characters, filter])

  return useMemo(
    () => ({
      state: { characters, stats, filteredCharacters, filter },
      actions: { setFilter },
    }),
    [characters, stats, filteredCharacters, filter],
  )
}
```

---

## 체크리스트

Context/Provider 작업 시 확인:

- [ ] 모든 로직이 hooks 파일에 있는가?
- [ ] Provider는 단순히 hook 반환값을 감싸는가?
- [ ] selector로 필요한 값만 구독하는가?
- [ ] state/actions가 명확히 분리되어 있는가?
- [ ] useMemo로 계산된 값을 최적화했는가?
- [ ] TypeScript 타입이 `ReturnType<typeof useHook>`로 정의되었는가?

---

## 언제 사용하는가?

### ✅ Context 사용이 적합한 경우

- 여러 깊이의 컴포넌트가 같은 상태를 공유
- 페이지/Feature 단위의 복잡한 상태 관리
- Modal, 폼 상태 등 UI 상태 관리

### ❌ Context가 과할 수 있는 경우

- 단순한 props drilling (2-3 depth)
- 전역 상태 관리 (Zustand, Redux 고려)
- 서버 상태 (TanStack Query면 충분)

---

## 설치

```bash
npm install use-context-selector
# 또는
pnpm install use-context-selector
# 또는
yarn add use-context-selector
```

---

## 빠른 시작

```typescript
// 1. Context 생성
import { createContext, useContextSelector } from 'use-context-selector';

const MyContext = createContext<MyContextType>(undefined!);

// 2. Provider 정의
export const MyProvider = ({ children }) => {
  const value = useMyHook();  // 로직은 hook에서
  return <MyContext.Provider value={value}>{children}</MyContext.Provider>;
};

// 3. Selector hook export
export const useMySelector = <T,>(selector: (ctx: MyContextType) => T) => {
  return useContextSelector(MyContext, selector);
};

// 4. 사용
const characters = useMySelector(ctx => ctx.state.characters);
```

상세한 구현은 references/ 문서를 참조하세요.
