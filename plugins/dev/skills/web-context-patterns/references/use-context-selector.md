# use-context-selector 최적화

불필요한 리렌더링을 방지하기 위한 use-context-selector 사용법 및 성능 최적화.

## 왜 필요한가?

### React Context API의 문제점

```tsx
// ❌ React 기본 Context
const MyContext = createContext({ value: 0, text: '', onClick: () => {} })

// 컴포넌트 A: value만 사용
function ComponentA() {
  const { value } = useContext(MyContext)
  return <div>{value}</div>
}

// 컴포넌트 B: text만 사용
function ComponentB() {
  const { text } = useContext(MyContext)
  return <div>{text}</div>
}
```

**문제:**

- `value` 변경 → ComponentA, ComponentB 둘 다 리렌더 (B는 불필요!)
- `text` 변경 → ComponentA, ComponentB 둘 다 리렌더 (A는 불필요!)
- Context 값 중 하나만 변경되어도 **모든 소비자가 리렌더**

---

### use-context-selector의 해결책

```tsx
// ✅ use-context-selector
import { createContext, useContextSelector } from 'use-context-selector'

const MyContext = createContext({ value: 0, text: '', onClick: () => {} })

// 컴포넌트 A: value만 구독
function ComponentA() {
  const value = useContextSelector(MyContext, (ctx) => ctx.value)
  return <div>{value}</div>
}

// 컴포넌트 B: text만 구독
function ComponentB() {
  const text = useContextSelector(MyContext, (ctx) => ctx.text)
  return <div>{text}</div>
}
```

**해결:**

- `value` 변경 → ComponentA만 리렌더 ✅
- `text` 변경 → ComponentB만 리렌더 ✅
- **선택한 값이 변경될 때만 리렌더**

---

## 기본 사용법

### 설치

```bash
npm install use-context-selector
# 또는
pnpm install use-context-selector
```

---

### Context 생성

```typescript
// providers/MyFeatureProvider.tsx
import { createContext, useContextSelector } from 'use-context-selector'
import useMyFeature from '../hooks/useMyFeature'

type MyFeatureCtx = ReturnType<typeof useMyFeature>

// ✅ createContext from use-context-selector
const MyFeatureContext = createContext<MyFeatureCtx>(undefined as unknown as MyFeatureCtx)
```

**중요:** `use-context-selector`의 `createContext`를 사용해야 합니다 (React 기본 `createContext` 아님).

---

### Selector Hook 정의

```typescript
// providers/MyFeatureProvider.tsx
export const useMyFeatureSelector = <T>(selector: (ctx: MyFeatureCtx) => T) => {
  return useContextSelector(MyFeatureContext, (context) => {
    // 개발 환경 에러 체크
    if (process.env.NODE_ENV !== 'production' && context === undefined) {
      throw new Error('MyFeatureContext.Provider 안에서만 사용하세요.')
    }
    return selector(context)
  })
}
```

**역할:**

- 타입 안전성 보장 (`<T,>` 제네릭)
- 개발 환경에서 Provider 누락 에러 감지
- 사용자에게 간결한 API 제공

---

## 패턴별 가이드

### 1. 단일 값 선택

```tsx
// ✅ 단일 값 선택
const characters = useMyFeatureSelector((ctx) => ctx.state.characters)
const isDeleting = useMyFeatureSelector((ctx) => ctx.state.isDeleting)

// characters 변경 시만 리렌더
// isDeleting 변경은 무관
```

---

### 2. 여러 값 선택

```tsx
// ✅ 여러 값 선택 (객체 반환)
const { characters, stats } = useMyFeatureSelector((ctx) => ({
  characters: ctx.state.characters,
  stats: ctx.state.stats,
}))

// ⚠️ 주의: 객체 새로 생성 → 매번 리렌더 (shallow equality)
```

**해결 (useMemo):**

```tsx
// ✅ useMemo로 최적화
const data = useMyFeatureSelector((ctx) =>
  useMemo(
    () => ({
      characters: ctx.state.characters,
      stats: ctx.state.stats,
    }),
    [ctx.state.characters, ctx.state.stats],
  ),
)
```

**또는 개별 선택 (더 간단):**

```tsx
// ✅ 개별 선택 (권장)
const characters = useMyFeatureSelector((ctx) => ctx.state.characters)
const stats = useMyFeatureSelector((ctx) => ctx.state.stats)
```

---

### 3. 배열 필터링

```tsx
// ❌ 금지: 배열 필터링을 selector에서
const published = useMyFeatureSelector(ctx =>
  ctx.state.characters.filter(c => c.status === 'published')
);
// 문제: 매번 새 배열 생성 → 매번 리렌더

// ✅ 권장: hook에서 useMemo로 필터링
// hooks/useMyFeature.ts
const publishedCharacters = useMemo(() =>
  characters.filter(c => c.status === 'published'),
  [characters]
);

return useMemo(() => ({
  state: { characters, publishedCharacters },
  actions: { ... },
}), [...]);

// 컴포넌트에서 사용
const published = useMyFeatureSelector(ctx => ctx.state.publishedCharacters);
```

---

### 4. 함수(액션) 선택

```tsx
// ✅ 함수 선택
const handleEdit = useMyFeatureSelector((ctx) => ctx.actions.handleEdit)
const confirmDelete = useMyFeatureSelector((ctx) => ctx.actions.confirmDelete)

// ⚠️ 주의: useCallback으로 메모이제이션 필수!
// hooks/useMyFeature.ts
const handleEdit = useCallback(
  (id: string) => {
    router.push(`/edit/${id}`)
  },
  [router],
)

return useMemo(
  () => ({
    actions: { handleEdit }, // 함수 참조가 안정적이어야 함
  }),
  [handleEdit],
)
```

---

## 성능 최적화

### 리렌더 발생 조건

**use-context-selector의 동작:**

1. Context 값 변경 감지
2. Selector 함수 실행
3. **이전 반환값과 비교 (shallow equality)**
4. 다르면 리렌더, 같으면 스킵

**Shallow Equality:**

```typescript
// Primitive 값
1 === 1          // true → 리렌더 안함
'text' === 'text' // true → 리렌더 안함

// 객체/배열 (참조 비교)
{ a: 1 } === { a: 1 }  // false → 리렌더!
[] === []              // false → 리렌더!
```

---

### 메모이제이션 전략

**1. Primitive 값은 그대로 선택 (최적)**

```tsx
// ✅ Primitive 값 - 최적
const count = useMyFeatureSelector((ctx) => ctx.state.count)
const text = useMyFeatureSelector((ctx) => ctx.state.text)
const isLoading = useMyFeatureSelector((ctx) => ctx.state.isLoading)
```

---

**2. 객체는 hooks에서 useMemo (권장)**

```tsx
// ✅ hooks에서 미리 메모이제이션
// hooks/useMyFeature.ts
const stats = useMemo(() => ({
  total: characters.length,
  published: characters.filter(...).length,
}), [characters]);

return useMemo(() => ({
  state: { stats },  // 이미 메모이제이션됨
}), [stats]);

// 컴포넌트에서 안전하게 선택
const stats = useMyFeatureSelector(ctx => ctx.state.stats);
// stats 객체가 변경될 때만 리렌더 (shallow equality 통과)
```

---

**3. 배열은 hooks에서 useMemo (권장)**

```tsx
// ✅ hooks에서 미리 필터링 + 메모이제이션
const filteredCharacters = useMemo(
  () => characters.filter((c) => c.status === filter),
  [characters, filter],
)

return useMemo(
  () => ({
    state: { filteredCharacters },
  }),
  [filteredCharacters],
)

// 컴포넌트에서
const filtered = useMyFeatureSelector((ctx) => ctx.state.filteredCharacters)
```

---

**4. 함수는 useCallback (필수)**

```tsx
// ✅ hooks에서 useCallback
const handleClick = useCallback(() => {
  // 로직...
}, [dependencies])

return useMemo(
  () => ({
    actions: { handleClick },
  }),
  [handleClick],
)

// 컴포넌트에서
const handleClick = useMyFeatureSelector((ctx) => ctx.actions.handleClick)
// handleClick 참조가 변경될 때만 리렌더
```

---

## 디버깅

### 리렌더 추적

**React DevTools Profiler 사용:**

```tsx
// 컴포넌트에 임시 로그 추가
function MyComponent() {
  const value = useMyFeatureSelector((ctx) => ctx.state.value)

  console.log('MyComponent rendered:', { value })

  return <div>{value}</div>
}
```

**확인:**

1. Context 값 변경
2. Console에 로그 출력 여부 확인
3. 불필요한 리렌더 발생 시 selector 수정

---

### 일반적인 실수

#### 실수 1: Selector에서 새 객체 생성

```tsx
// ❌ 매번 새 객체 → 매번 리렌더
const data = useMyFeatureSelector((ctx) => ({
  characters: ctx.state.characters,
  stats: ctx.state.stats,
}))

// ✅ 개별 선택
const characters = useMyFeatureSelector((ctx) => ctx.state.characters)
const stats = useMyFeatureSelector((ctx) => ctx.state.stats)
```

---

#### 실수 2: Selector에서 배열 필터링

```tsx
// ❌ 매번 새 배열 → 매번 리렌더
const published = useMyFeatureSelector((ctx) =>
  ctx.state.characters.filter((c) => c.status === 'published'),
)

// ✅ hooks에서 미리 필터링
// hooks에서:
const publishedCharacters = useMemo(
  () => characters.filter((c) => c.status === 'published'),
  [characters],
)

// 컴포넌트에서:
const published = useMyFeatureSelector((ctx) => ctx.state.publishedCharacters)
```

---

#### 실수 3: useCallback 누락

```tsx
// ❌ hooks에서 useCallback 없음
const handleClick = () => {
  // 매번 새 함수!
  console.log('clicked')
}

return useMemo(
  () => ({
    actions: { handleClick },
  }),
  [handleClick],
) // 의존성에 포함 → 매번 새 객체

// ✅ useCallback 사용
const handleClick = useCallback(() => {
  console.log('clicked')
}, []) // 함수 참조 안정적

return useMemo(
  () => ({
    actions: { handleClick },
  }),
  [handleClick],
) // 참조 변경 안됨
```

---

#### 실수 4: Context 직접 export

```tsx
// ❌ Context 직접 export
export const MyContext = createContext(...);

// 컴포넌트에서
import { MyContext } from '../providers/MyProvider';
const value = useContext(MyContext);  // 전체 구독!

// ✅ Selector hook만 export
export const useMyFeatureSelector = <T,>(selector: (ctx: Ctx) => T) => {
  return useContextSelector(MyContext, selector);
};

// 컴포넌트에서
import { useMyFeatureSelector } from '../providers/MyProvider';
const value = useMyFeatureSelector(ctx => ctx.state.value);  // 부분 구독!
```

---

#### 실수 5: 개발 환경 에러 체크 누락

```tsx
// ❌ 에러 체크 없음
export const useMyFeatureSelector = <T,>(selector: (ctx: Ctx) => T) => {
  return useContextSelector(MyContext, selector)
}

// Provider 누락 시 undefined → 런타임 에러!

// ✅ 개발 환경 에러 체크
export const useMyFeatureSelector = <T,>(selector: (ctx: Ctx) => T) => {
  return useContextSelector(MyContext, (context) => {
    if (process.env.NODE_ENV !== 'production' && context === undefined) {
      throw new Error('MyContext.Provider 안에서만 사용하세요.')
    }
    return selector(context)
  })
}
```

---

## 타입 안전성

### ReturnType 활용

```typescript
// ✅ 자동 타입 추론
type MyFeatureCtx = ReturnType<typeof useMyFeature>

const MyFeatureContext = createContext<MyFeatureCtx>(undefined as unknown as MyFeatureCtx)

// TypeScript가 자동으로 selector 타입 추론:
const characters = useMyFeatureSelector((ctx) => ctx.state.characters)
//    ^? Character[]

const handleEdit = useMyFeatureSelector((ctx) => ctx.actions.handleEdit)
//    ^? (id: string) => void
```

---

### 제네릭 활용

```typescript
// Selector hook은 제네릭 <T,> 필수
export const useMyFeatureSelector = <T>(
  selector: (ctx: MyFeatureCtx) => T,
  //         ^? 타입 추론          ^? 반환 타입
) => {
  return useContextSelector(MyFeatureContext, selector)
  //     ^? 반환 타입 T
}

// 사용 시 자동 타입 추론
const count = useMyFeatureSelector((ctx) => ctx.state.count)
//    ^? number

const stats = useMyFeatureSelector((ctx) => ctx.state.stats)
//    ^? { total: number; published: number; }
```

---

## 성능 측정

### Before/After 비교

**Before (React Context):**

```tsx
// 전체 context 구독
const MyComponent = () => {
  const { characters, stats, deleteTarget, isDeleting } = useContext(MyContext)
  console.log('rendered') // 4개 값 중 하나만 변경되어도 출력
  return <div>{characters.length}</div>
}

// Context 업데이트:
// - characters 변경 → render ✅ (필요)
// - stats 변경 → render ❌ (불필요)
// - deleteTarget 변경 → render ❌ (불필요)
// - isDeleting 변경 → render ❌ (불필요)
```

**After (use-context-selector):**

```tsx
// 필요한 값만 구독
const MyComponent = () => {
  const characters = useMyFeatureSelector((ctx) => ctx.state.characters)
  console.log('rendered') // characters 변경 시에만 출력
  return <div>{characters.length}</div>
}

// Context 업데이트:
// - characters 변경 → render ✅ (필요)
// - stats 변경 → render ✅ (스킵!)
// - deleteTarget 변경 → render ✅ (스킵!)
// - isDeleting 변경 → render ✅ (스킵!)
```

---

### 실제 성능 개선

**web-almigo Dashboard 예시:**

- Context 값: `{ characters, stats, filter, filteredCharacters, deleteTarget, isDeleting }`
- 컴포넌트 수: ~10개 (Stats, Content, Modal 등)

**Before (전체 구독):**

- `deleteTarget` 변경 (모달 열기) → 10개 컴포넌트 모두 리렌더
- `isDeleting` 변경 (삭제 중) → 10개 컴포넌트 모두 리렌더

**After (Selector):**

- `deleteTarget` 변경 → Modal만 리렌더 (1개)
- `isDeleting` 변경 → Modal의 Button만 리렌더 (1개)

**성능 개선: ~90% 리렌더 감소**

---

## 체크리스트

use-context-selector 사용 시 확인:

- [ ] `use-context-selector`에서 `createContext` import
- [ ] Selector hook을 제네릭 `<T,>`로 정의
- [ ] 개발 환경 에러 체크 포함
- [ ] hooks에서 useMemo/useCallback 사용
- [ ] selector에서 새 객체/배열 생성 안함
- [ ] 필요한 값만 선택 (전체 구독 안함)
- [ ] TypeScript 타입 안전성 확보

---

## 결론

**핵심 요약:**

- 필요한 값만 구독 → 불필요한 리렌더 방지
- hooks에서 메모이제이션 → selector는 단순 선택만
- Primitive 값 선택이 가장 최적
- 함수는 useCallback 필수

**성능 개선:**

- 복잡한 페이지: ~90% 리렌더 감소
- 단순한 페이지: ~50% 리렌더 감소
