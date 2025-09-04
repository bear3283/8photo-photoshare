# PhotoShare

사진 공유 전용 앱 - Phohoto 프로젝트에서 추출한 깔끔한 사진 공유 기능

## 개요

이 앱은 기존의 3탭 구조(정리, 공유, 앨범)에서 가운데 탭인 **사진 공유 기능**만을 독립적으로 추출한 버전입니다.

## 주요 기능

- **4단계 사진 공유 프로세스**:
  1. 날짜 선택 및 사진 확인
  2. 공유 대상자 설정  
  3. 8방향 드래그로 사진 분배
  4. 앨범 미리보기 및 공유 실행

- **핵심 특징**:
  - 깔끔한 단일 화면 인터페이스
  - 직관적인 8방향 드래그 인터페이스
  - 테마 시스템 지원 (Spring/Sleek)
  - 간단한 온보딩 시스템

## 프로젝트 구조

```
PhotoShare/
├── App/
│   └── PhotoShareApp.swift        # 앱 진입점
├── Views/
│   ├── Main/
│   │   └── ContentView.swift      # 메인 컨텐트 뷰
│   ├── Sharing/
│   │   └── SharingView.swift      # 사진 공유 메인 뷰
│   └── Onboarding/
│       └── SimpleOnboardingView.swift
├── Components/
│   ├── DirectionalDragView.swift  # 8방향 드래그 컴포넌트
│   ├── RecipientSetupView.swift   # 대상자 설정 뷰
│   ├── TemporaryAlbumPreview.swift # 앨범 미리보기
│   └── Pickers/
│       └── DatePickerView.swift   # 날짜 선택기
├── ViewModels/
│   ├── PhotoViewModel.swift       # 사진 데이터 관리
│   ├── SharingViewModel.swift     # 공유 로직 관리
│   └── ThemeViewModel.swift       # 테마 관리
├── Services/
│   ├── PhotoService.swift         # 사진 서비스
│   ├── SharingService.swift       # 공유 서비스
│   └── ThemeService.swift         # 테마 서비스
├── Models/
│   ├── Photo/                     # 사진 관련 모델
│   ├── Sharing/                   # 공유 관련 모델
│   ├── Theme/                     # 테마 관련 모델
│   └── Album/                     # 앨범 관련 모델 (임시 앨범용)
└── Utilities/
    ├── Helpers/
    └── Extensions/
```

## 변경사항

기존 Phohoto 프로젝트 대비 변경사항:

- ✅ 탭 네비게이션 제거, 직접적인 사진 공유 인터페이스
- ✅ 앱 이름 변경: "PHOHOTO" → "PhotoShare"
- ✅ 불필요한 정리/앨범 뷰 관련 코드 제거
- ✅ 공유 모드가 항상 활성화된 상태로 설정
- ✅ 간소화된 앱 구조

## 사용 방법

1. 앱 실행 후 간단한 온보딩 완료
2. 날짜 선택으로 원하는 날짜의 사진들 확인
3. 공유할 대상자들 설정 (최대 8명)
4. 8방향 드래그로 각 사진을 원하는 대상자에게 분배
5. 생성된 앨범들 미리보기 후 공유 실행

## 기술 스택

- Swift 5.0+
- SwiftUI
- Photos Framework
- Combine Framework

이제 사진 공유 기능만을 위한 깔끔하고 집중된 앱을 사용할 수 있습니다!