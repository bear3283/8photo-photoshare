//
//  PhotoGridView.swift
//  PhotoShare
//
//  Modern iOS 17 style photo grid with enhanced animations and accessibility
//

import SwiftUI
import Photos

struct PhotoGridView: View {
    let photos: [PhotoItem]
    @Environment(\.theme) private var theme
    @State private var selectedPhoto: PhotoItem?
    @State private var showingFullscreen = false
    @State private var isScrolling = false
    @Namespace private var photoTransition
    
    // Dynamic column calculation based on screen size
    private var columns: [GridItem] {
        let screenWidth = UIScreen.main.bounds.width
        let spacing: CGFloat = 2
        let padding: CGFloat = 8
        
        let availableWidth = screenWidth - (2 * padding)
        
        // Optimized for better photo visibility
        let columnCount: Int
        if screenWidth < 375 { // iPhone SE
            columnCount = 3
        } else if screenWidth < 430 { // iPhone 14, 15
            columnCount = 4
        } else if screenWidth < 500 { // iPhone Pro Max
            columnCount = 4
        } else { // iPad
            columnCount = 6
        }
        
        let itemSize = (availableWidth - (CGFloat(columnCount - 1) * spacing)) / CGFloat(columnCount)
        
        return Array(repeating: GridItem(
            .fixed(itemSize),
            spacing: spacing
        ), count: columnCount)
    }
    
    // Calculate item size for square grid items
    private var itemSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let spacing: CGFloat = 2
        let padding: CGFloat = 8
        let columnCount = columns.count
        
        let availableWidth = screenWidth - (2 * padding)
        return (availableWidth - (CGFloat(columnCount - 1) * spacing)) / CGFloat(columnCount)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(
                    columns: columns,
                    spacing: 2
                ) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        photoItemView(photo: photo, index: index)
                            .aspectRatio(1, contentMode: .fit)
                            .matchedGeometryEffect(
                                id: photo.id,
                                in: photoTransition
                            )
                            .scaleEffect(selectedPhoto?.id == photo.id ? 0.95 : 1.0)
                            .onTapGesture {
                                // Enhanced haptic feedback with selection animation
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.prepare()
                                
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    selectedPhoto = photo
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    impactFeedback.impactOccurred()
                                    
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        showingFullscreen = true
                                    }
                                }
                            }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in
                        if !isScrolling {
                            isScrolling = true
                        }
                    }
                    .onEnded { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isScrolling = false
                        }
                    }
            )
        }
        .fullScreenCover(isPresented: $showingFullscreen) {
            if let selectedPhoto = selectedPhoto {
                PhotoFullscreenView(
                    photo: selectedPhoto,
                    photos: photos,
                    isPresented: $showingFullscreen
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 1.1).combined(with: .opacity)
                ))
            }
        }
        .overlay {
            if photos.isEmpty {
                modernEmptyStateView
            }
        }
    }
    
    @ViewBuilder
    private func photoItemView(photo: PhotoItem, index: Int) -> some View {
        if let image = photo.image {
            loadedPhotoView(image: image, photo: photo, index: index)
        } else {
            loadingPhotoView(index: index)
        }
    }
    
    private func loadedPhotoView(image: UIImage, photo: PhotoItem, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: itemSize, height: itemSize)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // Favorite indicator with better visibility
            if photo.isFavorite {
                favoriteIndicatorView()
            }
        }
        .scaleEffect(isScrolling ? 0.98 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isScrolling)
    }
    
    private func loadingPhotoView(index: Int) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .frame(width: itemSize, height: itemSize)
            .overlay(
                ProgressView()
                    .tint(theme.accentColor)
            )
    }
    
    private func favoriteIndicatorView() -> some View {
        VStack {
            HStack {
                Spacer()
                Image(systemName: "heart.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .padding(.top, 4)
                    .padding(.trailing, 4)
            }
            Spacer()
        }
    }
    
    // MARK: - Modern Empty State
    private var modernEmptyStateView: some View {
        VStack(spacing: 24) {
            // Icon with subtle animation
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.secondaryText.opacity(0.6), theme.secondaryText.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: photos.isEmpty)
            
            VStack(spacing: 12) {
                Text("사진이 없습니다")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primaryText)
                
                Text("다른 날짜를 선택하거나\n사진을 추가해보세요")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

#Preview {
    // 샘플 PhotoItem들 생성
    let samplePhotos: [PhotoItem] = [
        PhotoItem(
            asset: PHAsset(),
            image: UIImage(systemName: "photo.fill")!,
            dateCreated: Date()
        ),
        PhotoItem(
            asset: PHAsset(),
            image: UIImage(systemName: "camera.fill")!,
            dateCreated: Date()
        ),
        PhotoItem(
            asset: PHAsset(),
            image: UIImage(systemName: "heart.fill")!,
            dateCreated: Date()
        )
    ]
    
    return PhotoGridView(photos: samplePhotos)
        .environment(\.theme, ThemeViewModel().colors)
}

#Preview("Empty State") {
    PhotoGridView(photos: [])
        .environment(\.theme, ThemeViewModel().colors)
}
