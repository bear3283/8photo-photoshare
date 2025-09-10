//
//  PhotoFullscreenView.swift
//  PhotoShare
//
//  Fullscreen photo viewer with zoom and navigation
//

import SwiftUI
import Photos

// MARK: - Custom Button Styles
struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct PhotoFullscreenView: View {
    let photo: PhotoItem
    let photos: [PhotoItem]
    @Binding var isPresented: Bool
    
    @State private var selectedIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGPoint = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGPoint = .zero
    @State private var fullQualityImages: [String: UIImage] = [:]
    @State private var loadingFullQuality: Set<String> = []
    
    @Environment(\.theme) private var theme
    private let photoService = PhotoService()
    
    init(photo: PhotoItem, photos: [PhotoItem], isPresented: Binding<Bool>) {
        self.photo = photo
        self.photos = photos
        self._isPresented = isPresented
        self._selectedIndex = State(initialValue: photos.firstIndex { $0.id == photo.id } ?? 0)
    }
    
    private var currentPhoto: PhotoItem {
        photos.indices.contains(selectedIndex) ? photos[selectedIndex] : photo
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Main photo view with zoom and pan
            if let displayImage = getDisplayImage(for: currentPhoto) {
                GeometryReader { geometry in
                    Image(uiImage: displayImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .scaleEffect(scale)
                        .offset(x: offset.x, y: offset.y)
                        .gesture(
                            SimultaneousGesture(
                                // Zoom gesture
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = lastScale * value
                                    }
                                    .onEnded { value in
                                        // Constrain zoom levels
                                        scale = max(1.0, min(scale, 4.0))
                                        lastScale = scale
                                        
                                        // Reset to center if zoomed out
                                        if scale == 1.0 {
                                            withAnimation(.spring(response: 0.3)) {
                                                offset = .zero
                                                lastOffset = .zero
                                            }
                                        }
                                    },
                                
                                // Pan and swipe gesture
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1.0 {
                                            // Pan when zoomed in
                                            offset = CGPoint(
                                                x: lastOffset.x + value.translation.width,
                                                y: lastOffset.y + value.translation.height
                                            )
                                        }
                                    }
                                    .onEnded { value in
                                        if scale > 1.0 {
                                            // Handle pan constraints when zoomed
                                            lastOffset = offset
                                            let maxOffsetX = (geometry.size.width * (scale - 1)) / 2
                                            let maxOffsetY = (geometry.size.height * (scale - 1)) / 2
                                            
                                            withAnimation(.spring(response: 0.3)) {
                                                offset.x = max(-maxOffsetX, min(maxOffsetX, offset.x))
                                                offset.y = max(-maxOffsetY, min(maxOffsetY, offset.y))
                                                lastOffset = offset
                                            }
                                        } else {
                                            // Handle swipe navigation when not zoomed
                                            let swipeThreshold: CGFloat = 50
                                            let velocity = value.predictedEndTranslation.width - value.translation.width
                                            
                                            if abs(value.translation.width) > swipeThreshold || abs(velocity) > 100 {
                                                if value.translation.width > 0 {
                                                    // Swipe right - go to previous photo
                                                    if selectedIndex > 0 {
                                                        withAnimation(.easeInOut(duration: 0.3)) {
                                                            selectedIndex -= 1
                                                            resetZoomAndPan()
                                                        }
                                                    }
                                                } else {
                                                    // Swipe left - go to next photo
                                                    if selectedIndex < photos.count - 1 {
                                                        withAnimation(.easeInOut(duration: 0.3)) {
                                                            selectedIndex += 1
                                                            resetZoomAndPan()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                            )
                        )
                        .onTapGesture(count: 2) {
                            // Double tap to zoom in/out
                            withAnimation(.spring(response: 0.3)) {
                                if scale > 1.0 {
                                    scale = 1.0
                                    offset = .zero
                                } else {
                                    scale = 2.0
                                }
                                lastScale = scale
                                lastOffset = offset
                            }
                        }
                }
                .ignoresSafeArea()
            }
            
            // Top overlay with close button and photo info
            VStack {
                HStack {
                    Button("완료") {
                        // Add haptic feedback for dismiss
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        isPresented = false
                    }
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.regularMaterial)
                            .opacity(0.8)
                    )
                    .buttonStyle(PressedButtonStyle())
                    
                    Spacer()
                    
                    // Photo counter
                    Text("\(selectedIndex + 1) / \(photos.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.3))
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                Spacer()
            }
            
            // Navigation buttons (left/right)
            HStack {
                // Previous photo
                if selectedIndex > 0 {
                    Button {
                        // Add haptic feedback for navigation
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedIndex -= 1
                            resetZoomAndPan()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(
                                Circle()
                                    .fill(.regularMaterial)
                                    .opacity(0.8)
                            )
                    }
                    .padding(.leading, 20)
                    .buttonStyle(PressedButtonStyle())
                }
                
                Spacer()
                
                // Next photo
                if selectedIndex < photos.count - 1 {
                    Button {
                        // Add haptic feedback for navigation
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedIndex += 1
                            resetZoomAndPan()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(
                                Circle()
                                    .fill(.regularMaterial)
                                    .opacity(0.8)
                            )
                    }
                    .padding(.trailing, 20)
                    .buttonStyle(PressedButtonStyle())
                }
            }
            
            // Bottom overlay with photo metadata
            VStack {
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentPhoto.dateCreated.photoDisplayString)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        // Favorite indicator
                        if currentPhoto.isFavorite {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                
                                Text("즐겨찾기")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .statusBarHidden(true)
        .navigationBarHidden(true)
        .gesture(
            // Swipe down to dismiss
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 100 && scale == 1.0 {
                        isPresented = false
                    }
                }
        )
        .onAppear {
            loadFullQualityImage(for: currentPhoto)
        }
        .onChange(of: selectedIndex) { oldValue, newValue in
            loadFullQualityImage(for: currentPhoto)
        }
    }
    
    private func resetZoomAndPan() {
        scale = 1.0
        offset = .zero
        lastScale = 1.0
        lastOffset = .zero
    }
    
    // MARK: - Full Quality Image Loading
    private func getDisplayImage(for photo: PhotoItem) -> UIImage? {
        // Try to return full quality image if available, otherwise use thumbnail
        return fullQualityImages[photo.asset.localIdentifier] ?? photo.image
    }
    
    private func loadFullQualityImage(for photo: PhotoItem) {
        let assetId = photo.asset.localIdentifier
        
        // Skip if already loaded or currently loading
        guard fullQualityImages[assetId] == nil && !loadingFullQuality.contains(assetId) else {
            return
        }
        
        // Mark as loading
        loadingFullQuality.insert(assetId)
        
        Task {
            if let fullQualityImage = await photoService.loadImage(for: photo.asset, context: .fullscreen) {
                await MainActor.run {
                    fullQualityImages[assetId] = fullQualityImage
                    loadingFullQuality.remove(assetId)
                }
            } else {
                await MainActor.run {
                    loadingFullQuality.remove(assetId)
                }
            }
        }
    }
}

#Preview {
    @State var isPresented = true
    
    // 샘플 PhotoItem 생성 (실제 PHAsset 없이 테스트용)
    let samplePhotos: [PhotoItem] = [
        PhotoItem(
            asset: PHAsset(), // 빈 asset (preview용)
            image: UIImage(systemName: "photo")!,
            dateCreated: Date()
        )
    ]
    
    return PhotoFullscreenView(
        photo: samplePhotos[0],
        photos: samplePhotos,
        isPresented: .constant(true)
    )
    .environment(\.theme, ThemeViewModel().colors)
}
