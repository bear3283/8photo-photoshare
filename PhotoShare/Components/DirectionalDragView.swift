import SwiftUI
import Foundation

/// 8방향 드래그 시스템의 핵심 컴포넌트 - 원형 오버레이 UI
struct DirectionalDragView: View {
    @ObservedObject var sharingViewModel: SharingViewModel
    @ObservedObject var photoViewModel: PhotoViewModel
    
    @Environment(\.theme) private var theme
    @State private var selectedPhotoIndex = 0
    
    // 세그먼트된 도넛형 오버레이 설정
    private let donutOuterRadius: CGFloat = 180
    private let donutInnerRadius: CGFloat = 120  // 중앙 사진이 보이는 영역
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background (깔끔한 배경)
                backgroundView
                
                // Center photo area (더 큰 사진 뷰)
                centerPhotoView(in: geometry)
                
                // 원형 드래그 오버레이 (드래그 시에만 표시)
                if sharingViewModel.dragState.isDragging {
                    circularDragOverlay(in: geometry)
                }
                
                // 대상자가 없을 때 안내 메시지
                if sharingViewModel.recipients.isEmpty {
                    noRecipientsGuideView
                }
                
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Background (깔끔한 배경)
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(theme.primaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(theme.buttonBorder.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: theme.primaryShadow.opacity(0.08), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - 세그먼트된 도넛형 드래그 오버레이
    private func circularDragOverlay(in geometry: GeometryProxy) -> some View {
        let centerPoint = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        
        return ZStack {
            // 세그먼트된 도넛 오버레이
            segmentedDonutOverlay(centerPoint: centerPoint)
            
            // 중앙 원형 테두리 (사진 영역 강조)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.9), Color.white.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: donutInnerRadius * 2, height: donutInnerRadius * 2)
                .position(centerPoint)
                .scaleEffect(sharingViewModel.dragState.isDragging ? 1.08 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: sharingViewModel.dragState.isDragging)
        }
    }
    
    // MARK: - 세그먼트된 도넛 오버레이
    private func segmentedDonutOverlay(centerPoint: CGPoint) -> some View {
        ZStack {
            // 8개 방향 세그먼트들
            ForEach(ShareDirection.allCases, id: \.self) { direction in
                let recipient = sharingViewModel.recipients.first { $0.direction == direction }
                let isActive = sharingViewModel.dragState.targetDirection == direction
                
                donutSegment(
                    direction: direction,
                    recipient: recipient,
                    centerPoint: centerPoint,
                    isActive: isActive
                )
            }
            
            // 세그먼트 구분선들
            ForEach(0..<8, id: \.self) { index in
                let angle = Double(index) * 45.0 - 22.5 // 각 세그먼트 경계선
                let radians = angle * .pi / 180
                let innerX = centerPoint.x + Foundation.cos(radians) * donutInnerRadius
                let innerY = centerPoint.y + Foundation.sin(radians) * donutInnerRadius
                let outerX = centerPoint.x + Foundation.cos(radians) * donutOuterRadius
                let outerY = centerPoint.y + Foundation.sin(radians) * donutOuterRadius
                
                Path { path in
                    path.move(to: CGPoint(x: innerX, y: innerY))
                    path.addLine(to: CGPoint(x: outerX, y: outerY))
                }
                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
            }
        }
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: sharingViewModel.dragState.isDragging)
    }
    
    // MARK: - 도넛 세그먼트
    private func donutSegment(direction: ShareDirection, recipient: ShareRecipient?, centerPoint: CGPoint, isActive: Bool) -> some View {
        let angle = getAngleForDirection(direction)
        let startAngle = Angle.degrees(angle - 22.5)
        let endAngle = Angle.degrees(angle + 22.5)
        
        return ZStack {
            // 세그먼트 배경
            DonutSegmentShape(
                innerRadius: donutInnerRadius,
                outerRadius: donutOuterRadius,
                startAngle: startAngle,
                endAngle: endAngle
            )
            .fill(
                recipient != nil ?
                LinearGradient(
                    colors: [
                        recipient!.swiftUIColor.opacity(isActive ? 0.9 : 0.6),
                        recipient!.swiftUIColor.opacity(isActive ? 0.7 : 0.4)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                ) :
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.2)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )
            .position(centerPoint)
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
            
            // 세그먼트 내 정보 표시
            if let recipient = recipient {
                segmentInfo(
                    recipient: recipient,
                    direction: direction,
                    centerPoint: centerPoint,
                    isActive: isActive
                )
            }
        }
    }
    
    // MARK: - 세그먼트 정보 표시
    private func segmentInfo(recipient: ShareRecipient, direction: ShareDirection, centerPoint: CGPoint, isActive: Bool) -> some View {
        let angle = getAngleForDirection(direction)
        let radians = angle * .pi / 180
        let segmentMidRadius = (donutInnerRadius + donutOuterRadius) / 2
        let x = centerPoint.x + Foundation.cos(radians) * segmentMidRadius
        let y = centerPoint.y + Foundation.sin(radians) * segmentMidRadius
        
        let album = sharingViewModel.getAlbumFor(direction: direction)
        let photoCount = album?.photoCount ?? 0
        
        return VStack(spacing: 4) {
            // 방향 아이콘
            Image(systemName: direction.systemIcon)
                .font(.system(size: isActive ? 20 : 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            
            // 이름
            Text(recipient.name)
                .font(.system(size: isActive ? 11 : 9, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.7), radius: 1, x: 0, y: 1)
                .lineLimit(1)
            
            // 사진 개수 (있을 때만)
            if photoCount > 0 {
                Text("\(photoCount)")
                    .font(.system(size: isActive ? 12 : 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                    )
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
        }
        .position(x: x, y: y)
        .scaleEffect(isActive ? 1.2 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isActive)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: photoCount)
    }
    
    
    
    // MARK: - 헬퍼 함수
    private func getAngleForDirection(_ direction: ShareDirection) -> Double {
        switch direction {
        case .top: return -90
        case .topRight: return -45
        case .right: return 0
        case .bottomRight: return 45
        case .bottom: return 90
        case .bottomLeft: return 135
        case .left: return 180
        case .topLeft: return -135
        }
    }
    
    // MARK: - Center Photo (확대된 크기)
    private func centerPhotoView(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            if !photoViewModel.photos.isEmpty {
                // 확대된 사진 드래그 뷰
                EnhancedPhotoDragView(
                    photo: photoViewModel.photos[selectedPhotoIndex],
                    sharingViewModel: sharingViewModel,
                    circularOverlayRadius: donutOuterRadius,
                    donutInnerRadius: donutInnerRadius
                )
                
                // 사진 네비게이션 (항상 표시)
                photoNavigationView
            } else {
                EmptyPhotoView()
            }
        }
        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
    }
    
    private var photoNavigationView: some View {
        HStack(spacing: 16) {
            Button(action: previousPhoto) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(theme.accentColor)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(theme.primaryBackground))
                    .shadow(color: theme.primaryShadow.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .disabled(selectedPhotoIndex == 0)
            
            Text("\(selectedPhotoIndex + 1) / \(photoViewModel.photos.count)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.secondaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(theme.primaryBackground.opacity(0.8))
                )
            
            Button(action: nextPhoto) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(theme.accentColor)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(theme.primaryBackground))
                    .shadow(color: theme.primaryShadow.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .disabled(selectedPhotoIndex == photoViewModel.photos.count - 1)
        }
    }
    
    
    // MARK: - No Recipients Guide
    private var noRecipientsGuideView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(theme.accentColor)
                .symbolEffect(.bounce, value: sharingViewModel.recipients.isEmpty)
            
            VStack(spacing: 8) {
                Text("공유할 대상자를 먼저 설정하세요")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                
                Text("이전 단계로 돌아가서\n공유할 사람들을 추가해주세요")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            Button("대상자 설정하러 가기") {
                // This would need to be handled by the parent view
                // For now, just show the message
            }
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
            .cornerRadius(25)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    
    
    // MARK: - Actions
    private func previousPhoto() {
        if selectedPhotoIndex > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedPhotoIndex -= 1
            }
        }
    }
    
    private func nextPhoto() {
        if selectedPhotoIndex < photoViewModel.photos.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedPhotoIndex += 1
            }
        }
    }
    
    // MARK: - Helper Methods (UI 숨김 기능 제거됨)
    // 더 이상 필요없는 UI 토글 기능들을 제거
}


// MARK: - Enhanced Photo Drag View (도넛형 오버레이용 사진 뷰)
struct EnhancedPhotoDragView: View {
    let photo: PhotoItem
    let sharingViewModel: SharingViewModel
    let circularOverlayRadius: CGFloat
    let donutInnerRadius: CGFloat
    
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @Environment(\.theme) private var theme
    
    var body: some View {
        ZStack {
            if let image = photo.image {
                let photoSize = min(donutInnerRadius * 1.8, 280) // 더 큰 사진 크기로 개선
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: photoSize, height: photoSize)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(
                        color: .black.opacity(isDragging ? 0.6 : 0.15), 
                        radius: isDragging ? 25 : 12, 
                        x: 0, 
                        y: isDragging ? 10 : 6
                    )
                    .scaleEffect(isDragging ? 0.85 : 1.0) // 드래그 시 살짝 축소
                    .offset(dragOffset)
                    .opacity(isDragging ? 1.0 : 1.0) // 도넛 중앙에서 완전히 보이도록
                    .overlay(
                        // 드래그 시 테두리 효과 - 도넛과 조화
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: isDragging ? 
                                    [Color.white.opacity(0.9), theme.accentColor.opacity(0.8)] :
                                    [Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isDragging ? 4 : 0
                            )
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isDragging)
                    )
                    // 도넛 중앙에 있을 때 추가 시각적 강조
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isDragging ? 
                                Color.white.opacity(0.3) :
                                Color.clear,
                                lineWidth: 1
                            )
                            .blur(radius: isDragging ? 2 : 0)
                            .animation(.easeInOut(duration: 0.3), value: isDragging)
                    )
                    .gesture(
                        DragGesture(coordinateSpace: .local)
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                    // Enhanced haptic feedback for drag start
                                    let selectionFeedback = UISelectionFeedbackGenerator()
                                    selectionFeedback.selectionChanged()
                                    
                                    Task {
                                        await sharingViewModel.sendAsync(.startDrag(photo, value.startLocation))
                                    }
                                }
                                
                                dragOffset = value.translation
                                
                                // Throttle drag updates for better performance
                                Task {
                                    await sharingViewModel.sendAsync(.updateDrag(value.translation, value.location))
                                }
                            }
                            .onEnded { value in
                                isDragging = false
                                
                                let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                                let minimumDragDistance: CGFloat = 60 // Reduced for better UX
                                
                                Task {
                                    if distance > minimumDragDistance {
                                        // Success haptic feedback
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                        impactFeedback.impactOccurred()
                                        await sharingViewModel.sendAsync(.endDrag(sharingViewModel.dragState.targetDirection))
                                    } else {
                                        // Light haptic for cancel
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                        await sharingViewModel.sendAsync(.endDrag(nil))
                                    }
                                }
                                
                                // Enhanced spring animation
                                withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
                                    dragOffset = .zero
                                }
                            }
                    )
                    // Enhanced accessibility support
                    .accessibility(label: Text("사진 공유 드래그"))
                    .accessibility(hint: Text("사진을 8방향 중 하나로 드래그하여 공유 대상자에게 할당하세요"))
                    .accessibility(addTraits: .isButton)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isDragging)
    }
}

// MARK: - Supporting Views

struct EmptyPhotoView: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 48))
                .foregroundColor(theme.accentColor.opacity(0.6))
            
            Text("선택한 날짜에 사진이 없습니다")
                .font(.headline)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(width: 240, height: 160)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.secondaryBackground.opacity(0.3))
                .stroke(theme.buttonBorder.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Custom Shapes

/// 도넛 세그먼트를 그리는 커스텀 Shape
struct DonutSegmentShape: Shape {
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        // 외부 호 (시계방향)
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        // 끝점에서 내부 원으로 직선
        let endRadians = endAngle.radians
        let innerEndPoint = CGPoint(
            x: center.x + Foundation.cos(endRadians) * innerRadius,
            y: center.y + Foundation.sin(endRadians) * innerRadius
        )
        path.addLine(to: innerEndPoint)
        
        // 내부 호 (반시계방향)
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        
        // 시작점으로 닫기
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Preview
#Preview {
    VStack {
        DirectionalDragView(
            sharingViewModel: {
                let vm = SharingViewModel()
                Task {
                    await vm.sendAsync(.createSession(Date()))
                    await vm.sendAsync(.addRecipient("친구1", .top))
                    await vm.sendAsync(.addRecipient("친구2", .right))
                    await vm.sendAsync(.addRecipient("친구3", .bottom))
                    await vm.sendAsync(.addRecipient("친구4", .left))
                }
                return vm
            }(),
            photoViewModel: PhotoViewModel()
        )
        .padding()
    }
    .environment(\.theme, SpringThemeColors())
}