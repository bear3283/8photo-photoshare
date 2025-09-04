import Foundation
import SwiftUI

// MARK: - Onboarding Manager
@MainActor
final class OnboardingManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isOnboardingCompleted: Bool {
        didSet {
            UserDefaults.standard.set(isOnboardingCompleted, forKey: "OnboardingCompleted")
        }
    }
    
    @Published var currentPageIndex: Int = 0
    @Published var isAnimating: Bool = false
    
    // MARK: - Constants
    private let onboardingKey = "OnboardingCompleted"
    
    // MARK: - Initialization
    init() {
        self.isOnboardingCompleted = UserDefaults.standard.bool(forKey: onboardingKey)
    }
    
    // MARK: - Public Methods
    func nextPage() {
        guard currentPageIndex < OnboardingPage.pages.count - 1 else {
            completeOnboarding()
            return
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentPageIndex += 1
        }
    }
    
    func previousPage() {
        guard currentPageIndex > 0 else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentPageIndex -= 1
        }
    }
    
    func skipToPage(_ index: Int) {
        guard index >= 0 && index < OnboardingPage.pages.count else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentPageIndex = index
        }
    }
    
    func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isOnboardingCompleted = true
        }
        
        // 완료 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("🎉 온보딩 완료!")
    }
    
    func resetOnboarding() {
        isOnboardingCompleted = false
        currentPageIndex = 0
        print("🔄 온보딩 리셋")
    }
    
    // MARK: - Helper Properties
    var isLastPage: Bool {
        currentPageIndex == OnboardingPage.pages.count - 1
    }
    
    var isFirstPage: Bool {
        currentPageIndex == 0
    }
    
    var currentPage: OnboardingPage {
        OnboardingPage.pages[currentPageIndex]
    }
    
    var progress: Double {
        Double(currentPageIndex + 1) / Double(OnboardingPage.pages.count)
    }
}