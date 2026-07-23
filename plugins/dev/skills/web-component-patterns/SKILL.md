---
name: web-component-patterns
description: UI 컴포넌트 레퍼런스 및 Feature 컴포넌트 템플릿. 기존 컴포넌트 재사용, Skeleton/Modal 패턴. 새 컴포넌트 작성 시 참조.
metadata:
  author: klleon
---

# 컴포넌트 패턴

UI 컴포넌트 레퍼런스와 Feature 컴포넌트 작성 템플릿.

## 상세 문서

| 문서                                                       | 용도                                              |
| ---------------------------------------------------------- | ------------------------------------------------- |
| [references/ui-components.md](references/ui-components.md) | Button, Modal, Switch 등 UI 컴포넌트 Props/사용법 |
| [references/component.md](references/component.md)         | Feature 컴포넌트, 조건부 렌더링, 애니메이션       |
| [references/modal.md](references/modal.md)                 | 모달, 성인인증 모달, ChatPageContext 연동         |

## Skeleton 패턴

```tsx
const PageSkeleton = () => (
  <div className="flex min-h-full flex-col px-6 py-8">
    <div className="h-9 w-32 animate-pulse rounded-lg bg-gray-20" />
    <div className="mt-6 space-y-4">
      {Array.from({ length: 4 }).map((_, i) => (
        <div key={i} className="h-20 animate-pulse rounded-2xl bg-gray-20" />
      ))}
    </div>
  </div>
)
```

## Modal 패턴

```tsx
<Modal open={open} onClose={onClose}>
  <div className="bg-gray-10 w-[400px] rounded-2xl p-6">
    <h2 className="font-18b-28">제목</h2>
    <div className="mt-4">{/* 내용 */}</div>
    <div className="mt-6 flex gap-3">
      <Button variant="tertiary" onClick={onClose}>
        취소
      </Button>
      <Button>확인</Button>
    </div>
  </div>
</Modal>
```

## Feature 컴포넌트 구조

```
features/{FeatureName}/
├── {FeatureName}.tsx
├── {FeatureName}Skeleton.tsx
├── providers/
├── hooks/
└── components/           # ✅ 언더바 없음
```
