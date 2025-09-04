//
//  SharingView.swift
//  PhotoShare
//
//  Main photo sharing view - cleaned up for standalone app
//

import SwiftUI
import Photos

/// Photo sharing system main view
struct SharingView: View {
    @ObservedObject var photoViewModel: PhotoViewModel
    @ObservedObject var themeViewModel: ThemeViewModel
    @StateObject private var sharingViewModel = SharingViewModel()
    
    @State private var showingDatePicker = false
    @State private var currentStep: SharingStep = .dateSelection
    
    @Environment(\.theme) private var theme
    
    enum SharingStep: CaseIterable {
        case dateSelection      // 1. 날짜 선택
        case recipientSetup     // 2. 공유 대상자 설정
        case photoDistribution  // 3. 사진 분배
        case albumPreview      // 4. 앨범 미리보기 및 공유
        
        var title: String {
            switch self {
            case .dateSelection: return "사진"
            case .recipientSetup: return "대상자"
            case .photoDistribution: return "분배"
            case .albumPreview: return "공유"
            }
        }
        
        var subtitle: String {
            switch self {
            case .dateSelection: return "사진 확인"
            case .recipientSetup: return "사람 설정"
            case .photoDistribution: return "사진 분배"
            case .albumPreview: return "공유 실행"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main Content
                VStack(spacing: 0) {
                    // Progress Header
                    progressHeaderView
                    
                    Divider()
                        .opacity(0.3)
                    
                    // Step Content
                    stepContentView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Bottom Navigation Buttons
                VStack {
                    Spacer()
                    
                    HStack(spacing: 16) {
                        // Previous Button
                        if currentStep != .dateSelection {
                            Button("이전") {
                                goToPreviousStep()
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.secondaryText)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .frame(minHeight: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(theme.secondaryBackground.opacity(0.8))
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                            .contentShape(Rectangle())
                        }
                        
                        Spacer()
                        
                        // Next Button - Enhanced with accessibility and haptic feedback
                        if canProceedToNext {
                            Button(action: {
                                // Add haptic feedback for better UX
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                goToNextStep()
                            }) {
                                HStack(spacing: 8) {
                                    Text(nextButtonText)
                                    if !isLastStep {
                                        Image(systemName: "arrow.right")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                }
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .frame(minHeight: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(
                                        LinearGradient(
                                            colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: theme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                            .contentShape(Rectangle())
                            .accessibility(label: Text("\(nextButtonText). \(currentStep.subtitle)"))
                            .accessibility(hint: Text("버튼을 눌러 \(isLastStep ? "공유를 시작하세요" : "다음 단계로 이동하세요")"))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34) // Safe area padding
                }
                .navigationTitle("PhotoShare")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack(spacing: 16) {
                            // Calendar icon
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingDatePicker.toggle()
                                }
                            }) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(theme.accentColor)
                            }
                        }
                    }
                    
                }
                .background(theme.primaryBackground.ignoresSafeArea())
                
                // Overlay Date Picker
                if showingDatePicker {
                    OverlayDatePicker(
                        selectedDate: $photoViewModel.selectedDate,
                        isPresented: $showingDatePicker,
                        onDateSelected: { newDate in
                            Task {
                                // Load photos for the newly selected date
                                await photoViewModel.sendAsync(.changeDate(newDate))
                                await sharingViewModel.sendAsync(.createSession(newDate))
                            }
                        }
                    )
                    .zIndex(1000)
                }
            }
        }
        .background(theme.primaryBackground.ignoresSafeArea())
        .onAppear {
            print("🎬 SharingView appeared - 선택된 날짜: \(photoViewModel.selectedDate)")
            setupInitialState()
            // Photo sharing mode is always active in standalone app
            photoViewModel.send(.setSharingMode(true))
        }
        .onChange(of: photoViewModel.selectedDate) { oldValue, newValue in
            print("📅 날짜 변경됨: \(DateFormatter.photoTitle.string(from: oldValue)) → \(DateFormatter.photoTitle.string(from: newValue))")
            Task {
                // Update sharing session with new date
                await sharingViewModel.sendAsync(.createSession(newValue))
                
                // Ensure photos are loaded for new date
                if photoViewModel.photos.isEmpty || oldValue != newValue {
                    await photoViewModel.sendAsync(.loadPhotos(for: newValue))
                }
                
                print("🔄 날짜 변경 처리 완료 - 사진 수: \(photoViewModel.photos.count)")
            }
        }
    }
    
    // MARK: - Progress Header
    private var progressHeaderView: some View {
        VStack(spacing: 12) {
            // Step indicator
            HStack(spacing: 6) {
                ForEach(Array(SharingStep.allCases.enumerated()), id: \.offset) { index, step in
                    Circle()
                        .fill(index <= SharingStep.allCases.firstIndex(of: currentStep)! ? AnyShapeStyle(theme.accentColor) : AnyShapeStyle(theme.buttonBorder.opacity(0.3)))
                        .frame(width: 8, height: 8)
                    
                    if index < SharingStep.allCases.count - 1 {
                        Rectangle()
                            .fill(index < SharingStep.allCases.firstIndex(of: currentStep)! ? AnyShapeStyle(theme.accentColor) : AnyShapeStyle(theme.buttonBorder.opacity(0.3)))
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Step info
            HStack {
                Text(currentStep.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                
                Spacer()
                
                Text(stepCompletionInfo)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(canProceedToNext ? theme.accentColor : theme.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(canProceedToNext ? AnyShapeStyle(theme.accentColor.opacity(0.1)) : AnyShapeStyle(theme.secondaryBackground))
                    )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        .background(theme.primaryBackground)
    }
    
    // MARK: - Step Content
    @ViewBuilder
    private var stepContentView: some View {
        switch currentStep {
        case .dateSelection:
            dateSelectionView
            
        case .recipientSetup:
            recipientSetupView
            
        case .photoDistribution:
            photoDistributionView
            
        case .albumPreview:
            albumPreviewView
        }
    }
    
    private var dateSelectionView: some View {
        VStack(spacing: 16) {
            // Photo grid view
            if !photoViewModel.photos.isEmpty {
                photoGridView
            } else if photoViewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(theme.accentColor)
                    
                    Text("사진 확인 중...")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Empty state or permission error
                VStack(spacing: 16) {
                    if let errorMessage = photoViewModel.errorMessage,
                        errorMessage.contains("권한") {
                        // Permission error state
                        Image(systemName: "lock.circle")
                            .font(.system(size: 48))
                            .foregroundColor(theme.accentColor.opacity(0.7))
                        
                        Text("사진 라이브러리 접근 권한 필요")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryText)
                        
                        Text("PhotoShare가 사진을 표시하려면 권한이 필요해요")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("설정으로 이동") {
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsURL)
                            }
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                        .padding(.top, 8)
                        
                    } else {
                        // Enhanced no photos state with better diagnostics and accessibility
                        VStack(spacing: 20) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 48))
                                .foregroundColor(theme.accentColor.opacity(0.5))
                                .accessibility(hidden: true)
                            
                            VStack(spacing: 8) {
                                Text("선택한 날짜에 사진이 없습니다")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(theme.secondaryText)
                                
                                Text("\(DateFormatter.photoTitle.string(from: photoViewModel.selectedDate))")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(theme.accentColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(theme.accentColor.opacity(0.1))
                                    )
                                
                                Text("상단의 달력 아이콘을 눌러 다른 날짜를 선택해보세요")
                                    .font(.subheadline)
                                    .foregroundColor(theme.secondaryText.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibility(label: Text("선택한 날짜 \(DateFormatter.photoTitle.string(from: photoViewModel.selectedDate))에 사진이 없습니다. 다른 날짜를 선택해보세요."))
                            
                            // Quick action to open date picker with enhanced accessibility
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingDatePicker.toggle()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                    Text("날짜 선택하기")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(10)
                            }
                            .accessibility(label: Text("날짜 선택기 열기"))
                            .accessibility(hint: Text("다른 날짜의 사진을 찾으려면 버튼을 누르세요"))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private var photoGridView: some View {
        PhotoGridView(photos: photoViewModel.photos)
    }
    
    
    private var recipientSetupView: some View {
        VStack(spacing: 20) {
            // RecipientSetupView - main content
            RecipientSetupView(sharingViewModel: sharingViewModel)
            
            Spacer()
            
            // Continue button
            if !sharingViewModel.recipients.isEmpty {
                Button("사진 분배 시작") {
                    goToNextStep()
                }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    private var photoDistributionView: some View {
        VStack(spacing: 20) {
            // DirectionalDragView - main content
            DirectionalDragView(
                sharingViewModel: sharingViewModel,
                photoViewModel: photoViewModel
            )
            
            Spacer()
            
            // Continue button
            if sharingViewModel.getTotalPhotosDistributed() > 0 {
                Button("공유 앨범 확인하기") {
                    goToNextStep()
                }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    private var albumPreviewView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // TemporaryAlbumPreview - main content
            TemporaryAlbumPreview(sharingViewModel: sharingViewModel)
            
            Spacer()
            
            // Reset button
            Button("새로 시작하기") {
                resetSharingSession()
            }
            .fontWeight(.medium)
            .foregroundColor(theme.secondaryText)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.buttonBorder.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .contentShape(Rectangle())
        }
    }
    
    // MARK: - Navigation Logic
    private var canProceedToNext: Bool {
        switch currentStep {
        case .dateSelection:
            // Can't proceed if there are permission issues or no photos
            if let errorMessage = photoViewModel.errorMessage, errorMessage.contains("권한") {
                return false
            }
            return !photoViewModel.photos.isEmpty && !photoViewModel.isLoading
        case .recipientSetup:
            return !sharingViewModel.recipients.isEmpty
        case .photoDistribution:
            return sharingViewModel.getTotalPhotosDistributed() > 0
        case .albumPreview:
            return false
        }
    }
    
    private var stepCompletionInfo: String {
        switch currentStep {
        case .dateSelection:
            if photoViewModel.isLoading {
                return "확인 중..."
            } else if let errorMessage = photoViewModel.errorMessage, errorMessage.contains("권한") {
                return "권한 필요"
            } else if photoViewModel.photos.isEmpty {
                return "사진 없음"
            } else {
                return "\(photoViewModel.photos.count)장 준비됨"
            }
        case .recipientSetup:
            if sharingViewModel.recipients.isEmpty {
                return "대상자 없음"
            } else {
                return "\(sharingViewModel.recipients.count)명 설정됨"
            }
        case .photoDistribution:
            let distributed = sharingViewModel.getTotalPhotosDistributed()
            let total = photoViewModel.photos.count
            if distributed == 0 {
                return sharingViewModel.recipients.isEmpty ? "대상자 설정 필요" : "드래그로 분배"
            } else {
                return "\(distributed)/\(total)장 분배됨"
            }
        case .albumPreview:
            let albumCount = sharingViewModel.temporaryAlbums.filter { !$0.isEmpty }.count
            return sharingViewModel.canStartSharing ? "\(albumCount)개 앨범 준비됨" : "분배 필요"
        }
    }
    
    // MARK: - Helper Properties for Enhanced UX
    private var nextButtonText: String {
        switch currentStep {
        case .dateSelection: return "대상자 설정하기"
        case .recipientSetup: return "사진 분배하기"
        case .photoDistribution: return "앨범 미리보기"
        case .albumPreview: return "공유하기"
        }
    }
    
    private var isLastStep: Bool {
        currentStep == .albumPreview
    }
    
    private func goToNextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .dateSelection:
                currentStep = .recipientSetup
            case .recipientSetup:
                currentStep = .photoDistribution
            case .photoDistribution:
                currentStep = .albumPreview
            case .albumPreview:
                break
            }
        }
    }
    
    private func goToPreviousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .dateSelection:
                break
            case .recipientSetup:
                currentStep = .dateSelection
            case .photoDistribution:
                currentStep = .recipientSetup
            case .albumPreview:
                currentStep = .photoDistribution
            }
        }
    }
    
    private func setupInitialState() {
        Task {
            print("🚀 SharingView 초기 설정 시작")
            
            // 1. Create sharing session first
            await sharingViewModel.sendAsync(.createSession(photoViewModel.selectedDate))
            print("📝 공유 세션 생성 완료: \(photoViewModel.selectedDate)")
            
            // 2. Request permission and load photos
            await photoViewModel.sendAsync(.requestPermission)
            print("🔐 권한 요청 완료")
            
            // 3. Verify photos were loaded
            if photoViewModel.photos.isEmpty {
                print("⚠️ 초기 로딩 후 사진이 비어있음 - 추가 검증 시작")
                
                // Try loading for current date explicitly
                await photoViewModel.sendAsync(.loadPhotos(for: photoViewModel.selectedDate))
                
                // If still empty, try to find a date with photos
                if photoViewModel.photos.isEmpty {
                    print("🔍 현재 날짜에 사진 없음, 최근 사진 날짜 검색")
                    // This is handled in PhotoViewModel.requestPhotoPermission already
                }
            }
            
            print("✅ 초기 설정 완료 - 사진 수: \(photoViewModel.photos.count)")
        }
    }
    
    private func resetSharingSession() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .dateSelection
        }
        
        Task {
            await sharingViewModel.sendAsync(.clearSession)
            await sharingViewModel.sendAsync(.createSession(photoViewModel.selectedDate))
        }
    }
}

#Preview {
    let previewPhotoViewModel = PreviewData.createPreviewPhotoViewModel()
    let previewThemeViewModel = PreviewData.createPreviewThemeViewModel()
    
    return SharingView(
        photoViewModel: previewPhotoViewModel,
        themeViewModel: previewThemeViewModel
    )
    .environment(\.theme, PreviewData.sampleThemeColors)
}
