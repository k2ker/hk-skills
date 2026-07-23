# 모달 컴포넌트 템플릿

## 기본 모달 템플릿

```typescript
'use client';

import { useTranslations } from 'next-intl';
import Modal from '@/components/ui/modal/Modal';
import IconButton from '@/components/ui/iconButton/IconButton';
import IconClose from '@/assets/icons/icon_stroke_Close.svg';

interface MyModalProps {
  open: boolean;
  onClose: () => void;
  data?: SomeType;
}

const MyModal = ({ open, onClose, data }: MyModalProps) => {
  const t = useTranslations();

  return (
    <Modal open={open} onClose={onClose}>
      <div className="bg-gray-10 relative w-[400px] rounded-2xl p-6">
        {/* 닫기 버튼 */}
        <IconButton
          className="absolute top-4 right-4 size-8 bg-transparent"
          icon={<IconClose className="size-5 text-white" />}
          onClick={onClose}
        />

        {/* 제목 */}
        <h2 className="font-18b-28 mb-4 text-white">{t('모달 제목')}</h2>

        {/* 컨텐츠 */}
        <div className="space-y-4">
          {/* ... */}
        </div>
      </div>
    </Modal>
  );
};

export default MyModal;
```

## 사이드 모달 템플릿

```typescript
'use client';

import { useTranslations } from 'next-intl';
import SideModal from '@/components/ui/sideModal/SideModal';
import IconButton from '@/components/ui/iconButton/IconButton';
import IconClose from '@/assets/icons/icon_stroke_Close.svg';

interface MySideModalProps {
  open: boolean;
  onClose: () => void;
}

const MySideModal = ({ open, onClose }: MySideModalProps) => {
  const t = useTranslations();

  return (
    <SideModal open={open} onClose={onClose} side="right">
      <div className="bg-gray-10 flex h-full w-[400px] flex-col px-6 pt-10">
        {/* 헤더 */}
        <div className="flex items-center justify-between">
          <span className="font-18b-28 text-white">{t('제목')}</span>
          <IconButton
            className="size-8 bg-transparent"
            icon={<IconClose className="size-6 text-white" />}
            onClick={onClose}
          />
        </div>

        {/* 스크롤 컨텐츠 */}
        <div className="hide-scrollbar flex-1 overflow-y-auto py-7">
          {/* 섹션들 */}
        </div>
      </div>
    </SideModal>
  );
};

export default MySideModal;
```

## ChatPageContext 연동

```typescript
// 모달 상태는 ChatPageContext에서 관리
const handleModalOpen = useChatPageSelector(state => state.handleModalOpen);
const handleModalClose = useChatPageSelector(state => state.handleModalClose);
const modalState = useChatPageSelector(state => state.state.modalState);

// 모달 열기
<button onClick={() => handleModalOpen('myModal')}>열기</button>

// 모달 컴포넌트
<MyModal
  open={modalState.myModal}
  onClose={() => handleModalClose('myModal')}
/>
```

## 성인인증 모달 패턴 (국내/해외 분기)

성인인증이 필요한 컴포넌트에서는 `useAdultVerification` 훅 사용:

```typescript
import { useAdultVerification } from '@/hooks/useAdultVerification';
import InternationalAdultVerificationModal from '@/components/ui/modal/InternationalAdultVerificationModal';

const MyComponent = () => {
  const {
    startVerification,
    isVerifying,
    showInternationalModal,
    closeInternationalModal,
    verifyInternational,
  } = useAdultVerification();

  const handleVerify = async () => {
    await startVerification();
  };

  return (
    <>
      <Button onClick={handleVerify} isLoading={isVerifying}>
        인증하기
      </Button>

      {/* 해외 사용자 성인인증 모달 */}
      <InternationalAdultVerificationModal
        open={showInternationalModal}
        onClose={closeInternationalModal}
        onVerify={verifyInternational}
        isLoading={isVerifying}
      />
    </>
  );
};
```

**동작:**

- 국내 사용자 (IP 기반): PortOne 본인인증 자동 시작
- 해외 사용자: `InternationalAdultVerificationModal` 표시 → 체크박스 동의 후 API 호출

## 필수 규칙

1. **open, onClose props** - 모든 모달은 이 패턴 사용
2. **useTranslations()** - 텍스트는 번역 키 사용
3. **닫기 버튼** - 우측 상단에 IconClose 배치
4. **배경색** - `bg-gray-10` 사용
5. **Portal** - Modal/SideModal 컴포넌트가 자동으로 portal 처리
6. **성인인증** - `useAdultVerification` 훅 + `InternationalAdultVerificationModal` 연동
