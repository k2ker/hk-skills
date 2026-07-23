# i18n 번역 키 패턴

next-intl 번역 키 작성 규칙 및 타입 안전성 패턴.

## 핵심 규칙

| 규칙                   | ✅ 올바름                  | ❌ 금지                     | 이유              |
| ---------------------- | -------------------------- | --------------------------- | ----------------- |
| **네임스페이스: 영어** | `useTranslations('Store')` | `useTranslations('스토어')` | 표준 관행         |
| **키: 한국어**         | `t('결제 완료')`           | `t('paymentSuccess')`       | 가독성            |
| **키에 `.` 금지**      | `t('총 결제 금액')`        | `t('payment.total')`        | 네임스페이스 충돌 |
| **키에 마침표 금지**   | `t('안녕하세요')`          | `t('안녕하세요.')`          | 문장부호는 값에만 |
| **depth: 1단계만**     | `Store.구매완료`           | `Store.purchase.success`    | 복잡도 방지       |
| **파일 3개 동시**      | ko, en, ja 모두            | 하나만 수정                 | 번역 누락 방지    |

---

## 키에 `.` 금지의 중요성

### 문제: next-intl 네임스페이스 구분자

```tsx
// ❌ 금지: 키에 . 포함
const t = useTranslations('Common');
t('User.Profile');  // next-intl이 'User' 네임스페이스의 'Profile' 키로 해석!

// messages/ko.json
{
  "Common": {
    "User.Profile": "사용자 프로필"  // ❌ 찾지 못함!
  }
}
```

**에러:**

```
Error: [next-intl] Could not resolve 'User.Profile' in 'Common' namespace.
```

---

### 해결: 키에 . 제거

```tsx
// ✅ 올바름
const t = useTranslations('Common');
t('사용자 프로필');  // 정상 작동

// messages/ko.json
{
  "Common": {
    "사용자 프로필": "사용자 프로필"  // ✅
  }
}

// messages/en.json
{
  "Common": {
    "사용자 프로필": "User Profile"
  }
}
```

---

## 다중 네임스페이스

### ❌ 잘못된 방법

```tsx
// ❌ 금지: 점으로 다른 네임스페이스 접근
const t = useTranslations('Chat')
t('Common.취소') // 에러!
t('Validation.필수항목') // 에러!
```

---

### ✅ 올바른 방법

**클라이언트 컴포넌트:**

```tsx
'use client'
import { useTranslations } from 'next-intl'

export function ChatComponent() {
  const t = useTranslations('Chat')
  const tCommon = useTranslations('Common')
  const tValidation = useTranslations('Validation')

  return (
    <div>
      <h1>{t('채팅방')}</h1>
      <button>{tCommon('취소')}</button>
      <p>{tValidation('필수 항목입니다')}</p>
    </div>
  )
}
```

---

**서버 컴포넌트:**

```tsx
import { getTranslations } from 'next-intl/server'

export default async function ChatPage() {
  const t = await getTranslations('Chat')
  const tCommon = await getTranslations('Common')

  return (
    <div>
      <h1>{t('채팅방')}</h1>
      <button>{tCommon('취소')}</button>
    </div>
  )
}
```

---

## 번역 파일 구조

### 디렉토리 구조

```
messages/
├── ko.json   # 한국어 (기준 언어)
├── en.json   # 영어
└── ja.json   # 일본어
```

---

### 파일 구조 (1 depth 권장)

```json
// messages/ko.json
{
  "Common": {
    "홈": "홈",
    "취소": "취소",
    "확인": "확인",
    "저장": "저장"
  },
  "Store": {
    "결제가 완료되었습니다": "결제가 완료되었습니다",
    "총 {count}개의 상품": "총 {count}개의 상품"
  },
  "Validation": {
    "필수 항목입니다": "필수 항목입니다",
    "올바른 이메일을 입력하세요": "올바른 이메일을 입력하세요"
  }
}
```

---

```json
// messages/en.json
{
  "Common": {
    "홈": "Home",
    "취소": "Cancel",
    "확인": "Confirm",
    "저장": "Save"
  },
  "Store": {
    "결제가 완료되었습니다": "Payment completed",
    "총 {count}개의 상품": "Total {count} items"
  },
  "Validation": {
    "필수 항목입니다": "This field is required",
    "올바른 이메일을 입력하세요": "Please enter a valid email"
  }
}
```

---

### ❌ 2 depth 이상 (비권장)

```json
// ❌ 복잡한 중첩 구조
{
  "Store": {
    "payment": {
      "success": "결제 완료",
      "failure": "결제 실패"
    }
  }
}

// 사용
const t = useTranslations('Store.payment');  // 복잡함
t('success');
```

---

## Validation 패턴

### ValidationMessages 상수

```typescript
// utils/validation.ts
export const ValidationMessages = {
  required: '필수 항목입니다',
  invalidEmail: '올바른 이메일을 입력하세요',
  invalidPhone: '올바른 전화번호를 입력하세요',
  minLength: '최소 {min}자 이상 입력하세요',
  maxLength: '최대 {max}자까지 입력 가능합니다',
} as const

// Validator에서
export const isValidEmail = (email: string) => {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}
```

---

### 폼에서 사용

```tsx
import { useTranslations } from 'next-intl'
import { isValidEmail, ValidationMessages } from '@/utils/validation'

export function LoginForm() {
  const tValidation = useTranslations('Validation')

  const form = useForm({
    defaultValues: { email: '' },
    validators: {
      onChange: ({ value }) => {
        if (!value) return tValidation(ValidationMessages.required)
        if (!isValidEmail(value)) return tValidation(ValidationMessages.invalidEmail)
        return undefined
      },
    },
  })

  return (
    <form.Field name="email">
      {(field) => (
        <Input
          value={field.state.value}
          onChange={(e) => field.handleChange(e.target.value)}
          error={field.state.meta.errors[0]}
        />
      )}
    </form.Field>
  )
}
```

---

## 변수 사용

### 기본 변수

```tsx
// 사용
const t = useTranslations('Store');
t('총 {count}개의 상품', { count: 5 });
t('{name}님 환영합니다', { name: userName });

// messages/ko.json
{
  "Store": {
    "총 {count}개의 상품": "총 {count}개의 상품",
    "{name}님 환영합니다": "{name}님 환영합니다"
  }
}

// messages/en.json
{
  "Store": {
    "총 {count}개의 상품": "Total {count} items",
    "{name}님 환영합니다": "Welcome, {name}"
  }
}
```

---

### 복수형 (ICU MessageFormat)

```tsx
// 사용
const t = useTranslations('Store');
t('아이템 개수', { count: 1 });  // "1 item"
t('아이템 개수', { count: 5 });  // "5 items"

// messages/en.json
{
  "Store": {
    "아이템 개수": "{count, plural, one {# item} other {# items}}"
  }
}

// messages/ko.json (한국어는 복수형 구분 없음)
{
  "Store": {
    "아이템 개수": "{count}개"
  }
}
```

---

## 타입 안전성

### 타입 정의

```typescript
// types/i18n.d.ts
type Messages = typeof import('../messages/ko.json')

declare global {
  interface IntlMessages extends Messages {}
}
```

**장점:**

- TypeScript가 번역 키 자동완성
- 존재하지 않는 키 사용 시 컴파일 에러

---

### 타입 안전 사용

```tsx
import { useTranslations } from 'next-intl'

const t = useTranslations('Store')

// ✅ 자동완성 지원
t('결제가 완료되었습니다') // IDE가 키 제안

// ❌ 존재하지 않는 키 → 컴파일 에러
t('없는키') // TypeScript error
```

---

## 네임스페이스 구성

### 권장 네임스페이스

| 네임스페이스 | 용도           | 예시 키                                     |
| ------------ | -------------- | ------------------------------------------- |
| `Common`     | 공통 UI 요소   | 홈, 취소, 확인, 저장, 삭제                  |
| `Validation` | 폼 유효성 검사 | 필수 항목입니다, 올바른 이메일을 입력하세요 |
| `Error`      | 에러 메시지    | 오류가 발생했습니다, 다시 시도해주세요      |
| `{PageName}` | 페이지별 번역  | Store, Chat, Profile 등                     |

---

### 네임스페이스 분리 예시

```json
// messages/ko.json
{
  "Common": {
    "홈": "홈",
    "취소": "취소",
    "확인": "확인"
  },
  "Validation": {
    "필수 항목입니다": "필수 항목입니다",
    "올바른 이메일을 입력하세요": "올바른 이메일을 입력하세요"
  },
  "Error": {
    "오류가 발생했습니다": "오류가 발생했습니다",
    "다시 시도해주세요": "다시 시도해주세요"
  },
  "Store": {
    "결제가 완료되었습니다": "결제가 완료되었습니다",
    "장바구니": "장바구니"
  },
  "Chat": {
    "메시지를 입력하세요": "메시지를 입력하세요",
    "채팅방": "채팅방"
  }
}
```

---

## 번역 추가 워크플로우

### Step 1: 코드에서 번역 키 추가

```tsx
// components/PaymentSuccess.tsx
const t = useTranslations('Store')

return <p>{t('결제가 완료되었습니다')}</p>
```

---

### Step 2: ko.json에 키 추가

```json
// messages/ko.json
{
  "Store": {
    "결제가 완료되었습니다": "결제가 완료되었습니다"
  }
}
```

---

### Step 3: en.json, ja.json에 번역 추가

```json
// messages/en.json
{
  "Store": {
    "결제가 완료되었습니다": "Payment completed"
  }
}

// messages/ja.json
{
  "Store": {
    "결제가 완료되었습니다": "お支払いが完了しました"
  }
}
```

---

### Step 4: 검증

```bash
# 번역 누락 확인
npm run i18n:check

# 빌드 테스트
npm run build
```

**i18n:check 결과 해석:**

| 항목               | 조치                          |
| ------------------ | ----------------------------- |
| **undefined keys** | ❌ 반드시 수정 (번역 키 누락) |
| **unused keys**    | ⚠️ 무시 (동적 사용 감지 못함) |

---

## 실전 예시

### 페이지 컴포넌트

```tsx
// app/[locale]/store/page.tsx
import { getTranslations } from 'next-intl/server'

export default async function StorePage() {
  const t = await getTranslations('Store')
  const tCommon = await getTranslations('Common')

  return (
    <div>
      <h1>{t('상점')}</h1>
      <button>{tCommon('확인')}</button>
    </div>
  )
}
```

---

### 클라이언트 컴포넌트 (여러 네임스페이스)

```tsx
'use client'
import { useTranslations } from 'next-intl'

export function ChatInput() {
  const t = useTranslations('Chat')
  const tCommon = useTranslations('Common')
  const tValidation = useTranslations('Validation')

  return (
    <div>
      <input placeholder={t('메시지를 입력하세요')} />
      <button>{tCommon('전송')}</button>
      {error && <p>{tValidation('필수 항목입니다')}</p>}
    </div>
  )
}
```

---

### 폼 유효성 검사

```tsx
import { useTranslations } from 'next-intl'
import { ValidationMessages } from '@/utils/validation'

export function SignupForm() {
  const tValidation = useTranslations('Validation')

  const form = useForm({
    defaultValues: {
      email: '',
      password: '',
    },
    validators: {
      onChange: ({ value }) => {
        if (!value.email) {
          return {
            email: tValidation(ValidationMessages.required),
          }
        }
        if (!isValidEmail(value.email)) {
          return {
            email: tValidation(ValidationMessages.invalidEmail),
          }
        }
        if (value.password.length < 8) {
          return {
            password: tValidation(ValidationMessages.minLength, { min: 8 }),
          }
        }
        return undefined
      },
    },
  })

  // ...
}
```

---

## 체크리스트

번역 추가 시 확인:

- [ ] 네임스페이스는 영어 (Common, Store 등)
- [ ] 키는 한국어 문장
- [ ] 키에 `.` 문자 없음
- [ ] 키에 마침표(`.`) 없음 (값에만 사용)
- [ ] ko.json, en.json, ja.json 3개 모두 업데이트
- [ ] `npm run i18n:check` 실행
- [ ] undefined keys 없음
- [ ] 빌드 성공

---

## 자동 검증

### i18n:check 스크립트

```bash
npm run i18n:check
```

**출력 예시:**

```
✅ All translation keys are defined

⚠️ Unused keys (safe to ignore):
  - Common.동적으로사용됨
  - Store.템플릿에서사용됨
```

**참고:** unused keys는 동적 사용을 감지 못하는 false positive. 삭제하지 마세요!

---

### ESLint 규칙

```typescript
// eslint.config.mjs (자동 감지)
{
  rules: {
    'no-restricted-syntax': [
      'error',
      {
        selector: 'CallExpression[callee.name=/^t$|^tCommon$|^tValidation$/] > Literal[value=/\\./]',
        message: '번역 키에 점(.)을 사용하지 마세요. next-intl 네임스페이스 구분자입니다.',
      },
    ],
  },
}
```

**감지 패턴:**

```tsx
t('Common.취소') // ❌ ESLint 에러
tCommon('User.Profile') // ❌ ESLint 에러
```

---

## 고급 패턴

### Rich Text (HTML 포함)

```tsx
const t = useTranslations('Store');

// messages/ko.json
{
  "Store": {
    "이용약관 동의": "저는 <link>이용약관</link>에 동의합니다"
  }
}

// 사용
t.rich('이용약관 동의', {
  link: (chunks) => <Link href="/terms">{chunks}</Link>,
});
```

---

### 날짜/시간 포맷

```tsx
import { useFormatter } from 'next-intl'

export function DateDisplay({ date }: { date: Date }) {
  const format = useFormatter()

  return (
    <div>
      <p>{format.dateTime(date, { dateStyle: 'long' })}</p>
      <p>{format.relativeTime(date)}</p>
    </div>
  )
}
```

---

### 숫자 포맷

```tsx
import { useFormatter } from 'next-intl'

export function PriceDisplay({ price }: { price: number }) {
  const format = useFormatter()

  return (
    <div>
      {format.number(price, {
        style: 'currency',
        currency: 'KRW',
      })}
    </div>
  )
}
```

---

## 결론

**핵심 규칙:**

- 네임스페이스: 영어
- 키: 한국어
- 키에 `.` 금지 (네임스페이스 구분자)
- 파일 3개 동시 수정

**검증:**

- npm run i18n:check
- ESLint (자동 감지)
- 빌드 테스트

**타입 안전성:**

- IntlMessages 인터페이스
- 자동완성 + 컴파일 체크
