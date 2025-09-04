import SwiftUI

/// 공유 대상자 설정 및 관리 뷰
struct RecipientSetupView: View {
    @ObservedObject var sharingViewModel: SharingViewModel
    @State private var showingAddRecipientSheet = false
    @State private var newRecipientName = ""
    @State private var selectedDirection: ShareDirection = .top
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView
            
            // Recipients Grid
            if !sharingViewModel.recipients.isEmpty {
                recipientsGridView
            } else {
                emptyStateView
            }
            
            // Add recipient button
            addRecipientButton
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.primaryBackground)
                .shadow(color: theme.primaryShadow.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .sheet(isPresented: $showingAddRecipientSheet) {
            AddRecipientSheet(
                newRecipientName: $newRecipientName,
                selectedDirection: $selectedDirection,
                availableDirections: sharingViewModel.getAvailableDirections(),
                sharingViewModel: sharingViewModel,
                onAdd: addRecipient,
                onCancel: cancelAddRecipient
            )
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("대상자")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                
                Text("최대 8명")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            
            Spacer()
            
            // Recipients count badge
            if !sharingViewModel.recipients.isEmpty {
                Text("\(sharingViewModel.recipients.count)/8")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(theme.accentColor)
                    )
            }
        }
    }
    
    // MARK: - Recipients Grid - 최적화된 레이아웃
    private var recipientsGridView: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3),
            spacing: 20
        ) {
            ForEach(sharingViewModel.recipients) { recipient in
                RecipientCard(
                    recipient: recipient,
                    album: sharingViewModel.getAlbumFor(direction: recipient.direction),
                    onRemove: {
                        removeRecipient(recipient)
                    }
                )
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(theme.accentColor.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("사람을 추가하세요")
                    .font(.headline)
                    .foregroundColor(theme.primaryText)
                
                Text("각 방향에 한 명씩 최대 8명까지 설정해서 분배가능")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.secondaryBackground.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.buttonBorder.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Add Recipient Button
    private var addRecipientButton: some View {
        Button(action: {
            prepareAddRecipient()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("추가")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(sharingViewModel.recipients.count >= 8)
        .opacity(sharingViewModel.recipients.count >= 8 ? 0.6 : 1.0)
        .scaleEffect(sharingViewModel.recipients.count >= 8 ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: sharingViewModel.recipients.count >= 8)
    }
    
    // MARK: - Actions
    private func prepareAddRecipient() {
        newRecipientName = ""
        selectedDirection = sharingViewModel.getAvailableDirections().first ?? .top
        showingAddRecipientSheet = true
    }
    
    private func addRecipient() {
        let trimmedName = newRecipientName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else { return }
        
        Task {
            await sharingViewModel.sendAsync(.addRecipient(trimmedName, selectedDirection))
        }
        
        showingAddRecipientSheet = false
    }
    
    private func cancelAddRecipient() {
        showingAddRecipientSheet = false
        newRecipientName = ""
    }
    
    private func removeRecipient(_ recipient: ShareRecipient) {
        Task {
            await sharingViewModel.sendAsync(.removeRecipient(recipient))
        }
    }
}

// MARK: - Recipient Card
struct RecipientCard: View {
    let recipient: ShareRecipient
    let album: TemporaryAlbum?
    let onRemove: () -> Void
    
    @Environment(\.theme) private var theme
    @State private var showingRemoveConfirmation = false
    
    var body: some View {
        VStack(spacing: 10) {
            // Direction indicator with photo count - 크기 증대
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                recipient.swiftUIColor,
                                recipient.swiftUIColor.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: recipient.swiftUIColor.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: recipient.direction.systemIcon)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                // Photo count badge - 개선된 위치
                if let album = album, !album.isEmpty {
                    VStack {
                        HStack {
                            Spacer()
                            Text("\(album.photoCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(
                                    Circle()
                                        .fill(.red)
                                        .overlay(
                                            Circle()
                                                .stroke(.white, lineWidth: 2)
                                        )
                                )
                                .offset(x: 8, y: -8)
                        }
                        Spacer()
                    }
                }
            }
            
            // Name and direction - 간소화
            VStack(spacing: 4) {
                Text(recipient.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primaryText)
                    .lineLimit(1)
                
                Text(recipient.direction.displayName)
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(recipient.swiftUIColor.opacity(0.4), lineWidth: 2)
                )
                .shadow(color: theme.primaryShadow.opacity(0.1), radius: 6, x: 0, y: 3)
        )
        .onLongPressGesture {
            showingRemoveConfirmation = true
        }
        .alert("대상자 제거", isPresented: $showingRemoveConfirmation) {
            Button("취소", role: .cancel) { }
            Button("제거", role: .destructive) {
                onRemove()
            }
        } message: {
            Text("\(recipient.name)을(를) 제거하시겠습니까?\n해당 임시 앨범의 사진도 함께 삭제됩니다.")
        }
    }
}

// MARK: - Add Recipient Sheet
struct AddRecipientSheet: View {
    @Binding var newRecipientName: String
    @Binding var selectedDirection: ShareDirection
    let availableDirections: [ShareDirection]
    let sharingViewModel: SharingViewModel
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFieldFocused: Bool
    
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Name input section
                nameInputSection
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                
                // Direction selection section
                directionSelectionSection
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 30)
                
                Spacer()
                
                // Add button
                addButton
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 40)
            }
            .padding(20)
            .navigationTitle("새 공유 대상자")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        onCancel()
                        dismiss()
                    }
                }
            }
            .background(theme.primaryBackground)
        }
        .onAppear {
            // 단계별 등장 애니메이션
            withAnimation(.easeOut(duration: 0.4)) {
                isAnimating = true
            }
            
            // 키보드 포커스는 약간 딜레이 후 설정
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isNameFieldFocused = true
            }
        }
    }
    
    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이름")
                .font(.headline)
                .foregroundColor(theme.primaryText)
            
            TextField("공유할 사람의 이름을 입력하세요", text: $newRecipientName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isNameFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    if canAddRecipient {
                        onAdd()
                        dismiss()
                    }
                }
        }
    }
    
    private var directionSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("방향 선택")
                .font(.headline)
                .foregroundColor(theme.primaryText)
            
            if availableDirections.isEmpty {
                Text("사용 가능한 방향이 없습니다 (최대 8명)")
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.red.opacity(0.1))
                    )
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                    ForEach(ShareDirection.allCases) { direction in
                        DirectionSelectionCard(
                            direction: direction,
                            isSelected: selectedDirection == direction,
                            isAvailable: availableDirections.contains(direction),
                            onSelect: {
                                if availableDirections.contains(direction) {
                                    selectedDirection = direction
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }
    
    private var addButton: some View {
        Button(action: {
            onAdd()
            dismiss()
        }) {
            Text("추가")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: canAddRecipient ? [theme.accentColor, theme.accentColor.opacity(0.8)] : [.gray, .gray.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
        }
        .disabled(!canAddRecipient)
    }
    
    private var canAddRecipient: Bool {
        !newRecipientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        availableDirections.contains(selectedDirection)
    }
}

// MARK: - Direction Selection Card
struct DirectionSelectionCard: View {
    let direction: ShareDirection
    let isSelected: Bool
    let isAvailable: Bool
    let onSelect: () -> Void
    
    @Environment(\.theme) private var theme
    
    // 8방향별 Spring Theme 조화로운 색상
    private func getDirectionColor(_ direction: ShareDirection) -> Color {
        switch direction {
        case .top: return Color(red: 0.91, green: 0.35, blue: 0.35)        // 부드러운 빨강
        case .topRight: return Color(red: 0.91, green: 0.48, blue: 0.24)   // 따뜻한 주황
        case .right: return Color(red: 0.83, green: 0.65, blue: 0.35)      // 차분한 황금
        case .bottomRight: return Color(red: 0.42, green: 0.7, blue: 0.42) // 자연스러운 녹색
        case .bottom: return Color(red: 0.29, green: 0.56, blue: 0.7)      // 부드러운 파랑
        case .bottomLeft: return Color(red: 0.48, green: 0.42, blue: 0.7)  // 차분한 보라
        case .left: return Color(red: 0.7, green: 0.42, blue: 0.66)        // 부드러운 자주
        case .topLeft: return Color(red: 0.91, green: 0.35, blue: 0.6)     // 자연스러운 분홍
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                // Spring Theme 조화로운 색상으로 SF Symbol 사용
                ZStack {
                    Circle()
                        .fill(
                            isAvailable ? 
                            (isSelected ? 
                             LinearGradient(colors: [getDirectionColor(direction), getDirectionColor(direction).opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                             LinearGradient(colors: [getDirectionColor(direction).opacity(0.2), getDirectionColor(direction).opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            ) :
                            LinearGradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: direction.systemIcon)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(
                            isAvailable ? 
                            (isSelected ? .white : getDirectionColor(direction)) :
                            .gray
                        )
                }
                
                Text(direction.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isAvailable ? (isSelected ? .white : theme.primaryText) : .gray)
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isAvailable ?
                        (isSelected ? AnyShapeStyle(theme.accentColor) : AnyShapeStyle(theme.secondaryBackground)) :
                        AnyShapeStyle(theme.secondaryBackground.opacity(0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isAvailable ?
                                (isSelected ? AnyShapeStyle(theme.accentColor) : AnyShapeStyle(theme.buttonBorder.opacity(0.3))) :
                                AnyShapeStyle(.clear),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isAvailable)
        .scaleEffect(isSelected ? 1.08 : (isAvailable ? 1.0 : 0.95))
        .opacity(isAvailable ? 1.0 : 0.6)
        .animation(.interpolatingSpring(stiffness: 300, damping: 25), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isAvailable)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        RecipientSetupView(
            sharingViewModel: {
                let vm = SharingViewModel()
                Task {
                    await vm.sendAsync(.createSession(Date()))
                    await vm.sendAsync(.addRecipient("친구1", .top))
                    await vm.sendAsync(.addRecipient("친구2", .right))
                }
                return vm
            }()
        )
        .padding()
        
        Spacer()
    }
    .environment(\.theme, SpringThemeColors())
}