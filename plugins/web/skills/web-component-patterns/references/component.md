# Feature 내부 컴포넌트 템플릿

`src/features/{Feature}/_components/` 내의 클라이언트 컴포넌트 기본 템플릿입니다.

## 기본 템플릿

```typescript
'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import Image from 'next/image';
import { cn } from '@/utils/cn';
import { Z_INDEX_CLASS } from '@/constants/zIndex';

interface MyComponentProps {
  // 필수 props
  data: SomeType;
  // 선택적 props
  className?: string;
  onAction?: () => void;
}

const MyComponent = ({ data, className, onAction }: MyComponentProps) => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div className={cn('relative', className)}>
      {/* 오버레이 요소는 Z_INDEX_CLASS 사용 */}
      <div className={`absolute inset-0 ${Z_INDEX_CLASS.OVERLAY}`}>
        {/* 애니메이션은 Framer Motion 사용 */}
        <AnimatePresence>
          {isOpen && (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 10 }}
              transition={{ type: 'spring', stiffness: 400, damping: 25 }}
            >
              {/* 컨텐츠 */}
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
};

export default MyComponent;
```

## 캐릭터 타입별 조건부 렌더링

```typescript
import { isDatingCharacter, hasAffectionFeature } from '@/api/klleon/character/character.type';

// DATING 캐릭터 전용 컴포넌트
{hasAffectionFeature(character) && (
  <AffectionOverlay relationship={character.user_character_relationship!} />
)}

// 비-DATING 캐릭터 전용 컴포넌트
{!isDatingCharacter(character) && character && (
  <CharacterProfileOverlay character={character} />
)}

// DATING 여부에 따른 스타일 분기
<div className={cn(
  'rounded-xl',
  isDatingCharacter(character)
    ? 'bg-linear-to-br from-pink-400 via-red-400 to-orange-400'
    : 'border border-black/10',
)}>
```

## Hover 확장 카드 패턴

```typescript
const [isExpanded, setIsExpanded] = useState(false);

return (
  <div
    className={`absolute left-3 bottom-4 ${Z_INDEX_CLASS.OVERLAY}`}
    onMouseEnter={() => setIsExpanded(true)}
    onMouseLeave={() => setIsExpanded(false)}
  >
    {/* 미니 배지 (항상 표시) */}
    <motion.div
      className="flex cursor-pointer items-center gap-2 rounded-full bg-black/50 px-3 py-1.5 backdrop-blur-sm"
      whileHover={{ scale: 1.02 }}
    >
      <span className="font-14b-22 text-white">{name}</span>
    </motion.div>

    {/* 확장 카드 (hover 시 표시) */}
    <AnimatePresence>
      {isExpanded && (
        <motion.div
          initial={{ opacity: 0, y: 10, scale: 0.95 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          exit={{ opacity: 0, y: 10, scale: 0.95 }}
          className="absolute bottom-full left-0 mb-2 w-[280px] rounded-2xl bg-black/70 backdrop-blur-md"
        >
          {/* 확장된 컨텐츠 */}
        </motion.div>
      )}
    </AnimatePresence>
  </div>
);
```

## 프로그레스 바 패턴

```typescript
// 백분율 계산
const progressPercent = Math.min(
  ((currentValue - minValue) / (maxValue - minValue)) * 100,
  100,
);

// 렌더링
<div className="h-1 w-full overflow-hidden rounded-full bg-white/20">
  <motion.div
    className="h-full rounded-full bg-linear-to-r from-pink-400 to-rose-400"
    initial={{ width: 0 }}
    animate={{ width: `${progressPercent}%` }}
    transition={{ duration: 0.5, ease: 'easeOut' }}
  />
</div>
```

## 필수 규칙

1. **'use client'** - hooks, context, 브라우저 API 사용 시 필수
2. **cn()** - Tailwind 클래스 병합에 사용
3. **Z_INDEX_CLASS** - 오버레이 요소에 z-index 상수 사용
4. **optional chaining** - `character?.property` (비동기 데이터)
5. **Framer Motion** - 애니메이션에 사용 (AnimatePresence + motion.div)
