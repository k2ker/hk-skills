# Axios & API Layer Architecture

## 파일 구조

```
src/api/
├── client.ts             # Client 전용 axios instance
├── server.ts             # Server 전용 axios factory
├── types.ts              # 공통 응답 타입
└── {domain}/
    ├── {domain}.api.ts      # API 함수 (Client)
    ├── {domain}.server.ts   # API 함수 (Server)
    ├── {domain}.hooks.ts    # TanStack Query 훅
    ├── {domain}.queries.ts  # queryOptions 팩토리
    └── {domain}.types.ts    # 도메인 타입
```

---

## Client Axios Instance

```typescript
// api/client.ts
import axios, { AxiosError } from 'axios'

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request Interceptor: 인증 토큰 주입
api.interceptors.request.use(async (config) => {
  const token = getAccessToken() // 쿠키 또는 스토리지에서 가져오기
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Response Interceptor: 에러 핸들링
api.interceptors.response.use(
  (response) => {
    const result = response.data
    if (result?.success) return response

    // 인증 에러 처리
    if (isAuthError(result.code)) {
      clearAuthTokens()
    }
    throw result // FailResponse throw
  },
  (error: AxiosError) => {
    const apiError = {
      code: error.code ?? 'NETWORK_ERROR',
      message: error.message ?? '네트워크 오류가 발생했습니다',
      success: false,
    }
    return Promise.reject(apiError)
  },
)

export default api
```

---

## Server Axios Factory

```typescript
// api/server.ts
import axios from 'axios'
import { cookies } from 'next/headers'

// Factory 함수 (Server Component에서 매번 새 인스턴스 생성)
const createServerApi = async () => {
  const serverApi = axios.create({
    baseURL: process.env.API_URL || process.env.NEXT_PUBLIC_API_URL,
  })

  serverApi.interceptors.request.use(async (config) => {
    const cookieStore = await cookies()
    const accessToken = cookieStore.get('access_token')?.value

    if (accessToken) {
      config.headers.Authorization = `Bearer ${accessToken}`
    }
    return config
  })

  serverApi.interceptors.response.use(
    (res) => {
      const result = res.data
      if (result?.success ?? true) return res
      throw result
    },
    (err) => Promise.reject(err),
  )

  return serverApi
}

export default createServerApi
```

---

## 공통 응답 타입

```typescript
// api/types.ts
export interface Response<T> {
  success: boolean
  data: T
}

export interface PaginationResponse<T> {
  success: boolean
  data: {
    contents: T
    has_next: boolean
    total_count: number
    page_token: string
  }
}

export interface FailResponse<T = string> {
  success: boolean
  code: T
  message: string
  info?: unknown
}
```

---

## API 함수 패턴

### Client 전용

```typescript
// user/user.api.ts
import api from '../client'
import type { Response } from '../types'
import type { User } from './user.types'

export const getUser = async (): Promise<Response<User>> => {
  const response = await api.get('/api/v1/user')
  return response.data
}

export const putUserProfile = async (data: { nickname?: string }) => {
  const response = await api.put('/api/v1/user', data)
  return response.data
}
```

### Server 전용

```typescript
// page/page.server.ts
import createServerApi from '../server'
import type { HomeData } from './page.types'

export async function getHomeDataServer(): Promise<HomeData> {
  const api = await createServerApi()
  const response = await api.get('/api/v1/home')
  return response.data.data
}
```

---

## Client vs Server API 사용 구분

| 환경             | API 사용                     | 예시                         |
| ---------------- | ---------------------------- | ---------------------------- |
| Client Component | `api` (싱글톤)               | `useQuery`의 `queryFn`       |
| Server Component | `createServerApi()` (팩토리) | SSR `fetchQuery`의 `queryFn` |

### 규칙

- **Client**: 싱글톤 인스턴스 (`export default api`)
- **Server**: 팩토리 함수 (`async () => createServerApi()`)
- **이유**: Server Component는 요청마다 독립 컨텍스트, cookies() 호출 필요
- **네이밍**: Client는 `{fn}.api.ts`, Server는 `{fn}.server.ts`
