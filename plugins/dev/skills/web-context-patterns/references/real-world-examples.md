# 실제 구현 예시

web-almigo 프로젝트의 실제 Context 구현을 기반으로 한 완전한 예시.

## Dashboard 페이지 완전 구현

대시보드 페이지의 전체 Context 패턴 구현.

### 폴더 구조

```
features/CreatorPage/CreatorDashboardPage/
├── index.ts                                  # export default
├── CreatorDashboardPage.tsx                   # 메인 컴포넌트
├── providers/
│   └── CreatorDashboardPageProvider.tsx       # Provider
├── hooks/
│   └── useCreatorDashboardPage.ts             # 모든 로직
└── components/
    ├── DashboardContent.tsx                   # 목록 표시
    ├── DashboardStats.tsx                     # 통계 + 필터
    ├── DashboardSkeleton.tsx                  # 로딩
    └── DeleteModal.tsx                        # 삭제 모달
```

---

### hooks/useCreatorDashboardPage.ts (전체 코드)

```typescript
'use client'
import { useState, useCallback, useMemo } from 'react'
import { useRouter } from '@/i18n/navigation'
import { useMyCharactersSuspense, type Character } from '@/api/character/character.queries'
import { useDeleteCharacter } from '@/api/character/character.mutations'
import { useToast } from '@/contexts/ToastContext'

export type CharacterFilter = 'all' | 'registered' | 'draft' | 'error' | 'banned'

const useCreatorDashboardPage = () => {
  const router = useRouter()
  const { showToast } = useToast()
  const [filter, setFilter] = useState<CharacterFilter>('all')
  const [deleteTarget, setDeleteTarget] = useState<Character | null>(null)

  // API 호출
  const { data: characters } = useMyCharactersSuspense()
  const deleteMutation = useDeleteCharacter()

  // 통계 계산
  const stats = useMemo(
    () => ({
      total: characters.length,
      registered: characters.filter(
        (c) => c.status === 'PUBLISHED' || c.status === 'PRIVATE_BY_CREATOR',
      ).length,
      draft: characters.filter((c) => c.status === 'DRAFT').length,
      error: characters.filter((c) => c.status === 'VIDEO_FAILED' || c.status === 'VIDEO_ERROR')
        .length,
      banned: characters.filter((c) => c.status === 'BANNED_BY_ADMIN').length,
    }),
    [characters],
  )

  // 필터링된 캐릭터 목록
  const filteredCharacters = useMemo(() => {
    switch (filter) {
      case 'registered':
        return characters.filter(
          (c) => c.status === 'PUBLISHED' || c.status === 'PRIVATE_BY_CREATOR',
        )
      case 'draft':
        return characters.filter((c) => c.status === 'DRAFT')
      case 'error':
        return characters.filter((c) => c.status === 'VIDEO_FAILED' || c.status === 'VIDEO_ERROR')
      case 'banned':
        return characters.filter((c) => c.status === 'BANNED_BY_ADMIN')
      default:
        return characters
    }
  }, [characters, filter])

  // 액션들
  const handleCreateNew = useCallback(() => {
    router.push('/creator/new')
  }, [router])

  const handleEdit = useCallback(
    (characterId: string) => {
      router.push(`/creator/edit/${characterId}`)
    },
    [router],
  )

  const openDeleteModal = useCallback((char: Character) => {
    setDeleteTarget(char)
  }, [])

  const closeDeleteModal = useCallback(() => {
    setDeleteTarget(null)
  }, [])

  const confirmDelete = useCallback(async () => {
    if (!deleteTarget) return

    try {
      await deleteMutation.mutateAsync(deleteTarget.id)
      showToast('삭제되었습니다', { variant: 'success' })
      setDeleteTarget(null)
    } catch (error) {
      showToast('삭제에 실패했습니다', { variant: 'error' })
    }
  }, [deleteTarget, deleteMutation, showToast])

  // 반환: state/actions 분리
  return useMemo(
    () => ({
      state: {
        characters,
        stats,
        filter,
        filteredCharacters,
        deleteTarget,
        isDeleting: deleteMutation.isPending,
      },
      actions: {
        setFilter,
        handleCreateNew,
        handleEdit,
        openDeleteModal,
        closeDeleteModal,
        confirmDelete,
      },
    }),
    [
      characters,
      stats,
      filter,
      filteredCharacters,
      deleteTarget,
      deleteMutation.isPending,
      handleCreateNew,
      handleEdit,
      openDeleteModal,
      closeDeleteModal,
      confirmDelete,
    ],
  )
}

export default useCreatorDashboardPage
```

---

### providers/CreatorDashboardPageProvider.tsx (전체 코드)

```typescript
'use client';
import { ReactNode } from 'react';
import { createContext, useContextSelector } from 'use-context-selector';
import useCreatorDashboardPage from '../hooks/useCreatorDashboardPage';

type CreatorDashboardPageCtx = ReturnType<typeof useCreatorDashboardPage>;

const CreatorDashboardPageContext = createContext<CreatorDashboardPageCtx>(
  undefined as unknown as CreatorDashboardPageCtx
);

export const useCreatorDashboardPageSelector = <T,>(
  selector: (ctx: CreatorDashboardPageCtx) => T
) => {
  return useContextSelector(CreatorDashboardPageContext, (context) => {
    if (process.env.NODE_ENV !== 'production' && context === undefined) {
      throw new Error(
        'CreatorDashboardPageContext.Provider 안에서만 사용하세요.'
      );
    }
    return selector(context);
  });
};

export const CreatorDashboardPageProvider = ({
  children,
}: {
  children: ReactNode;
}) => {
  const value = useCreatorDashboardPage();
  return (
    <CreatorDashboardPageContext.Provider value={value}>
      {children}
    </CreatorDashboardPageContext.Provider>
  );
};
```

---

### components/DashboardContent.tsx (사용 예시)

```tsx
'use client'
import { useCreatorDashboardPageSelector } from '../providers/CreatorDashboardPageProvider'
import Button from '@/components/ui/button/Button'

export default function DashboardContent() {
  // ✅ selector로 필요한 값만 구독
  const filteredCharacters = useCreatorDashboardPageSelector((ctx) => ctx.state.filteredCharacters)
  const handleEdit = useCreatorDashboardPageSelector((ctx) => ctx.actions.handleEdit)
  const openDeleteModal = useCreatorDashboardPageSelector((ctx) => ctx.actions.openDeleteModal)

  return (
    <div className="grid grid-cols-3 gap-4">
      {filteredCharacters.map((character) => (
        <div key={character.id} className="border rounded p-4">
          <h3>{character.name}</h3>
          <p>{character.description}</p>

          <div className="flex gap-2 mt-4">
            <Button onClick={() => handleEdit(character.id)}>편집</Button>
            <Button variant="tertiary" onClick={() => openDeleteModal(character)}>
              삭제
            </Button>
          </div>
        </div>
      ))}
    </div>
  )
}
```

---

### components/DashboardStats.tsx (필터 UI)

```tsx
'use client'
import { useCreatorDashboardPageSelector } from '../providers/CreatorDashboardPageProvider'
import type { CharacterFilter } from '../hooks/useCreatorDashboardPage'

export default function DashboardStats() {
  const stats = useCreatorDashboardPageSelector((ctx) => ctx.state.stats)
  const filter = useCreatorDashboardPageSelector((ctx) => ctx.state.filter)
  const setFilter = useCreatorDashboardPageSelector((ctx) => ctx.actions.setFilter)

  const statItems: { key: CharacterFilter; label: string; color: string }[] = [
    { key: 'all', label: '전체', color: 'text-common-100' },
    { key: 'registered', label: '등록됨', color: 'text-blue-50' },
    { key: 'draft', label: '임시저장', color: 'text-yellow-50' },
    { key: 'error', label: '오류', color: 'text-red-50' },
    { key: 'banned', label: '정지', color: 'text-gray-50' },
  ]

  return (
    <div className="flex gap-2">
      {statItems.map((item) => (
        <button
          key={item.key}
          type="button"
          onClick={() => setFilter(item.key)}
          className={`flex items-center gap-2 rounded-lg px-2 py-1 ${
            filter === item.key ? 'bg-gray-26' : 'hover:bg-gray-20'
          }`}
        >
          <span className={filter === item.key ? 'text-common-100' : 'text-gray-50'}>
            {item.label}
          </span>
          <span className={item.color}>{stats[item.key]}</span>
        </button>
      ))}
    </div>
  )
}
```

---

### components/DeleteModal.tsx

```tsx
'use client'
import { useCreatorDashboardPageSelector } from '../providers/CreatorDashboardPageProvider'
import Modal from '@/components/ui/modal/Modal'
import Button from '@/components/ui/button/Button'

export default function DeleteModal() {
  const deleteTarget = useCreatorDashboardPageSelector((ctx) => ctx.state.deleteTarget)
  const isDeleting = useCreatorDashboardPageSelector((ctx) => ctx.state.isDeleting)
  const closeDeleteModal = useCreatorDashboardPageSelector((ctx) => ctx.actions.closeDeleteModal)
  const confirmDelete = useCreatorDashboardPageSelector((ctx) => ctx.actions.confirmDelete)

  return (
    <Modal open={!!deleteTarget} onClose={closeDeleteModal}>
      <div className="bg-gray-10 w-[400px] rounded-2xl p-6">
        <h2 className="font-18b-28">캐릭터 삭제</h2>
        <p className="mt-2 text-gray-60">'{deleteTarget?.name}'을(를) 정말 삭제하시겠습니까?</p>
        <div className="mt-6 flex gap-3">
          <Button variant="tertiary" onClick={closeDeleteModal}>
            취소
          </Button>
          <Button onClick={confirmDelete} isLoading={isDeleting}>
            삭제
          </Button>
        </div>
      </div>
    </Modal>
  )
}
```

---

### CreatorDashboardPage.tsx (메인)

```tsx
'use client'
import { useCreatorDashboardPageSelector } from './providers/CreatorDashboardPageProvider'
import Button from '@/components/ui/button/Button'
import DashboardStats from './components/DashboardStats'
import DashboardContent from './components/DashboardContent'
import DeleteModal from './components/DeleteModal'

export default function CreatorDashboardPage() {
  const handleCreateNew = useCreatorDashboardPageSelector((ctx) => ctx.actions.handleCreateNew)

  return (
    <div className="min-h-screen p-6">
      {/* 헤더 */}
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">내 캐릭터</h1>
        <Button onClick={handleCreateNew}>새로 만들기</Button>
      </div>

      {/* 통계 + 필터 */}
      <DashboardStats />

      {/* 캐릭터 목록 */}
      <div className="mt-6">
        <DashboardContent />
      </div>

      {/* 삭제 모달 */}
      <DeleteModal />
    </div>
  )
}
```

---

### page.tsx (라우트 파일)

```tsx
// app/[locale]/(main)/creator/page.tsx
import { Suspense } from 'react'
import CreatorDashboardPage from '@/features/CreatorPage/CreatorDashboardPage/CreatorDashboardPage'
import { CreatorDashboardPageProvider } from '@/features/CreatorPage/CreatorDashboardPage/providers/CreatorDashboardPageProvider'
import DashboardSkeleton from '@/features/CreatorPage/CreatorDashboardPage/components/DashboardSkeleton'

export default function CreatorPageRoute() {
  return (
    <Suspense fallback={<DashboardSkeleton />}>
      <CreatorDashboardPageProvider>
        <CreatorDashboardPage />
      </CreatorDashboardPageProvider>
    </Suspense>
  )
}
```

---

## ChatPage 완전 구현

채팅 페이지의 복잡한 Context 패턴 (Modal, 성인인증 포함).

### 폴더 구조

```
features/ChatPage/
├── ChatPage.tsx                    # 메인 컴포넌트
├── providers/
│   ├── ChatPageProvider.tsx        # 메인 Provider
│   └── chatSettingProvider/
│       └── ChatSettingProvider.tsx # 설정 Provider (localStorage)
├── hooks/
│   └── useChatPage.ts              # 메인 로직
└── components/
    ├── ChatContent.tsx
    ├── ChatInput.tsx
    ├── ChatSettings.tsx
    └── modals/
        ├── AdultVerificationModal.tsx
        └── SettingsModal.tsx
```

---

### hooks/useChatPage.ts

```typescript
'use client'
import { useState, useCallback, useMemo } from 'react'
import { useParams } from 'next/navigation'
import {
  useCharacterDetailSuspense,
  useIndividualCharacter,
} from '@/api/character/character.queries'
import { useSendMessage } from '@/api/chat/chat.mutations'
import { useUserSuspense } from '@/api/user/user.queries'

export type ModalType = 'settings' | 'adultVerification' | null

const useChatPage = () => {
  const params = useParams<{ id: string }>()
  const [modalState, setModalState] = useState<ModalType>(null)

  // API 호출
  const { data: character } = useCharacterDetailSuspense(params.id)
  const { data: individualCharacter } = useIndividualCharacter(params.id, character.is_group_chat)
  const { data: user } = useUserSuspense()
  const sendMessageMutation = useSendMessage()

  // 모달 핸들러
  const handleModalOpen = useCallback((type: ModalType) => {
    setModalState(type)
  }, [])

  const handleModalClose = useCallback(() => {
    setModalState(null)
  }, [])

  // 메시지 전송
  const handleSendMessage = useCallback(
    async (message: string) => {
      await sendMessageMutation.mutateAsync({
        character_id: params.id,
        message,
      })
    },
    [params.id, sendMessageMutation],
  )

  return useMemo(
    () => ({
      state: {
        character,
        individualCharacter,
        user,
        modalState,
        isSending: sendMessageMutation.isPending,
      },
      actions: {
        handleModalOpen,
        handleModalClose,
        handleSendMessage,
      },
    }),
    [
      character,
      individualCharacter,
      user,
      modalState,
      sendMessageMutation.isPending,
      handleModalOpen,
      handleModalClose,
      handleSendMessage,
    ],
  )
}

export default useChatPage
```

---

### providers/ChatPageProvider.tsx

```typescript
'use client';
import { ReactNode } from 'react';
import { createContext, useContextSelector } from 'use-context-selector';
import useChatPage from '../hooks/useChatPage';

type ChatPageCtx = ReturnType<typeof useChatPage>;

const ChatPageContext = createContext<ChatPageCtx>(
  undefined as unknown as ChatPageCtx
);

export const useChatPageSelector = <T,>(
  selector: (ctx: ChatPageCtx) => T
) => {
  return useContextSelector(ChatPageContext, (context) => {
    if (process.env.NODE_ENV !== 'production' && context === undefined) {
      throw new Error('ChatPageContext.Provider 안에서만 사용하세요.');
    }
    return selector(context);
  });
};

export const ChatPageProvider = ({ children }: { children: ReactNode }) => {
  const value = useChatPage();
  return (
    <ChatPageContext.Provider value={value}>
      {children}
    </ChatPageContext.Provider>
  );
};
```

---

## 공통 패턴

### 패턴 1: Modal 관리

**hooks에서 Modal 상태 관리:**

```typescript
// hooks/useFeature.ts
const useFeature = () => {
  const [modalState, setModalState] = useState<'settings' | 'delete' | null>(null)

  const openModal = useCallback((type: 'settings' | 'delete') => {
    setModalState(type)
  }, [])

  const closeModal = useCallback(() => {
    setModalState(null)
  }, [])

  return useMemo(
    () => ({
      state: { modalState },
      actions: { openModal, closeModal },
    }),
    [modalState, openModal, closeModal],
  )
}
```

**컴포넌트에서 Modal 렌더:**

```tsx
export default function FeaturePage() {
  const modalState = useFeatureSelector((ctx) => ctx.state.modalState)
  const openModal = useFeatureSelector((ctx) => ctx.actions.openModal)
  const closeModal = useFeatureSelector((ctx) => ctx.actions.closeModal)

  return (
    <>
      <Button onClick={() => openModal('settings')}>설정</Button>

      <SettingsModal open={modalState === 'settings'} onClose={closeModal} />
      <DeleteModal open={modalState === 'delete'} onClose={closeModal} />
    </>
  )
}
```

---

### 패턴 2: TanStack Form 통합

**hooks에서 Form 관리:**

```typescript
// hooks/useCreatorNew.ts
import { useForm } from '@tanstack/react-form'
import { useCreateCharacter } from '@/api/character/character.mutations'

const useCreatorNew = () => {
  const router = useRouter()
  const createMutation = useCreateCharacter()

  const form = useForm({
    defaultValues: {
      name: '',
      description: '',
      tags: [],
    },
    onSubmit: async ({ value }) => {
      const result = await createMutation.mutateAsync(value)
      router.push(`/creator/edit/${result.data.data.id}`)
    },
  })

  const handleCancel = useCallback(() => {
    router.back()
  }, [router])

  return useMemo(
    () => ({
      state: {
        form,
        isSubmitting: createMutation.isPending,
      },
      actions: {
        handleCancel,
      },
    }),
    [form, createMutation.isPending, handleCancel],
  )
}
```

**컴포넌트에서 Form 사용:**

```tsx
export default function CreatorNewPage() {
  const form = useCreatorNewSelector((ctx) => ctx.state.form)
  const isSubmitting = useCreatorNewSelector((ctx) => ctx.state.isSubmitting)
  const handleCancel = useCreatorNewSelector((ctx) => ctx.actions.handleCancel)

  return (
    <div>
      <form.Field name="name">
        {(field) => (
          <Input value={field.state.value} onChange={(e) => field.handleChange(e.target.value)} />
        )}
      </form.Field>

      <div className="flex gap-2">
        <Button variant="tertiary" onClick={handleCancel}>
          취소
        </Button>
        <Button onClick={form.handleSubmit} isLoading={isSubmitting}>
          생성
        </Button>
      </div>
    </div>
  )
}
```

---

### 패턴 3: localStorage 영속성

**ChatSettingContext 예시:**

```typescript
// hooks/useChatSetting.ts
'use client'
import { useState, useEffect, useCallback, useMemo } from 'react'

const useChatSetting = () => {
  // 초기값 (SSR 안전)
  const [volume, setVolumeState] = useState(0.5)
  const [backgroundColor, setBackgroundColorState] = useState('#FFFFFF')

  // 클라이언트에서 localStorage 로드
  useEffect(() => {
    const savedVolume = localStorage.getItem('chat_volume')
    const savedBg = localStorage.getItem('chat_bg_color')

    if (savedVolume) setVolumeState(parseFloat(savedVolume))
    if (savedBg) setBackgroundColorState(savedBg)
  }, [])

  // 볼륨 변경 (localStorage 저장)
  const setVolume = useCallback((newVolume: number) => {
    setVolumeState(newVolume)
    localStorage.setItem('chat_volume', newVolume.toString())
  }, [])

  // 배경색 변경
  const setBackgroundColor = useCallback((newColor: string) => {
    setBackgroundColorState(newColor)
    localStorage.setItem('chat_bg_color', newColor)
  }, [])

  return useMemo(
    () => ({
      state: { volume, backgroundColor },
      actions: { setVolume, setBackgroundColor },
    }),
    [volume, backgroundColor, setVolume, setBackgroundColor],
  )
}

export default useChatSetting
```

---

## 인증 필요 페이지 패턴

**AuthGuardProvider와 조합:**

```tsx
// app/[locale]/(main)/store/page.tsx
import { Suspense } from 'react'
import AuthGuardProvider from '@/providers/AuthGuardProvider'
import StorePage from '@/features/StorePage/StorePage'
import { StorePageProvider } from '@/features/StorePage/providers/StorePageProvider'
import StorePageSkeleton from '@/features/StorePage/components/StorePageSkeleton'

export default function Store() {
  return (
    <AuthGuardProvider fallback={<></>}>
      <Suspense fallback={<StorePageSkeleton />}>
        <StorePageProvider>
          <StorePage />
        </StorePageProvider>
      </Suspense>
    </AuthGuardProvider>
  )
}
```

**구조:**

```
AuthGuardProvider (인증 체크)
└── Suspense (로딩)
    └── StorePageProvider (상태 관리)
        └── StorePage (UI)
```

**예시 페이지:**

- StorePage: 상점
- MyPage: 마이 페이지
- SettingsPage: 설정

---

## 체크리스트

Provider/hooks 분리 구현 시:

- [ ] hooks 파일에 모든 로직 (useState, useCallback, useMemo)
- [ ] Provider는 단순 (hook 호출 + Context.Provider 반환)
- [ ] state/actions 명확히 분리
- [ ] useMemo로 반환값 최적화
- [ ] ReturnType으로 타입 정의
- [ ] Selector hook export
- [ ] Context는 Provider 파일 내부에서만 사용
- [ ] 개발 환경 에러 체크 (context === undefined)

---

## 결론

**핵심 원칙:**

- Provider는 20-40줄 (단순)
- hooks는 100-150줄 (모든 로직)
- state/actions 분리
- ReturnType 타입 추론

**실제 사용:**

- Dashboard: 필터 + stats + 삭제
- ChatPage: Modal + 메시지 전송
- ChatSetting: localStorage 영속성
