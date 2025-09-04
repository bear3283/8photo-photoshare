import SwiftUI

// MARK: - Onboarding Data Model
struct OnboardingPage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let iconName: String
    let iconColor: Color
    let gradientColors: [Color]
    let features: [String]
    
    static func == (lhs: OnboardingPage, rhs: OnboardingPage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Onboarding Content
extension OnboardingPage {
    static let pages: [OnboardingPage] = [
        // Step 1: 날짜 선택 및 사진 확인
        OnboardingPage(
            title: "1단계: 날짜 선택",
            subtitle: "공유할 사진의 날짜를 선택해보세요",
            description: "달력에서 원하는 날짜를 선택하면 해당 날짜의 모든 사진들을 확인할 수 있어요",
            iconName: "calendar.badge.plus",
            iconColor: .blue,
            gradientColors: [
                Color(red: 0.3, green: 0.7, blue: 0.9),
                Color(red: 0.2, green: 0.5, blue: 0.8)
            ],
            features: [
                "📅 달력에서 간편한 날짜 선택",
                "📸 선택한 날짜의 모든 사진 확인",
                "⚡ 빠른 날짜 변경 가능",
                "🔍 사진이 없는 날짜는 자동 스킵"
            ]
        ),
        
        // Step 2: 공유 대상자 설정
        OnboardingPage(
            title: "2단계: 대상자 설정",
            subtitle: "사진을 공유받을 사람들을 추가하세요",
            description: "최대 8명까지 공유 대상자를 설정할 수 있어요. 각자에게 어떤 사진을 보낼지 다음 단계에서 선택하게 됩니다",
            iconName: "person.2.fill",
            iconColor: .green,
            gradientColors: [
                Color(red: 0.2, green: 0.8, blue: 0.4),
                Color(red: 0.1, green: 0.7, blue: 0.3)
            ],
            features: [
                "👥 최대 8명까지 대상자 추가",
                "✏️ 각 대상자 이름 맞춤 설정",
                "🎨 대상자별 색상 자동 지정",
                "📝 언제든 수정 및 삭제 가능"
            ]
        ),
        
        // Step 3: 8방향 드래그로 사진 분배
        OnboardingPage(
            title: "3단계: 사진 분배",
            subtitle: "8방향 드래그로 사진을 나누어보세요",
            description: "사진을 8방향(상하좌우, 대각선)으로 드래그하여 각 대상자에게 분배해보세요. 직관적이고 재미있는 방식이에요!",
            iconName: "arrow.up.and.down.and.arrow.left.and.right",
            iconColor: .orange,
            gradientColors: [
                Color(red: 1.0, green: 0.6, blue: 0.2),
                Color(red: 0.9, green: 0.4, blue: 0.1)
            ],
            features: [
                "🎯 직관적인 8방향 드래그 시스템",
                "👆 한 번의 드래그로 빠른 분배",
                "🔄 실시간 분배 상태 확인",
                "↩️ 실수 시 쉬운 되돌리기"
            ]
        ),
        
        // Step 4: 앨범 미리보기 및 공유 실행
        OnboardingPage(
            title: "4단계: 공유 실행",
            subtitle: "만들어진 앨범을 확인하고 공유하세요",
            description: "각 대상자별로 만들어진 앨범을 미리보고, 메시지나 이메일로 한 번에 공유할 수 있어요",
            iconName: "square.and.arrow.up.circle.fill",
            iconColor: .purple,
            gradientColors: [
                Color(red: 0.7, green: 0.3, blue: 0.8),
                Color(red: 0.6, green: 0.2, blue: 0.7)
            ],
            features: [
                "👀 대상자별 앨범 미리보기",
                "📱 메시지, 이메일로 즉시 공유",
                "🔗 여러 앱으로 동시 전송",
                "✅ 공유 완료 상태 확인"
            ]
        )
    ]
}