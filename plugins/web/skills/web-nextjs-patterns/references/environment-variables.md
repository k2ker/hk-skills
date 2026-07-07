# 환경변수 설정 패턴

Next.js 환경변수 설정 및 API Route 접근 방법.

## 핵심 규칙

**API Route에서 환경변수 사용 시:**

- ❌ `.env`에만 정의 → 접근 불가 (undefined)
- ✅ `next.config.ts` env 객체에 추가 → 접근 가능

**이유:** Next.js는 빌드 타임에 환경변수를 주입합니다. API Route (특히 Amplify Lambda)는 `next.config.ts`의 env 객체에 정의된 변수만 접근 가능합니다.

---

## next.config.ts env 객체

### 필수 설정

```typescript
// next.config.ts
const nextConfig = {
  env: {
    // ⚠️ API Route에서 사용할 변수는 반드시 여기 등록!
    API_BASE_URL: process.env.API_BASE_URL,
    ANALYTICS_ID: process.env.ANALYTICS_ID,
    DATABASE_URL: process.env.DATABASE_URL,
    JWT_SECRET: process.env.JWT_SECRET,
  },
}

export default nextConfig
```

**중요:**

- `env` 객체에 등록 = 빌드 타임에 주입
- 등록 안함 = API Route에서 `undefined`

---

### 타입 안전성

```typescript
// env.d.ts
declare namespace NodeJS {
  interface ProcessEnv {
    API_BASE_URL: string
    ANALYTICS_ID: string
    DATABASE_URL: string
    JWT_SECRET: string

    // 클라이언트 노출 변수
    NEXT_PUBLIC_API_URL: string
    NEXT_PUBLIC_GA_ID: string
  }
}
```

**장점:** TypeScript 자동완성 + 타입 체크.

---

## .env 파일 구조

### 파일 우선순위

```
.env.local          # 1순위: 로컬 개발 (gitignore)
.env.development    # 2순위: 개발 환경
.env.production     # 3순위: 프로덕션 환경
.env                # 4순위: 기본값
```

---

### .env.local (로컬 개발용)

```bash
# .env.local (gitignore 필수!)
API_BASE_URL=http://localhost:3001
DATABASE_URL=postgresql://localhost:5432/dev
JWT_SECRET=local-dev-secret-key

NEXT_PUBLIC_API_URL=http://localhost:3000/api
```

**주의:** 민감한 정보 포함, Git에 커밋 금지!

---

### .env.production (프로덕션)

```bash
# .env.production
API_BASE_URL=https://api.prod.example.com
DATABASE_URL=${DATABASE_URL}  # 배포 환경에서 주입
JWT_SECRET=${JWT_SECRET}      # 배포 환경에서 주입

NEXT_PUBLIC_API_URL=https://example.com/api
```

**참고:** 배포 플랫폼 (Vercel, Amplify)에서 환경변수 설정 필요.

---

## API Route에서 사용

### 서버 전용 변수

```typescript
// app/api/users/route.ts
export async function GET() {
  // ✅ next.config.ts env에 등록된 변수
  const apiUrl = process.env.API_BASE_URL
  const jwtSecret = process.env.JWT_SECRET

  const response = await fetch(`${apiUrl}/users`, {
    headers: {
      Authorization: `Bearer ${generateToken(jwtSecret)}`,
    },
  })

  return Response.json(await response.json())
}
```

**규칙:**

- `NEXT_PUBLIC_` 접두사 없음
- 클라이언트에 노출 안됨
- API Route, Server Component만 접근 가능

---

### 클라이언트 노출 변수

```typescript
// app/api/analytics/route.ts
export async function POST(request: Request) {
  const { event } = await request.json()

  // ✅ 클라이언트 노출 변수
  const analyticsId = process.env.ANALYTICS_ID

  await sendToAnalytics(event, analyticsId)

  return Response.json({ success: true })
}
```

---

### ❌ 흔한 실수

```typescript
// app/api/data/route.ts
export async function GET() {
  // ❌ next.config.ts env에 없음 → undefined
  const newKey = process.env.NEW_KEY

  console.log(newKey) // undefined

  // ...
}
```

**해결:**

```typescript
// next.config.ts에 추가
const nextConfig = {
  env: {
    NEW_KEY: process.env.NEW_KEY, // 이제 API Route에서 접근 가능
  },
}
```

---

## 클라이언트에서 사용

### NEXT*PUBLIC* 접두사

```tsx
// components/Analytics.tsx
'use client'

export function Analytics() {
  // ✅ 클라이언트에서 접근 가능
  const gaId = process.env.NEXT_PUBLIC_GA_ID

  useEffect(() => {
    // Google Analytics 초기화
    window.gtag('config', gaId)
  }, [gaId])

  return null
}
```

**규칙:**

- `NEXT_PUBLIC_` 접두사 필수
- 빌드 시 클라이언트 번들에 포함
- 브라우저에서 접근 가능

---

### ⚠️ 주의사항

```tsx
// ❌ 민감한 정보는 NEXT_PUBLIC_ 사용 금지!
const jwt = process.env.NEXT_PUBLIC_JWT_SECRET // 브라우저에 노출!

// ✅ 민감한 정보는 서버 전용
// app/api/auth/route.ts
const jwt = process.env.JWT_SECRET // 안전
```

---

## 체크리스트

환경변수 추가 시 확인:

- [ ] `.env.local`에 변수 정의
- [ ] `next.config.ts` env 객체에 추가 (API Route 사용 시)
- [ ] `env.d.ts`에 타입 정의
- [ ] `NEXT_PUBLIC_` 접두사 확인 (클라이언트 노출 여부)
- [ ] 민감한 정보는 서버 전용으로 유지
- [ ] 빌드 후 테스트 (`npm run build && npm start`)

---

## 실전 예시

### API 클라이언트 설정

```typescript
// lib/api-client.ts
import axios from 'axios'

// ✅ 서버: next.config.ts env에서
// ✅ 클라이언트: NEXT_PUBLIC_
const baseURL =
  typeof window === 'undefined'
    ? process.env.API_BASE_URL // 서버
    : process.env.NEXT_PUBLIC_API_URL // 클라이언트

export const apiClient = axios.create({
  baseURL,
  timeout: 10000,
})
```

---

### Feature Flags

```typescript
// lib/feature-flags.ts
export const featureFlags = {
  enableNewDashboard: process.env.NEXT_PUBLIC_ENABLE_NEW_DASHBOARD === 'true',
  enableBetaFeatures: process.env.NEXT_PUBLIC_ENABLE_BETA === 'true',
};

// components/Dashboard.tsx
import { featureFlags } from '@/lib/feature-flags';

export function Dashboard() {
  if (featureFlags.enableNewDashboard) {
    return <NewDashboard />;
  }

  return <LegacyDashboard />;
}
```

---

### 환경별 설정

```typescript
// lib/config.ts
const isDev = process.env.NODE_ENV === 'development'
const isProd = process.env.NODE_ENV === 'production'

export const config = {
  apiUrl: isDev ? 'http://localhost:3001' : process.env.API_BASE_URL,

  enableDebugLogs: isDev,
  enableAnalytics: isProd,

  cacheTTL: isDev ? 10 : 3600, // 10초 vs 1시간
}
```

---

## 배포 환경 설정

### Vercel

1. Vercel Dashboard → 프로젝트 → Settings → Environment Variables
2. 변수 추가:
   - `API_BASE_URL`
   - `DATABASE_URL`
   - `JWT_SECRET`
3. 환경 선택: Production, Preview, Development

---

### AWS Amplify

```yaml
# amplify.yml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - npm ci
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: .next
    files:
      - '**/*'
  cache:
    paths:
      - node_modules/**/*

# 환경변수는 Amplify Console에서 설정
```

**Amplify Console:**

1. App settings → Environment variables
2. 변수 추가 (API_BASE_URL, JWT_SECRET 등)

---

## 결론

**핵심 요약:**

- API Route 사용 = `next.config.ts` env 필수
- 클라이언트 노출 = `NEXT_PUBLIC_` 접두사
- 민감한 정보 = 서버 전용 (NEXT*PUBLIC* 금지)
- 타입 안전성 = `env.d.ts`

**체크리스트:**

1. .env.local 정의
2. next.config.ts env 추가
3. env.d.ts 타입 정의
4. 빌드 테스트
