# i18n 라우팅 패턴

Next.js + next-intl을 사용한 국제화 라우팅 패턴.

## 핵심 규칙

**절대 금지:**

- ❌ `import Link from 'next/link'`
- ❌ `import { useRouter } from 'next/navigation'`
- ❌ `import { usePathname } from 'next/navigation'`

**반드시 사용:**

- ✅ `import { Link } from '@/i18n/navigation'`
- ✅ `import { useRouter } from '@/i18n/navigation'`
- ✅ `import { usePathname } from '@/i18n/navigation'`

**이유:** next/link와 next/navigation은 locale 정보를 유실시킵니다. 항상 `@/i18n/navigation`에서 import해야 locale이 보존됩니다.

---

## next-intl 설정

### i18n/navigation.ts 구현

```typescript
// i18n/navigation.ts
import { createSharedPathnamesNavigation } from 'next-intl/navigation'

export const locales = ['ko', 'en', 'ja'] as const
export const defaultLocale = 'ko' as const

export const { Link, useRouter, usePathname, redirect } = createSharedPathnamesNavigation({
  locales,
})
```

**설명:**

- `createSharedPathnamesNavigation`: 모든 locale에서 동일한 경로 사용
- `locales`: 지원하는 언어 목록
- `defaultLocale`: 기본 언어
- Export: Link, useRouter, usePathname, redirect (locale-aware)

---

### i18n/request.ts (Server Component용)

```typescript
// i18n/request.ts
import { getRequestConfig } from 'next-intl/server'
import { notFound } from 'next/navigation'

export const locales = ['ko', 'en', 'ja']

export default getRequestConfig(async ({ locale }) => {
  // locale 검증
  if (!locales.includes(locale as any)) notFound()

  return {
    messages: (await import(`../../messages/${locale}.json`)).default,
  }
})
```

---

### next.config.ts 설정

```typescript
// next.config.ts
import createNextIntlPlugin from 'next-intl/plugin'

const withNextIntl = createNextIntlPlugin('./i18n/request.ts')

const nextConfig = {
  // 기타 설정...
}

export default withNextIntl(nextConfig)
```

---

## middleware vs proxy.ts

### ❌ 기존 방식 (middleware.ts - Deprecated)

```typescript
// middleware.ts (Next.js 16에서 deprecated)
import createMiddleware from 'next-intl/middleware'

export default createMiddleware({
  locales: ['ko', 'en', 'ja'],
  defaultLocale: 'ko',
})

export const config = {
  matcher: ['/((?!api|_next|.*\\..*).*)'],
}
```

**문제점:** Next.js 16에서 middleware.ts가 deprecated되었습니다.

---

### ✅ 권장 방식 (proxy.ts)

```typescript
// proxy.ts
import { NextRequest } from 'next/server'
import createMiddleware from 'next-intl/middleware'

const intl = createMiddleware({
  locales: ['ko', 'en', 'ja'],
  defaultLocale: 'ko',
  localePrefix: 'always', // URL에 항상 locale 포함
})

export function proxy(request: NextRequest) {
  const response = intl(request)

  // locale 쿠키 설정 (선택적)
  const locale = request.nextUrl.pathname.split('/')[1]
  if (['ko', 'en', 'ja'].includes(locale)) {
    response.cookies.set('NEXT_LOCALE', locale, {
      path: '/',
      maxAge: 60 * 60 * 24 * 365, // 1년
    })
  }

  return response
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
}
```

**장점:**

- Next.js 16 호환
- 커스텀 로직 추가 가능 (쿠키, 헤더 등)
- next-intl과 완벽 통합

---

## Link 컴포넌트

### 기본 사용법

```tsx
import { Link } from '@/i18n/navigation'

function Navigation() {
  return (
    <nav>
      {/* ✅ 자동으로 locale 포함: /ko/about, /en/about */}
      <Link href="/about">About</Link>

      {/* ✅ Dynamic route */}
      <Link href={`/users/${userId}`}>User Profile</Link>

      {/* ✅ Query parameters */}
      <Link href={{ pathname: '/search', query: { q: 'next.js' } }}>Search</Link>
    </nav>
  )
}
```

---

### 외부 링크 처리

```tsx
import { Link } from '@/i18n/navigation'

function Footer() {
  return (
    <>
      {/* ✅ 내부 링크: i18n Link */}
      <Link href="/privacy">Privacy Policy</Link>

      {/* ✅ 외부 링크: 일반 <a> 태그 */}
      <a href="https://example.com" target="_blank" rel="noopener">
        External Link
      </a>
    </>
  )
}
```

---

### 활성 링크 스타일

```tsx
import { Link, usePathname } from '@/i18n/navigation'

function Navigation() {
  const pathname = usePathname()

  const links = [
    { href: '/dashboard', label: 'Dashboard' },
    { href: '/settings', label: 'Settings' },
  ]

  return (
    <nav>
      {links.map((link) => {
        const isActive = pathname === link.href

        return (
          <Link key={link.href} href={link.href} className={isActive ? 'active' : ''}>
            {link.label}
          </Link>
        )
      })}
    </nav>
  )
}
```

---

## useRouter 훅

### 기본 네비게이션

```tsx
import { useRouter } from '@/i18n/navigation'

function NavigationButtons() {
  const router = useRouter()

  return (
    <>
      {/* ✅ push: 새 항목 추가 (뒤로가기 가능) */}
      <button onClick={() => router.push('/dashboard')}>Go to Dashboard</button>

      {/* ✅ replace: 현재 항목 교체 (뒤로가기 불가) */}
      <button onClick={() => router.replace('/home')}>Replace with Home</button>

      {/* ✅ back: 이전 페이지 */}
      <button onClick={() => router.back()}>Go Back</button>
    </>
  )
}
```

---

### 프로그래밍 방식 네비게이션

```tsx
import { useRouter } from '@/i18n/navigation'

function LoginForm() {
  const router = useRouter()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    const success = await login()

    if (success) {
      // ✅ 로그인 성공 → 대시보드로 이동
      router.push('/dashboard')
    }
  }

  return <form onSubmit={handleSubmit}>{/* ... */}</form>
}
```

---

### locale 전환

```tsx
import { useRouter, usePathname } from '@/i18n/navigation'
import { useLocale } from 'next-intl'

function LanguageSwitcher() {
  const router = useRouter()
  const pathname = usePathname()
  const currentLocale = useLocale()

  const handleLocaleChange = (newLocale: string) => {
    // ✅ 같은 경로, 다른 locale로 이동
    router.replace(pathname, { locale: newLocale })
  }

  return (
    <div>
      <button onClick={() => handleLocaleChange('ko')} disabled={currentLocale === 'ko'}>
        한국어
      </button>
      <button onClick={() => handleLocaleChange('en')} disabled={currentLocale === 'en'}>
        English
      </button>
      <button onClick={() => handleLocaleChange('ja')} disabled={currentLocale === 'ja'}>
        日本語
      </button>
    </div>
  )
}
```

---

## usePathname 훅

### 현재 경로 확인

```tsx
import { usePathname } from '@/i18n/navigation'

function Breadcrumb() {
  const pathname = usePathname()

  // pathname = '/dashboard/settings' (locale 제외된 경로)

  const segments = pathname.split('/').filter(Boolean)

  return (
    <nav>
      <Link href="/">Home</Link>
      {segments.map((segment, index) => {
        const href = '/' + segments.slice(0, index + 1).join('/')
        return (
          <span key={href}>
            {' > '}
            <Link href={href}>{segment}</Link>
          </span>
        )
      })}
    </nav>
  )
}
```

---

## 실전 예시

### 네비게이션 바

```tsx
// components/Navbar.tsx
import { Link, usePathname } from '@/i18n/navigation'
import { useTranslations } from 'next-intl'

export default function Navbar() {
  const t = useTranslations('Navigation')
  const pathname = usePathname()

  const links = [
    { href: '/', label: t('home') },
    { href: '/dashboard', label: t('dashboard') },
    { href: '/settings', label: t('settings') },
  ]

  return (
    <nav className="flex gap-4">
      {links.map((link) => {
        const isActive = pathname === link.href

        return (
          <Link
            key={link.href}
            href={link.href}
            className={`px-4 py-2 rounded ${
              isActive ? 'bg-blue-500 text-white' : 'bg-gray-200 text-gray-700'
            }`}
          >
            {link.label}
          </Link>
        )
      })}
    </nav>
  )
}
```

---

### 언어 선택기 (드롭다운)

```tsx
// components/LanguageSwitcher.tsx
import { useRouter, usePathname } from '@/i18n/navigation'
import { useLocale, useTranslations } from 'next-intl'

export default function LanguageSwitcher() {
  const router = useRouter()
  const pathname = usePathname()
  const currentLocale = useLocale()
  const t = useTranslations('Common')

  const languages = [
    { code: 'ko', name: '한국어', flag: '🇰🇷' },
    { code: 'en', name: 'English', flag: '🇺🇸' },
    { code: 'ja', name: '日本語', flag: '🇯🇵' },
  ]

  const handleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const newLocale = e.target.value
    router.replace(pathname, { locale: newLocale })
  }

  return (
    <select value={currentLocale} onChange={handleChange} className="px-3 py-2 border rounded">
      {languages.map((lang) => (
        <option key={lang.code} value={lang.code}>
          {lang.flag} {lang.name}
        </option>
      ))}
    </select>
  )
}
```

---

## 체크리스트

i18n 라우팅 작업 시 확인:

- [ ] `@/i18n/navigation`에서 Link, useRouter, usePathname import
- [ ] next/link, next/navigation에서 절대 import 안함
- [ ] proxy.ts 설정 완료 (middleware.ts 사용 안함)
- [ ] i18n/navigation.ts에 locales 정의
- [ ] 모든 내부 링크를 i18n Link로 교체
- [ ] 언어 전환 기능 구현 (router.replace + locale)
