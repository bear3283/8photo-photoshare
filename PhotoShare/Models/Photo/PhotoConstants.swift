import SwiftUI

/// 앱 전체에서 사용하는 상수 정의
struct PhotoConstants {
    
    // MARK: - Swipe & Gesture
    
    /// 스와이프 완료로 인식되는 최소 거리
    static let swipeThreshold: CGFloat = 100
    
    /// 스와이프 완료 후 애니메이션 거리
    static let swipeAnimationDistance: CGFloat = 300
    
    /// 스와이프 중 사진 축소 비율
    static let swipeScaleEffect: CGFloat = 0.98
    
    // MARK: - Animation
    
    /// 기본 애니메이션 지속시간
    static let defaultAnimationDuration: TimeInterval = 0.3
    
    /// 인터랙티브 스프링 애니메이션 응답성
    static let springResponse: Double = 0.4
    
    /// 인터랙티브 스프링 애니메이션 댐핑
    static let springDamping: Double = 0.8
    
    /// 버튼 애니메이션 지속시간
    static let buttonAnimationDuration: TimeInterval = 0.2
    
    // MARK: - Image Processing
    
    /// 최대 이미지 크기 (메모리 최적화용)
    static let maxImageSize: CGFloat = 1024
    
    /// 이미지 캐시 한도 (개수)
    static let imageCacheLimit: Int = 50
    
    // MARK: - UI Dimensions
    
    /// 사진 뷰어 최소 높이
    static let minPhotoViewerHeight: CGFloat = 380
    
    /// 네비게이션 버튼 크기
    static let navigationButtonSize: CGFloat = 48
    
    /// 컴팩트 네비게이션 버튼 크기
    static let compactNavigationButtonSize: CGFloat = 36
    
    /// 점 인디케이터 최대 개수
    static let maxDotIndicators: Int = 5
    
    /// 활성 점 크기
    static let activeDotSize: CGFloat = 12
    
    /// 비활성 점 크기
    static let inactiveDotSize: CGFloat = 8
    
    // MARK: - Layout Spacing
    
    /// 기본 패딩
    static let defaultPadding: CGFloat = 16
    
    /// 작은 패딩
    static let smallPadding: CGFloat = 8
    
    /// 큰 패딩
    static let largePadding: CGFloat = 24
    
    /// 컴포넌트 간 기본 간격
    static let defaultSpacing: CGFloat = 12
    
    // MARK: - Corner Radius
    
    /// 기본 모서리 반경
    static let defaultCornerRadius: CGFloat = 12
    
    /// 작은 모서리 반경
    static let smallCornerRadius: CGFloat = 8
    
    /// 큰 모서리 반경
    static let largeCornerRadius: CGFloat = 20
    
    // MARK: - Opacity Values
    
    /// 비활성 요소 투명도
    static let inactiveOpacity: Double = 0.6
    
    /// 보조 텍스트 투명도
    static let secondaryTextOpacity: Double = 0.7
    
    /// 오버레이 배경 투명도 (라이트 모드)
    static let overlayOpacityLight: Double = 0.4
    
    /// 오버레이 배경 투명도 (다크 모드)
    static let overlayOpacityDark: Double = 0.7
}

/// 접근성 관련 상수
struct AccessibilityConstants {
    
    /// 최소 터치 타겟 크기
    static let minimumTouchTarget: CGFloat = 44
    
    /// 고대비 모드에서 추가 테두리 두께
    static let highContrastBorderWidth: CGFloat = 2
    
    /// VoiceOver 일시정지 시간
    static let voiceOverPause: TimeInterval = 0.5
}

/// 성능 관련 상수
struct PerformanceConstants {
    
    /// 이미지 로딩 타임아웃
    static let imageLoadTimeout: TimeInterval = 10.0
    
    /// 백그라운드 큐 QoS
    static let backgroundQoS: DispatchQoS.QoSClass = .userInitiated
    
    /// 메모리 경고 시 캐시 정리 비율
    static let memoryClearRatio: Double = 0.5
}