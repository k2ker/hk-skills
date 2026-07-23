---
name: web-tailwind-patterns
description: Tailwind CSS 팀 컨벤션. cn() 유틸리티, 조건부 클래스. v3/v4 버전별 패턴은 references 참조.
metadata:
  author: klleon
---

# Tailwind CSS 팀 컨벤션

## 버전별 패턴

| 문서                                 | 용도                 |
| ------------------------------------ | -------------------- |
| [references/v3.md](references/v3.md) | Tailwind CSS v3 패턴 |
| [references/v4.md](references/v4.md) | Tailwind CSS v4 패턴 |

### 버전 확인

```bash
# package.json에서 tailwindcss 버전 확인
npm list tailwindcss
```

### Context7 문서 조회

```
mcp__context7__query-docs(libraryId="/tailwindlabs/tailwindcss", query="v4 theme")
mcp__context7__query-docs(libraryId="/tailwindlabs/tailwindcss", query="gradient")
```

---

## 금지 패턴 (DO/DON'T)

| ❌ 금지                  | ✅ 권장                      | 이유                              |
| ------------------------ | ---------------------------- | --------------------------------- |
| `@apply` 남용 (컴포넌트) | 컴포넌트로 추상화            | React 등에서는 컴포넌트가 더 적합 |
| `@apply` 큰 패턴         | `@apply` 작은 것만 (버튼/폼) | 유지보수성                        |
| arbitrary values 과용    | theme에 추가                 | 일관성 유지                       |
| `!important` 남용        | specificity 조정             | 우선순위 문제                     |
| 인라인 스타일 혼용       | Tailwind 클래스만            | 일관성                            |

**상세:** [references/common-mistakes.md](references/common-mistakes.md)

---

## cn() 유틸리티 (공통)

### 설치

```bash
npm install clsx tailwind-merge
```

### 구현

```tsx
// utils/cn.ts
import { ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export const cn = (...inputs: ClassValue[]) => {
  return twMerge(clsx(inputs))
}
```

### 사용 예시

```tsx
import { cn } from '@/utils/cn' // 프로젝트 경로에 맞게 수정

;<div
  className={cn(
    'base-class px-4 py-2',
    isActive && 'bg-primary text-white',
    variant === 'outline' && 'border border-gray-300',
    disabled && 'opacity-50 cursor-not-allowed',
  )}
/>
```

---

## 조건부 클래스 패턴 (공통)

```tsx
// 불리언 조건
cn('base', condition && 'conditional-class')

// 삼항 연산자
cn('base', isActive ? 'active-class' : 'inactive-class')

// 객체 문법 (clsx)
cn('base', {
  'class-a': conditionA,
  'class-b': conditionB,
})

// 복합 조건
cn(
  'base-styles',
  variant === 'primary' && 'bg-blue-500',
  variant === 'secondary' && 'bg-gray-500',
  size === 'sm' && 'text-sm px-2',
  size === 'lg' && 'text-lg px-4',
)
```

---

## @layer utilities (공통)

```css
@layer utilities {
  .hide-scrollbar {
    -ms-overflow-style: none;
    scrollbar-width: none;
  }
  .hide-scrollbar::-webkit-scrollbar {
    display: none;
  }
}
```

---

## 반응형 패턴 (공통)

```tsx
// Mobile First
<div className="w-full md:w-1/2 lg:w-1/3" />

// 반응형 숨김/표시
<div className="hidden md:block" />  // 모바일 숨김
<div className="block md:hidden" />  // 데스크탑 숨김

// 반응형 flex/grid
<div className="flex flex-col md:flex-row gap-4" />
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4" />
```

---

## 다크모드 패턴 (공통)

```tsx
// class 기반 다크모드
<div className="bg-white dark:bg-gray-900 text-black dark:text-white" />

// 호버 + 다크모드 조합
<button className="bg-gray-100 hover:bg-gray-200 dark:bg-gray-800 dark:hover:bg-gray-700" />
```

---

## 자주 쓰는 유틸리티 조합 (공통)

```tsx
// Flex Center
<div className="flex items-center justify-center" />

// Absolute Center
<div className="absolute inset-0 flex items-center justify-center" />

// Text Ellipsis
<p className="truncate" />
<p className="line-clamp-2" />

// Transition
<div className="transition-all duration-200" />
<div className="transition-colors duration-150" />

// Focus Ring
<button className="focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" />

// Disabled State
<button className="disabled:opacity-50 disabled:cursor-not-allowed" />
```
