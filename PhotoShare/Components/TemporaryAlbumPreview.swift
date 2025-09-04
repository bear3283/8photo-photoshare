import SwiftUI

/// 임시 앨범들의 미리보기 및 관리 뷰
struct TemporaryAlbumPreview: View {
    @ObservedObject var sharingViewModel: SharingViewModel
    @State private var selectedAlbum: TemporaryAlbum?
    @State private var showingAlbumDetail = false
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            headerView
            
            // Albums preview
            if !sharingViewModel.temporaryAlbums.isEmpty {
                albumsPreviewView
                
                // Share controls
                shareControlsView
            } else {
                emptyStateView
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.primaryBackground)
                .shadow(color: theme.primaryShadow.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .sheet(item: $selectedAlbum) { album in
            AlbumDetailSheet(album: album, sharingViewModel: sharingViewModel)
        }
        .alert("공유 상태", isPresented: .constant(sharingViewModel.errorMessage != nil)) {
            Button("확인") {
                sharingViewModel.send(.clearError)
            }
        } message: {
            Text(sharingViewModel.errorMessage ?? "")
        }
        // 공유 성공 시 간단한 피드백
        .overlay(alignment: .top) {
            if sharingViewModel.currentSession?.status == .completed {
                successToast
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.5), value: sharingViewModel.currentSession?.status)
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("임시 앨범")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                
                if !sharingViewModel.temporaryAlbums.isEmpty {
                    Text("\(sharingViewModel.getTotalPhotosDistributed())장의 사진 분배됨")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
            }
            
            Spacer()
            
            // Quick stats - 개선된 공유 상태 표시
            HStack(spacing: 8) {
                let totalPhotos = sharingViewModel.getTotalPhotosDistributed()
                let nonEmptyAlbums = sharingViewModel.temporaryAlbums.filter { !$0.isEmpty }.count
                let totalAlbums = sharingViewModel.temporaryAlbums.count
                
                Image(systemName: sharingViewModel.canStartSharing ? "checkmark.circle.fill" : "info.circle")
                    .foregroundColor(sharingViewModel.canStartSharing ? .green : theme.accentColor)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(sharingViewModel.canStartSharing ? "공유 준비 완료" : "일부 앨범 준비됨")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(sharingViewModel.canStartSharing ? .green : theme.primaryText)
                    
                    Text("\(totalPhotos)장 사진 • \(nonEmptyAlbums)/\(totalAlbums)명 대상자")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryText)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(sharingViewModel.canStartSharing ? AnyShapeStyle(.green.opacity(0.1)) : AnyShapeStyle(theme.accentColor.opacity(0.1)))
            )
        }
    }
    
    // MARK: - Albums Preview
    private var albumsPreviewView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            ForEach(sharingViewModel.temporaryAlbums) { album in
                AlbumPreviewCard(
                    album: album,
                    onTap: {
                        selectedAlbum = album
                        showingAlbumDetail = true
                    }
                )
            }
        }
    }
    
    // MARK: - Share Controls
    private var shareControlsView: some View {
        VStack(spacing: 12) {
            // Share readiness indicator
            shareReadinessIndicator
            
            // Share button
            shareButton
        }
    }
    
    private var shareReadinessIndicator: some View {
        HStack {
            ForEach(sharingViewModel.temporaryAlbums) { album in
                HStack(spacing: 4) {
                    Circle()
                        .fill(album.isEmpty ? .red : .green)
                        .frame(width: 8, height: 8)
                        .symbolEffect(.pulse, options: .repeat(.continuous).speed(1), value: album.isEmpty)
                    
                    Text(album.recipient.name)
                        .font(.caption2)
                        .foregroundColor(album.isEmpty ? .red : theme.secondaryText)
                        .fontWeight(album.isEmpty ? .medium : .regular)
                }
                .transition(.scale.combined(with: .opacity))
                
                if album.id != sharingViewModel.temporaryAlbums.last?.id {
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryText.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.secondaryBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            sharingViewModel.canStartSharing ? 
                            .green.opacity(0.3) : .red.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.3), value: sharingViewModel.canStartSharing)
    }
    
    private var shareButton: some View {
        Button(action: {
            Task {
                await sharingViewModel.sendAsync(.shareAlbums)
            }
        }) {
            HStack(spacing: 8) {
                if sharingViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .symbolEffect(.bounce, value: sharingViewModel.canStartSharing)
                }
                
                Text(sharingViewModel.isLoading ? "공유 중..." : "모든 앨범 공유하기")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: sharingViewModel.canStartSharing && !sharingViewModel.isLoading ?
                    [theme.accentColor, theme.accentColor.opacity(0.8)] :
                    [.gray, .gray.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(
                color: sharingViewModel.canStartSharing && !sharingViewModel.isLoading ? 
                theme.accentColor.opacity(0.3) : .clear,
                radius: 8, x: 0, y: 4
            )
            .scaleEffect(sharingViewModel.canStartSharing && !sharingViewModel.isLoading ? 1.0 : 0.98)
        }
        .disabled(!sharingViewModel.canStartSharing || sharingViewModel.isLoading)
        .animation(.easeInOut(duration: 0.2), value: sharingViewModel.canStartSharing)
        .animation(.easeInOut(duration: 0.2), value: sharingViewModel.isLoading)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(theme.accentColor.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("임시 앨범이 없습니다")
                    .font(.headline)
                    .foregroundColor(theme.primaryText)
                
                Text("공유 대상자를 추가하고\n사진을 드래그하여 분배해보세요")
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
                .stroke(theme.buttonBorder.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Success Toast
    private var successToast: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("공유 완료!")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Text("모든 앨범이 성공적으로 공유되었습니다")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .green.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

// MARK: - Album Preview Card
struct AlbumPreviewCard: View {
    let album: TemporaryAlbum
    let onTap: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Recipient info with direction
                HStack(spacing: 8) {
                    // Direction indicator
                    ZStack {
                        Circle()
                            .fill(album.recipient.swiftUIColor)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: album.recipient.direction.systemIcon)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .rotationEffect(album.recipient.direction.angle)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(album.recipient.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryText)
                        
                        Text(album.recipient.direction.displayName)
                            .font(.caption2)
                            .foregroundColor(theme.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Photo count with badge style
                    ZStack {
                        Circle()
                            .fill(album.isEmpty ? .red.opacity(0.1) : theme.accentColor.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Text("\(album.photoCount)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(album.isEmpty ? .red : theme.accentColor)
                    }
                    .scaleEffect(album.isEmpty ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: album.isEmpty)
                }
                
                // Photos preview
                if !album.isEmpty {
                    photoPreviewGrid
                } else {
                    emptyAlbumIndicator
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.secondaryBackground.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                album.isEmpty ? .red.opacity(0.3) : album.recipient.swiftUIColor.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var photoPreviewGrid: some View {
        let maxPhotos = min(album.photos.count, 4)
        let photos = Array(album.photos.prefix(maxPhotos))
        
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 2), spacing: 2) {
            ForEach(photos) { photo in
                if let image = photo.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
            // Show "+X more" if there are more photos
            if album.photos.count > 4 {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.accentColor.opacity(0.8))
                        .frame(width: 40, height: 40)
                    
                    Text("+\(album.photos.count - 4)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 82)
    }
    
    private var emptyAlbumIndicator: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.badge.plus")
                .font(.title2)
                .foregroundColor(.red.opacity(0.6))
                .symbolEffect(.pulse, options: .repeat(.continuous).speed(2))
            
            Text("사진을 드래그하여\n앨범에 추가하세요")
                .font(.caption)
                .foregroundColor(.red)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(height: 82)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.red.opacity(0.1))
                .stroke(.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Album Detail Sheet
struct AlbumDetailSheet: View {
    let album: TemporaryAlbum
    @ObservedObject var sharingViewModel: SharingViewModel
    
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Album info header
                albumInfoHeader
                    .padding()
                
                Divider()
                
                // Photos grid
                if !album.isEmpty {
                    photosGridView
                } else {
                    emptyAlbumView
                }
            }
            .navigationTitle(album.recipient.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    shareAlbumButton
                }
            }
            .background(theme.primaryBackground)
        }
    }
    
    private var albumInfoHeader: some View {
        HStack(spacing: 16) {
            // Direction indicator
            ZStack {
                Circle()
                    .fill(album.recipient.swiftUIColor)
                    .frame(width: 50, height: 50)
                
                Image(systemName: album.recipient.direction.systemIcon)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .rotationEffect(album.recipient.direction.angle)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(album.recipient.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                
                Text("\(album.recipient.direction.displayName) 방향")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                
                Text("\(album.photoCount)장의 사진")
                    .font(.caption)
                    .foregroundColor(album.isEmpty ? .red : theme.accentColor)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
    
    private var photosGridView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                ForEach(album.photos) { photo in
                    if let image = photo.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding()
        }
    }
    
    private var emptyAlbumView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(theme.accentColor.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("앨범이 비어있습니다")
                    .font(.headline)
                    .foregroundColor(theme.primaryText)
                
                Text("\(album.recipient.direction.displayName) 방향으로\n사진을 드래그하여 추가해보세요")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private var shareAlbumButton: some View {
        Button {
            // Individual album sharing
            Task {
                await sharingViewModel.sendAsync(.shareIndividualAlbum(album))
            }
            dismiss()
        } label: {
            HStack(spacing: 8) {
                if sharingViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.subheadline)
                }
                
                Text(sharingViewModel.isLoading ? "공유 중..." : "공유하기")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: !album.isEmpty && !sharingViewModel.isLoading ? 
                    [theme.accentColor, theme.accentColor.opacity(0.8)] :
                    [.gray, .gray.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
        }
        .disabled(album.isEmpty || sharingViewModel.isLoading)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        TemporaryAlbumPreview(
            sharingViewModel: {
                let vm = SharingViewModel()
                Task {
                    await vm.sendAsync(.createSession(Date()))
                    await vm.sendAsync(.addRecipient("친구1", .top))
                    await vm.sendAsync(.addRecipient("친구2", .right))
                    await vm.sendAsync(.addRecipient("친구3", .bottom))
                }
                return vm
            }()
        )
        .padding()
        
        Spacer()
    }
    .environment(\.theme, SpringThemeColors())
}