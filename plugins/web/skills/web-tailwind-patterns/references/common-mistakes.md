# Tailwind CSS 흔한 실수

Tailwind CSS 사용 시 피해야 할 안티패턴과 올바른 해결책.

## 1. @apply 남용 (컴포넌트 프레임워크)

### ❌ 안티패턴

```css
/* styles.css */
@layer components {
  .card {
    @apply rounded-lg border p-4 shadow-md;
  }
  .card-title {
    @apply text-xl font-bold mb-2;
  }
  .card-content {
    @apply text-gray-600;
  }
}
```

```tsx
<div className="card">
  <h2 className="card-title">제목</h2>
  <p className="card-content">내용</p>
</div>
```

**문제점:**

- React/Vue 같은 컴포넌트 프레임워크에서는 컴포넌트로 추상화하는 것이 더 적합
- CSS 파일과 컴포넌트 파일을 오가며 수정 (유지보수 어려움)
- Tailwind의 workflow 이점 상실

---

### ✅ 올바른 방법

```tsx
// components/Card.tsx
export function Card({ title, children }: CardProps) {
  return (
    <div className="rounded-lg border p-4 shadow-md">
      <h2 className="text-xl font-bold mb-2">{title}</h2>
      <p className="text-gray-600">{children}</p>
    </div>
  )
}

// 사용
;<Card title="제목">내용</Card>
```

**장점:**

- 모든 스타일이 컴포넌트 안에
- props로 variants 전달 가능
- TypeScript 타입 안전성
- Tailwind workflow 유지

---

## 2. @apply는 작은 것만

### ✅ @apply 사용이 적합한 경우

**조건:**

- 컴포넌트 프레임워크를 사용하지 않는 경우
- 매우 작고 재사용 가능한 것 (버튼, 폼 컨트롤)
- 서드파티 라이브러리 스타일 override

```css
/* ✅ 적합: 작고 재사용 가능 */
@layer components {
  .btn {
    @apply px-4 py-2 rounded font-medium;
  }
}

/* ✅ 적합: 서드파티 override */
.select2-dropdown {
  @apply rounded-b-lg shadow-md;
}
.select2-search {
  @apply border border-gray-300 rounded;
}
```

---

### ❌ @apply 부적합한 경우

```css
/* ❌ 너무 큼 */
@layer components {
  .complex-card {
    @apply rounded-lg border-2 border-gray-200 bg-white p-6 shadow-lg
           hover:shadow-xl hover:border-blue-500
           focus:outline-none focus:ring-4 focus:ring-blue-300
           transition-all duration-300;
  }
}

/* ❌ 컴포넌트로 만들어야 함 */
.user-profile-header {
  @apply flex items-center gap-4 p-6 bg-gradient-to-r from-blue-500 to-purple-600;
}
```

**대신:**

```tsx
// ✅ 컴포넌트로
<div className="rounded-lg border-2 border-gray-200 bg-white p-6 shadow-lg hover:shadow-xl hover:border-blue-500 focus:outline-none focus:ring-4 focus:ring-blue-300 transition-all duration-300">
  {/* ... */}
</div>
```

---

## 3. arbitrary values 과용

### ⚠️ arbitrary values란?

```tsx
// 일회성 값을 [] 안에 직접 지정
<div className="top-[117px]" />
<div className="bg-[#bada55]" />
<div className="text-[22px]" />
```

---

### ✅ 적절한 사용

```tsx
// ✅ 진짜 일회성 값
<div className="top-[117px] lg:top-[344px]" />  // 레이아웃 미세 조정
<div className="max-w-[220px]" />  // 특정 디자인 요구사항
```

---

### ❌ 과용 (안티패턴)

```tsx
// ❌ 반복되는 값을 arbitrary로
<div className="w-[300px]" />
<div className="w-[300px]" />
<div className="w-[300px]" />

// ❌ 디자인 토큰이어야 할 값
<div className="bg-[#3b82f6]" />  // 이건 blue-500과 같음
<div className="text-[16px]" />   // 이건 text-base와 같음
```

---

### ✅ 올바른 방법

```tsx
// ✅ theme 확장
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      width: {
        '300': '300px',
      },
      colors: {
        brand: '#3b82f6',
      },
    },
  },
};

// 사용
<div className="w-300" />
<div className="bg-brand" />
```

**기준:**

- 2번 이상 사용 → theme에 추가
- 진짜 일회성 → arbitrary values

---

## 4. !important 남용

### ❌ 안티패턴

```tsx
// ❌ !important로 강제
<div className="!bg-blue-500 !text-white !p-4" />
```

**문제점:**

- Specificity 문제 숨김
- 나중에 override 더 어려워짐
- 근본 원인 해결 안됨

---

### ✅ 올바른 방법

**원인 1: Specificity 충돌**

```tsx
// ❌ 충돌
<div className="text-gray-600">  // Specificity 낮음
  <p className="text-blue-500">텍스트</p>  // 적용 안됨
</div>

// ✅ 해결: 더 구체적인 클래스
<div className="text-gray-600">
  <p className="text-blue-500">텍스트</p>  // 정상 작동 (자식이 더 구체적)
</div>
```

---

**원인 2: 서드파티 라이브러리**

```tsx
// ❌ !important로 강제
<input className="!border-blue-500" />

// ✅ 해결: @layer로 우선순위 조정
// styles.css
@layer base {
  input {
    @apply border-gray-300;
  }
}

// 컴포넌트에서
<input className="border-blue-500" />  // 정상 작동
```

---

## 5. 인라인 스타일 혼용

### ❌ 안티패턴

```tsx
<div className="flex items-center gap-4" style={{ marginTop: '20px', color: '#333' }}>
  {/* ... */}
</div>
```

**문제점:**

- 일관성 없음
- Tailwind 디자인 토큰 미사용
- 다크모드 지원 어려움

---

### ✅ 올바른 방법

```tsx
// ✅ Tailwind 클래스만
<div className="flex items-center gap-4 mt-5 text-gray-700">
  {/* ... */}
</div>

// ✅ 진짜 동적 값만 인라인
<div
  className="flex items-center gap-4"
  style={{ width: `${percentage}%` }}  // 계산된 값
>
  {/* ... */}
</div>
```

---

## 6. CSS-Only Abstraction

### ❌ 안티패턴

```html
<div class="chat-notification">
  <div class="chat-notification-logo-wrapper">
    <img class="chat-notification-logo" src="/img/logo.svg" />
  </div>
  <div class="chat-notification-content">
    <div class="chat-notification-title">ChitChat</div>
    <p class="chat-notification-message">You have a new message!</p>
  </div>
</div>
```

```css
.chat-notification {
  /* ... */
}
.chat-notification-logo-wrapper {
  /* ... */
}
.chat-notification-logo {
  /* ... */
}
```

**문제점:**

- CSS만 업데이트 가능, HTML 구조는 여전히 중복
- 구조 변경 시 모든 인스턴스 수정 필요

---

### ✅ 올바른 방법 (컴포넌트)

```tsx
// components/ChatNotification.tsx
export function ChatNotification({ title, message }: Props) {
  return (
    <div className="flex items-center gap-4 p-4 bg-white rounded-lg shadow">
      <div className="flex-shrink-0">
        <img src="/img/logo.svg" className="w-12 h-12" alt="Logo" />
      </div>
      <div className="flex-1">
        <h3 className="font-bold text-lg">{title}</h3>
        <p className="text-gray-600">{message}</p>
      </div>
    </div>
  )
}

// 사용
;<ChatNotification title="ChitChat" message="You have a new message!" />
```

**장점:**

- 구조 + 스타일 한 곳에
- props로 커스터마이징
- 재사용성 극대화

---

## 7. 과도한 커스텀 클래스

### ❌ 안티패턴

```css
/* styles.css */
.primary-btn {
  @apply bg-blue-500 text-white px-4 py-2 rounded;
}
.secondary-btn {
  @apply bg-gray-500 text-white px-4 py-2 rounded;
}
.danger-btn {
  @apply bg-red-500 text-white px-4 py-2 rounded;
}
/* 10개 이상의 커스텀 버튼 클래스... */
```

**문제점:**

- Tailwind의 유틸리티 철학에 반함
- CSS 파일이 비대해짐
- 유지보수 어려움

---

### ✅ 올바른 방법

```tsx
// components/Button.tsx (cva 또는 tv 사용)
import { cva } from 'class-variance-authority';

const buttonVariants = cva('px-4 py-2 rounded text-white', {
  variants: {
    color: {
      primary: 'bg-blue-500',
      secondary: 'bg-gray-500',
      danger: 'bg-red-500',
    },
  },
});

export function Button({ color, children }: ButtonProps) {
  return (
    <button className={buttonVariants({ color })}>
      {children}
    </button>
  );
}

// 사용
<Button color="primary">Submit</Button>
<Button color="danger">Delete</Button>
```

**장점:**

- TypeScript 타입 안전성
- variants 관리 용이
- Tailwind 유틸리티 그대로 사용

---

## 8. Specificity 충돌

### 문제 상황

```tsx
// ❌ 부모의 스타일이 자식을 override
<div className="text-red-500">
  <p className="text-blue-500">이 텍스트는 무슨 색?</p>
</div>
```

**결과:** 파란색 (자식이 더 구체적)

---

### 해결 방법

```tsx
// ✅ 명시적 상속
<div className="text-red-500">
  <p className="text-blue-500">파란색</p>
  <p>빨간색 (부모 상속)</p>
</div>

// ✅ 전체 override 필요 시
<div>
  <p className="text-red-500">빨간색</p>
  <p className="text-blue-500">파란색</p>
</div>
```

---

## 9. Purge/Content 설정 오류

### ❌ 안티패턴

```js
// tailwind.config.js
module.exports = {
  content: [
    './src/**/*.{js,jsx,ts,tsx}', // ✅
  ],
  // ❌ 동적 클래스가 제거됨!
}
```

```tsx
// ❌ 동적 클래스명 생성
const colorClass = `bg-${color}-500` // Purge에서 제거!
;<div className={colorClass} />
```

**결과:** 프로덕션 빌드에서 스타일 누락

---

### ✅ 올바른 방법

```tsx
// ✅ 전체 클래스명 사용
const colorClass = color === 'blue' ? 'bg-blue-500' : 'bg-red-500'
;<div className={colorClass} />

// ✅ 또는 safelist에 추가
// tailwind.config.js
module.exports = {
  safelist: ['bg-blue-500', 'bg-red-500', 'bg-green-500'],
}
```

---

## 10. JIT 모드 오해

### ❌ 잘못된 이해

"arbitrary values를 사용하면 번들 크기가 커진다"

**실제:**

- JIT 모드에서는 사용한 클래스만 생성
- arbitrary values도 동일 (사용한 것만 CSS에 포함)

---

### ✅ 올바른 사용

```tsx
// ✅ JIT에서 안전
<div className="top-[117px]" />  // CSS에 .top-\[117px\] 생성
<div className="bg-[#bada55]" />  // CSS에 .bg-\[\#bada55\] 생성

// 사용하지 않으면 CSS에 포함 안됨
```

**주의:**

- Purge 설정에 해당 파일 포함 필수
- 동적 생성은 여전히 불가

---

## 11. 유틸리티 중복

### ❌ 안티패턴

```tsx
// ❌ 같은 클래스 여러 번
<img className="inline-block h-12 w-12 rounded-full ring-2 ring-white" />
<img className="inline-block h-12 w-12 rounded-full ring-2 ring-white" />
<img className="inline-block h-12 w-12 rounded-full ring-2 ring-white" />
```

**문제점:**

- 중복 코드
- 수정 시 모든 곳 변경 필요

---

### ✅ 올바른 방법

```tsx
// ✅ 컴포넌트로 추상화
const Avatar = ({ src, alt }: AvatarProps) => (
  <img src={src} alt={alt} className="inline-block h-12 w-12 rounded-full ring-2 ring-white" />
)

// 사용
;<div className="flex -space-x-2">
  <Avatar src="/user1.jpg" alt="User 1" />
  <Avatar src="/user2.jpg" alt="User 2" />
  <Avatar src="/user3.jpg" alt="User 3" />
</div>
```

---

## 체크리스트

Tailwind 사용 시 확인:

- [ ] @apply를 컴포넌트 대신 사용하지 않았는가?
- [ ] @apply는 작고 재사용 가능한 것만 사용했는가?
- [ ] arbitrary values가 2번 이상 반복되지 않는가? (theme 추가 고려)
- [ ] !important를 남용하지 않았는가?
- [ ] 인라인 스타일과 혼용하지 않았는가?
- [ ] 동적 클래스명을 생성하지 않았는가?
- [ ] Purge 설정에 모든 템플릿 파일이 포함되었는가?

---

## 베스트 프랙티스

### 1. Tailwind의 철학 따르기

**"Utility-First"**

- 유틸리티 클래스를 HTML/JSX에 직접 사용
- 컴포넌트로 추상화 (CSS가 아닌)
- @apply는 예외적 상황만

---

### 2. 추상화 우선순위

1. **컴포넌트** (가장 권장)
2. **cva/tailwind-variants** (variants 관리)
3. **@apply** (최후의 수단)

---

### 3. 일관성 유지

```tsx
// ✅ 디자인 토큰 사용
<div className="text-blue-500" />  // theme에 정의된 색상
<div className="p-4" />  // theme에 정의된 spacing

// ❌ 일관성 없음
<div className="text-[#3b82f6]" />  // 같은 색이지만 arbitrary
<div className="p-[16px]" />  // 같은 spacing이지만 arbitrary
```

---

## 결론

**핵심 원칙:**

- 컴포넌트 > cva > @apply
- arbitrary values는 진짜 일회성만
- !important 대신 specificity 조정
- 인라인 스타일 지양

**Tailwind 철학:**

- Utility-First
- 컴포넌트로 추상화
- 디자인 토큰 일관성
