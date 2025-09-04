import SwiftUI

// MARK: - Simple Onboarding View
struct SimpleOnboardingView: View {
    @EnvironmentObject private var onboardingManager: OnboardingManager
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Current page content
            currentPageContent
            
            Spacer()
            
            // Bottom controls
            bottomControls
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 50)
        .background(
            LinearGradient(
                colors: onboardingManager.currentPage.gradientColors.map { $0.opacity(0.1) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.8), value: onboardingManager.currentPageIndex)
        )
    }
    
    // MARK: - Current Page Content
    private var currentPageContent: some View {
        VStack(spacing: 30) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: onboardingManager.currentPage.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: onboardingManager.currentPage.iconColor.opacity(0.3), radius: 15, x: 0, y: 8)
                
                Image(systemName: onboardingManager.currentPage.iconName)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Text content
            VStack(spacing: 16) {
                Text(onboardingManager.currentPage.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: onboardingManager.currentPage.gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)
                
                Text(onboardingManager.currentPage.subtitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(onboardingManager.currentPage.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 10)
            }
            
            // Features
            VStack(spacing: 12) {
                ForEach(Array(onboardingManager.currentPage.features.enumerated()), id: \.offset) { index, feature in
                    HStack(spacing: 16) {
                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.primary.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        LinearGradient(
                                            colors: onboardingManager.currentPage.gradientColors.map { $0.opacity(0.3) },
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                }
            }
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<OnboardingPage.pages.count, id: \.self) { index in
                    Circle()
                        .fill(
                            index == onboardingManager.currentPageIndex ?
                            LinearGradient(
                                colors: onboardingManager.currentPage.gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: index == onboardingManager.currentPageIndex ? 12 : 8, 
                               height: index == onboardingManager.currentPageIndex ? 12 : 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: onboardingManager.currentPageIndex)
                }
            }
            
            // Navigation buttons
            HStack(spacing: 16) {
                // Back button
                if !onboardingManager.isFirstPage {
                    Button("이전") {
                        onboardingManager.previousPage()
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: onboardingManager.currentPage.gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: onboardingManager.currentPage.gradientColors.map { $0.opacity(0.3) },
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
                }
                
                Spacer()
                
                // Skip button
                if !onboardingManager.isLastPage {
                    Button("건너뛰기") {
                        onboardingManager.completeOnboarding()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                
                Spacer()
                
                // Next/Complete button
                Button(onboardingManager.isLastPage ? "사진 공유 시작하기" : "다음") {
                    if onboardingManager.isLastPage {
                        onboardingManager.completeOnboarding()
                    } else {
                        onboardingManager.nextPage()
                    }
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: onboardingManager.currentPage.gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(
                            color: onboardingManager.currentPage.gradientColors.first?.opacity(0.3) ?? .clear,
                            radius: 6, x: 0, y: 3
                        )
                )
            }
        }
    }
}

#Preview {
    SimpleOnboardingView()
        .environmentObject(OnboardingManager())
        .environment(\.theme, SpringThemeColors())
}