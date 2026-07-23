# Component Patterns

이 문서는 프로젝트의 기존 UI 컴포넌트와 사용 패턴을 정리합니다.
**새로 만들기 전에 반드시 기존 컴포넌트 재사용 여부를 확인하세요.**

---

## 공통 패턴

### 1. tailwind-variants 사용

모든 UI 컴포넌트는 `tailwind-variants` 패키지를 사용하여 variants를 정의합니다.

```tsx
// ComponentName.variants.ts
import { tv } from 'tailwind-variants';

export const componentVariants = tv({
  base: [...],
  variants: {
    variant: { ... },
    size: { ... },
  },
  defaultVariants: { ... },
});
```

### 2. cn() 유틸리티

클래스 병합시 항상 `cn()` 유틸리티를 사용합니다:

```tsx
import { cn } from '@/utils/cn'

;<div className={cn(styles.base(), className)} />
```

### 3. 컴포넌트 구조

```
src/components/ui/{component-name}/
├── {ComponentName}.tsx          # 메인 컴포넌트
├── {ComponentName}.variants.ts  # tailwind-variants 설정
└── {ComponentName}.stories.tsx  # Storybook 문서
```

---

## Button

**위치:** `src/components/ui/button/Button.tsx`

### Props

```tsx
interface ButtonProps<T extends ElementType = 'button'> {
  as?: T // 렌더링할 컴포넌트/요소 (기본: 'button')
  variant?: 'primary' | 'error' | 'tertiary' | 'stroke'
  size?: 'small' | 'medium' | 'large'
  fullWidth?: boolean
  isLoading?: boolean
  disabled?: boolean
  children: React.ReactNode
  className?: string
  // ...렌더링되는 요소의 HTML attributes
}
```

### `as` Prop (Polymorphic Component)

Button은 `as` prop을 통해 다른 요소나 컴포넌트로 렌더링할 수 있습니다:

```tsx
import Button from '@/components/ui/button/Button';
import { Link } from '@/i18n/navigation';

// 기본: <button> 요소
<Button>클릭</Button>

// Link로 렌더링 (네비게이션)
<Button as={Link} href="/creator/new">
  새로 만들기
</Button>

// <a> 요소로 렌더링 (외부 링크)
<Button as="a" href="https://example.com" target="_blank">
  외부 링크
</Button>
```

> ⚠️ **주의:** `as` prop 사용 시 해당 요소의 속성도 함께 전달 가능 (예: `href`, `target`)

### Variants 상세

| Variant    | 배경색                          | 용도               |
| ---------- | ------------------------------- | ------------------ |
| `primary`  | `bg-primary-40`                 | 주요 액션 (기본값) |
| `error`    | `bg-red-20`                     | 삭제, 위험한 액션  |
| `tertiary` | `bg-gray-15`                    | 보조 액션          |
| `stroke`   | `border-gray-40 bg-transparent` | 외곽선 버튼        |

| Size     | 높이 | 패딩          | 폰트          |
| -------- | ---- | ------------- | ------------- |
| `small`  | 32px | `px-3 py-1.5` | `font-12b-20` |
| `medium` | 48px | `px-4 py-3`   | `font-14b-22` |
| `large`  | 56px | `px-5 py-4`   | `font-16b-24` |

### 사용 예시

```tsx
import Button from '@/components/ui/button/Button';

// 기본 primary 버튼
<Button>확인</Button>

// 크기 및 variant 지정
<Button variant="tertiary" size="small">취소</Button>

// 전체 너비
<Button fullWidth>로그인</Button>

// 에러 버튼
<Button variant="error">삭제</Button>

// 외곽선 버튼
<Button variant="stroke">더보기</Button>
```

---

## IconButton

**위치:** `src/components/ui/iconButton/IconButton.tsx`

### Props

```tsx
interface IconButtonProps {
  icon: React.ReactNode
  size?: 'sm' | 'md' | 'lg'
  shape?: 'circle' | 'square'
  className?: string
  // ...기타 button HTML attributes
}
```

### Variants 상세

| Size | 크기    |
| ---- | ------- |
| `sm` | 44x44px |
| `md` | 48x48px |
| `lg` | 52x52px |

| Shape    | 스타일         |
| -------- | -------------- |
| `circle` | `rounded-full` |
| `square` | `rounded-md`   |

### 사용 예시

```tsx
import IconButton from '@/components/ui/iconButton/IconButton'
import CloseIcon from '@/assets/icons/close.svg'

;<IconButton icon={<CloseIcon />} size="md" shape="circle" />
```

---

## Modal

**위치:** `src/components/ui/modal/Modal.tsx`

### Props

```tsx
interface ModalProps {
  open: boolean
  onClose: () => void
  closeOnOutside?: boolean // 기본값: true
  children: React.ReactNode
  className?: string
}
```

### 특징

- Portal: `#modal-root`에 렌더링
- 애니메이션: Framer Motion (fade + scale)
- 배경: `bg-black/70`
- 컨텐츠 배경: `bg-gray-30 rounded-[20px]`

### 사용 예시

```tsx
import Modal from '@/components/ui/modal/Modal'

;<Modal open={isOpen} onClose={() => setIsOpen(false)}>
  <div className="p-6">
    <h2 className="font-20b-32 text-text-default">제목</h2>
    <p className="font-14r-22 text-text-sub mt-2">내용</p>
    <div className="mt-6 flex gap-2">
      <Button variant="tertiary" onClick={() => setIsOpen(false)}>
        취소
      </Button>
      <Button>확인</Button>
    </div>
  </div>
</Modal>
```

---

## SideModal

**위치:** `src/components/ui/sideModal/SideModal.tsx`

### Props

```tsx
interface SideModalProps {
  open: boolean
  onClose: () => void
  closeOnOutside?: boolean // 기본값: true
  side: 'left' | 'right'
  className?: string
  children: React.ReactNode
}
```

### 특징

- Portal: `#side-modal-root`에 렌더링
- 애니메이션: 슬라이드 (좌/우)
- 배경: `bg-neutral-900`

### 사용 예시

```tsx
import SideModal from '@/components/ui/sideModal/SideModal'

;<SideModal open={isOpen} onClose={() => setIsOpen(false)} side="right" className="w-[400px]">
  <div className="p-6">사이드 패널 내용</div>
</SideModal>
```

---

## Slider

**위치:** `src/components/ui/slider/Slider.tsx`

### Props

```tsx
interface SliderProps {
  value?: number[]
  defaultValue?: number[]
  min?: number // 기본값: 0
  max?: number // 기본값: 100
  size?: 'sm' | 'md' | 'lg'
  onValueChange?: (value: number[]) => void
  className?: string
}
```

### 특징

- 기반: `@radix-ui/react-slider`
- 트랙: `bg-gray-30`
- 활성 범위: `bg-primary-40`
- 썸: `bg-primary-40`

### Variants 상세

| Size | 트랙 높이 | 썸 크기 |
| ---- | --------- | ------- |
| `sm` | 4px       | 12px    |
| `md` | 6px       | 16px    |
| `lg` | 8px       | 20px    |

### 사용 예시

```tsx
import Slider from '@/components/ui/slider/Slider';

// 단일 값
<Slider
  value={[volume]}
  onValueChange={([val]) => setVolume(val)}
  min={0}
  max={100}
/>

// 범위
<Slider
  value={[min, max]}
  onValueChange={([newMin, newMax]) => { ... }}
/>
```

---

## Switch

**위치:** `src/components/ui/switch/Switch.tsx`

### Props

```tsx
interface SwitchProps {
  checked?: boolean
  onCheckedChange?: (checked: boolean) => void
  disabled?: boolean
  className?: string
}
```

### 특징

- 커스텀 체크박스 기반
- 트랙: 48x28px, `rounded-[14px]`
- 활성: `bg-primary-40`, 비활성: `bg-gray-30`
- 썸: 24x24px, 흰색

### 사용 예시

```tsx
import Switch from '@/components/ui/switch/Switch';

<Switch
  checked={isEnabled}
  onCheckedChange={setIsEnabled}
/>

// 비활성화
<Switch checked={true} disabled />
```

---

## Textarea

**위치:** `src/components/ui/textarea/Textarea.tsx`

### Props

```tsx
interface TextareaProps {
  value?: string
  onChange?: (e: ChangeEvent<HTMLTextAreaElement>) => void
  autoHeight?: boolean // 기본값: false
  minHeight?: number // 기본값: 120
  error?: boolean | string // 에러 상태 또는 메시지
  maxLength?: number // 기본값: 250
  showCounter?: boolean // 기본값: true
  rightSlot?: ReactNode // 오른쪽 커스텀 영역
  className?: string
  disabled?: boolean
}
```

### 특징

- 기본 높이: 120px
- 배경: `bg-gray-20`
- 보더: `border-white-t10`, hover시 `border-white-t30`
- 에러: `border-red-20`

### 사용 예시

```tsx
import Textarea from '@/components/ui/textarea/Textarea';

<Textarea
  value={text}
  onChange={(e) => setText(e.target.value)}
  placeholder="메시지를 입력하세요"
  maxLength={500}
/>

// 에러 상태
<Textarea
  value={text}
  error="최대 글자수를 초과했습니다"
/>

// 자동 높이
<Textarea
  value={text}
  autoHeight
  minHeight={80}
/>
```

---

## Radio / RadioGroup

**위치:** `src/components/ui/radio/Radio.tsx`

### Props

```tsx
// RadioGroup
interface RadioGroupProps {
  value?: string
  defaultValue?: string
  onValueChange?: (value: string) => void
  disabled?: boolean
  className?: string
  children: React.ReactNode
}

// Radio
interface RadioProps {
  value: string
  id?: string
  disabled?: boolean
  className?: string
  labelClassName?: string
  children?: React.ReactNode
}
```

### 특징

- 커스텀 스타일 라디오
- 원형 인디케이터: 18x18px
- 선택시: `border-primary-40`, 내부 점 `bg-primary-40`

### 사용 예시

```tsx
import { RadioGroup, Radio } from '@/components/ui/radio/Radio'

;<RadioGroup value={selected} onValueChange={setSelected}>
  <Radio value="option1">옵션 1</Radio>
  <Radio value="option2">옵션 2</Radio>
  <Radio value="option3" disabled>
    옵션 3 (비활성)
  </Radio>
</RadioGroup>
```

---

## Tooltip

**위치:** `src/components/ui/tooltip/Tooltip.tsx`

### 컴포넌트

- `Tooltip` - 루트 래퍼
- `TooltipTrigger` - 트리거 요소
- `TooltipContent` - 툴팁 내용

### Props (TooltipContent)

```tsx
interface TooltipContentProps {
  sideOffset?: number // 기본값: 4
  className?: string
  children: React.ReactNode
}
```

### 특징

- 기반: `@radix-ui/react-tooltip`
- 배경: `bg-gray-30`
- 보더: `border-white-t10`
- 애니메이션: fade + zoom

### 사용 예시

```tsx
import { Tooltip, TooltipTrigger, TooltipContent } from '@/components/ui/tooltip/Tooltip'

;<Tooltip>
  <TooltipTrigger>
    <button>?</button>
  </TooltipTrigger>
  <TooltipContent>도움말 내용입니다</TooltipContent>
</Tooltip>
```

---

## Toast

**위치:** `src/components/ui/toast/Toast.tsx`

### Props

```tsx
interface ToastProps {
  message: string
  duration?: number // 기본값: 3000ms
  onClose?: () => void
}
```

### 특징

- Portal: `document.body`에 렌더링
- 위치: 상단 중앙
- 배경: `bg-black-t75`
- 애니메이션: 위에서 슬라이드

### 사용 예시

```tsx
import Toast from '@/components/ui/toast/Toast'

{
  showToast && <Toast message="저장되었습니다" onClose={() => setShowToast(false)} />
}
```

---

## Tabs

**위치:** `src/components/ui/tabs/Tabs.tsx`

### 컴포넌트

- `Tabs` - 루트 래퍼
- `TabsList` - 탭 목록 컨테이너
- `TabsTrigger` - 탭 버튼
- `TabsContent` - 탭 내용

### 특징

- 기반: `@radix-ui/react-tabs`
- 비활성: `text-gray-50`, 하단 라인 `bg-gray-30`
- 활성: `text-common-100`, 하단 라인 `bg-primary-40`

### 사용 예시

```tsx
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs/Tabs'

;<Tabs defaultValue="tab1">
  <TabsList>
    <TabsTrigger value="tab1">탭 1</TabsTrigger>
    <TabsTrigger value="tab2">탭 2</TabsTrigger>
  </TabsList>
  <TabsContent value="tab1">탭 1 내용</TabsContent>
  <TabsContent value="tab2">탭 2 내용</TabsContent>
</Tabs>
```

---

## Checkbox

**위치:** `src/components/ui/checkbox/Checkbox.tsx`

### Props

```tsx
interface CheckboxProps {
  checked: boolean
  onChange: (checked: boolean) => void
  label?: string
  size?: 'small' | 'medium'
  labelClassName?: string
  disabled?: boolean
  className?: string
}
```

### Variants 상세

| Size     | 체크박스 크기 | 아이콘 크기 |
| -------- | ------------- | ----------- |
| `small`  | 20x20px       | 24px        |
| `medium` | 24x24px       | 32px        |

### 특징

- 비활성: `border-common-100 bg-transparent`
- 활성: `bg-primary-50` + 체크 아이콘
- 라벨: 비활성시 `text-gray-60`, 활성시 `text-common-100`

### 사용 예시

```tsx
import Checkbox from '@/components/ui/checkbox/Checkbox';

<Checkbox
  checked={isChecked}
  onChange={setIsChecked}
  label="동의합니다"
/>

// 라벨 없이
<Checkbox checked={isChecked} onChange={setIsChecked} />
```

---

## CircularProgress

**위치:** `src/components/ui/circularProgress/CircularProgress.tsx`

### Props

```tsx
interface CircularProgressProps {
  value?: number // 0-100
  size?: 'sm' | 'md' | 'lg' | 'xl'
  color?: 'primary'
  strokeWidth?: number // 기본값: 8
  children?: React.ReactNode
}
```

### Variants 상세

| Size | 크기  |
| ---- | ----- |
| `sm` | 64px  |
| `md` | 96px  |
| `lg` | 128px |
| `xl` | 160px |

### 사용 예시

```tsx
import CircularProgress from '@/components/ui/circularProgress/CircularProgress'

;<CircularProgress value={75} size="lg">
  <span className="font-20b-32 text-primary-40">75%</span>
</CircularProgress>
```

---

## 레이아웃 패턴

### Flex 레이아웃

```tsx
// 수평 정렬, 간격 2 (8px)
<div className="flex items-center gap-2">

// 수직 정렬
<div className="flex flex-col gap-4">

// space-between
<div className="flex items-center justify-between">
```

### Grid 레이아웃

```tsx
// 2열 그리드
<div className="grid grid-cols-2 gap-4">

// 반응형
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
```

### 스크롤 영역

```tsx
// 세로 스크롤 (스크롤바 숨김)
<div className="overflow-y-auto hide-scrollbar">
```

---

## 주의사항

1. **기존 컴포넌트 우선 사용**
   - Figma에서 버튼이 보이면 → `Button` 컴포넌트 사용
   - 슬라이더가 보이면 → `Slider` 컴포넌트 사용
   - 비슷한 UI가 있으면 새로 만들지 말고 기존 것 활용

2. **Props 활용**
   - 스타일을 직접 변경하지 말고 variant/size props 사용
   - 추가 스타일은 `className` prop으로 전달

3. **일관성 유지**
   - 동일한 UI 패턴은 동일한 컴포넌트 사용
   - 새 컴포넌트 필요시 기존 패턴(variants 파일 분리 등) 따르기
