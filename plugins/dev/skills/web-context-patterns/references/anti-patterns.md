# 안티패턴 및 마이그레이션

Context 설계 시 피해야 할 패턴과 올바른 패턴으로의 마이그레이션 가이드.

## 금지 패턴

### 1. Provider에 로직 작성 (❌)

**문제점:**

- Provider 파일이 비대해짐 (100+ 줄)
- 테스트하기 어려움
- 로직 재사용 불가능
- 타입 관리 복잡

```typescript
// ❌ 안티패턴
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

  // ...100줄의 로직...

  return (
    <MyContext.Provider
      value={{ value, characters, stats, handleClick, openDeleteModal }}
    >
      {children}
    </MyContext.Provider>
  );
};
```

---

**올바른 방법:**

```typescript
// ✅ hooks에 로직 분리
// hooks/useMyFeature.ts
const useMyFeature = () => {
  // 모든 로직을 여기에...
  return useMemo(() => ({ state, actions }), [...]);
};

// providers/MyFeatureProvider.tsx
export const MyFeatureProvider = ({ children }) => {
  const value = useMyFeature();  // 단순!
  return <MyContext.Provider value={value}>{children}</MyContext.Provider>;
};
```

---

### 2. 전체 context 구독 (❌)

**문제점:**

- 불필요한 리렌더 발생
- 성능 저하 (특히 큰 Context)
- selector의 이점 미활용

```typescript
// ❌ 안티패턴: 전체 구독
const MyComponent = () => {
  const { characters, stats, deleteTarget, isDeleting } = useContext(MyContext);

  // characters만 사용
  return <div>{characters.length}</div>;
};

// 문제: stats, deleteTarget, isDeleting 변경 시에도 리렌더!
```

---

**올바른 방법:**

```typescript
// ✅ 필요한 값만 구독
const MyComponent = () => {
  const characters = useMyFeatureSelector(ctx => ctx.state.characters);

  return <div>{characters.length}</div>;
};

// stats, deleteTarget, isDeleting 변경 시 리렌더 안됨!
```

---

### 3. state/actions 분리 없이 (❌)

**문제점:**

- 코드 의도 불명확
- selector 사용 시 혼란
- 유지보수 어려움

```typescript
// ❌ 안티패턴: 평면 구조
return useMemo(() => ({
  characters,
  stats,
  deleteTarget,
  isDeleting,
  setFilter,
  openDeleteModal,
  confirmDelete,
}), [...]);

// 사용 시 헷갈림
const stats = useMyFeatureSelector(ctx => ctx.stats);  // 데이터인가 함수인가?
const setFilter = useMyFeatureSelector(ctx => ctx.setFilter);
```

---

**올바른 방법:**

```typescript
// ✅ state/actions 분리
return useMemo(() => ({
  state: {
    characters,
    stats,
    deleteTarget,
    isDeleting,
  },
  actions: {
    setFilter,
    openDeleteModal,
    confirmDelete,
  },
}), [...]);

// 사용 시 명확
const stats = useMyFeatureSelector(ctx => ctx.state.stats);  // 데이터
const setFilter = useMyFeatureSelector(ctx => ctx.actions.setFilter);  // 함수
```

---

### 4. Context 직접 export (❌)

**문제점:**

- 전체 구독 유도
- 일관성 없는 사용 패턴
- selector 미사용

```typescript
// ❌ 안티패턴
export const MyContext = createContext(...);

// 다른 파일에서
import { MyContext } from '../providers/MyProvider';
const value = useContext(MyContext);  // 전체 구독!
```

---

**올바른 방법:**

```typescript
// ✅ Selector hook만 export
const MyContext = createContext(...);  // export 안함!

export const useMyFeatureSelector = <T,>(selector: (ctx: Ctx) => T) => {
  return useContextSelector(MyContext, selector);
};

// 다른 파일에서
import { useMyFeatureSelector } from '../providers/MyProvider';
const value = useMyFeatureSelector(ctx => ctx.state.value);  // 부분 구독!
```

---

### 5. 과도한 중첩 (❌)

**문제점:**

- 디버깅 어려움
- 성능 저하
- 코드 복잡도 증가

```tsx
// ❌ 안티패턴: 과도한 Provider 중첩
<ThemeProvider>
  <UserProvider>
    <DashboardProvider>
      <SettingsProvider>
        <ModalProvider>
          <ToastProvider>
            <MyComponent />
          </ToastProvider>
        </ModalProvider>
      </SettingsProvider>
    </DashboardProvider>
  </UserProvider>
</ThemeProvider>
```

---

**올바른 방법:**

```tsx
// ✅ Provider 조합 컴포넌트
const AppProviders = ({ children }: { children: ReactNode }) => (
  <ThemeProvider>
    <UserProvider>
      <ToastProvider>{children}</ToastProvider>
    </UserProvider>
  </ThemeProvider>
)

// 페이지별 Provider는 page.tsx에서
;<AppProviders>
  <DashboardProvider>
    <DashboardPage />
  </DashboardProvider>
</AppProviders>
```

**원칙:**

- 전역 Provider (Theme, User, Toast): 3-4개로 제한
- 페이지/Feature Provider: page.tsx에서 필요할 때만

---

## 마이그레이션 가이드

### 기존 Context → 새 패턴

**Step 1: hooks 파일 생성**

```bash
mkdir -p features/MyFeature/hooks
touch features/MyFeature/hooks/useMyFeature.ts
```

---

**Step 2: Provider에서 로직 추출**

```typescript
// 기존 Provider에서 로직 복사 → hooks 파일로 이동
// hooks/useMyFeature.ts
const useMyFeature = () => {
  // Provider에 있던 useState, useCallback, useMemo 모두 복사
  const [value, setValue] = useState(0)
  // ...

  return useMemo(
    () => ({
      state: { value },
      actions: { setValue },
    }),
    [value],
  )
}

export default useMyFeature
```

---

**Step 3: Provider 단순화**

```typescript
// providers/MyFeatureProvider.tsx
import useMyFeature from '../hooks/useMyFeature';

type MyFeatureCtx = ReturnType<typeof useMyFeature>;
const MyFeatureContext = createContext<MyFeatureCtx>(undefined!);

export const useMyFeatureSelector = <T,>(selector: (ctx: MyFeatureCtx) => T) => {
  return useContextSelector(MyFeatureContext, selector);
};

export const MyFeatureProvider = ({ children }) => {
  const value = useMyFeature();
  return <MyContext.Provider value={value}>{children}</MyContext.Provider>;
};
```

---

**Step 4: 사용 코드 수정**

```typescript
// ❌ 기존
import { MyContext } from '../providers/MyProvider'
const { value, setValue } = useContext(MyContext)

// ✅ 새 패턴
import { useMyFeatureSelector } from '../providers/MyProvider'
const value = useMyFeatureSelector((ctx) => ctx.state.value)
const setValue = useMyFeatureSelector((ctx) => ctx.actions.setValue)
```

---

### useState → Context

**언제 마이그레이션하는가?**

**✅ Context로 전환:**

- Props drilling이 3 depth 이상
- 5개 이상 컴포넌트가 같은 상태 공유
- 상태 + 관련 액션이 복잡함 (10+ 줄)

**❌ useState 유지:**

- 단일 컴포넌트 내부 상태
- Props drilling 2 depth 이하
- 간단한 상태 (toggle, input 값 등)

---

**마이그레이션 예시:**

```typescript
// Before: useState + Props drilling
const ParentComponent = () => {
  const [user, setUser] = useState(null);

  return (
    <div>
      <Header user={user} />
      <Sidebar user={user} />
      <Content user={user} onUserChange={setUser} />
    </div>
  );
};

// After: Context
const ParentComponent = () => {
  return (
    <UserProvider>
      <Header />
      <Sidebar />
      <Content />
    </UserProvider>
  );
};

// 각 컴포넌트에서
const user = useUserSelector(ctx => ctx.state.user);
const setUser = useUserSelector(ctx => ctx.actions.setUser);
```

---

### Redux → Context

**언제 전환하는가?**

**✅ Context로 전환:**

- 페이지/Feature 범위 상태 (전역 아님)
- 복잡한 reducer 불필요
- 미들웨어 불필요

**❌ Redux 유지:**

- 진짜 전역 상태 (모든 페이지에서 사용)
- Time-travel debugging 필요
- Redux DevTools 필요

---

**전환 전략:**

```typescript
// Before: Redux slice
const userSlice = createSlice({
  name: 'user',
  initialState: { data: null, isLoading: false },
  reducers: {
    setUser: (state, action) => {
      state.data = action.payload
    },
  },
})

// After: Context + hooks
const useUser = () => {
  const [user, setUser] = useState(null)
  const [isLoading, setIsLoading] = useState(false)

  return useMemo(
    () => ({
      state: { user, isLoading },
      actions: { setUser, setIsLoading },
    }),
    [user, isLoading],
  )
}
```

---

## 체크리스트

마이그레이션 전 확인:

- [ ] Provider에 로직이 100줄 이상인가? → hooks 분리 고려
- [ ] 전체 context 구독하는 컴포넌트 3개 이상인가? → selector 전환
- [ ] Props drilling이 3 depth 이상인가? → Context 전환 고려
- [ ] state/actions가 섞여있나? → 분리 필요
- [ ] Context를 직접 export하나? → Selector hook으로 변경

---

## 마이그레이션 체크리스트

기존 Context를 새 패턴으로 전환 시:

**Phase 1: 구조 변경**

- [ ] hooks 파일 생성
- [ ] Provider에서 로직 추출 → hooks로 이동
- [ ] state/actions 분리
- [ ] useMemo로 반환값 최적화

**Phase 2: Provider 수정**

- [ ] `use-context-selector`에서 createContext import
- [ ] ReturnType으로 타입 정의
- [ ] Selector hook 추가
- [ ] Context 직접 export 제거

**Phase 3: 사용 코드 수정**

- [ ] useContext → useSelector 전환
- [ ] 전체 구독 → 필요한 값만 선택
- [ ] ctx.state._, ctx.actions._ 접근 패턴 적용

**Phase 4: 검증**

- [ ] 타입 에러 없음
- [ ] 불필요한 리렌더 감소 확인 (React DevTools)
- [ ] 기능 정상 작동

---

## 결론

**핵심 금지 패턴:**

1. Provider에 로직 작성
2. 전체 context 구독
3. state/actions 분리 없이
4. Context 직접 export
5. 과도한 Provider 중첩

**마이그레이션:**

- hooks 파일 생성 → 로직 이동
- use-context-selector 전환
- state/actions 분리
- Selector hook 제공

**검증:**

- React DevTools로 리렌더 확인
- 타입 에러 체크
- 기능 테스트
