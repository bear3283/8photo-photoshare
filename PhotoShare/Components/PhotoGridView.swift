//
//  PhotoGridView.swift
//  PhotoShare
//
//  Enhanced photo grid with iOS Photos app-style layout
//

import SwiftUI

struct PhotoGridView: View {
    let photos: [PhotoItem]
    @Environment(\.theme) private var theme
    @State private var selectedPhoto: PhotoItem?
    @State private var showingFullscreen = false
    
    // Dynamic column calculation based on screen size
    private var columns: [GridItem] {
        let screenWidth = UIScreen.main.bounds.width
        let spacing: CGFloat = 1.5
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
        let spacing: CGFloat = 1.5
        let padding: CGFloat = 8
        let columnCount = columns.count
        
        let availableWidth = screenWidth - (2 * padding)
        return (availableWidth - (CGFloat(columnCount - 1) * spacing)) / CGFloat(columnCount)
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: columns,
                spacing: 1.5
            ) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    photoGridItem(photo: photo, index: index)
                        .aspectRatio(1, contentMode: .fit)
                        .onTapGesture {
                            // Haptic feedback for better UX
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            
                            selectedPhoto = photo
                            showingFullscreen = true
                        }
                        .scaleEffect(showingFullscreen && selectedPhoto?.id == photo.id ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: showingFullscreen && selectedPhoto?.id == photo.id)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
        .fullScreenCover(isPresented: $showingFullscreen) {
            if let selectedPhoto = selectedPhoto {
                PhotoFullscreenView(
                    photo: selectedPhoto,
                    photos: photos,
                    isPresented: $showingFullscreen
                )
            }
        }
    }
    
    @ViewBuilder
    private func photoGridItem(photo: PhotoItem, index: Int) -> some View {
        Group {
            if let image = photo.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: itemSize, height: itemSize)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .contentShape(Rectangle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    )
            } else {
                // Dummy image or loading placeholder
                if let dummyImage = DummyImageGenerator.generatePhoto(
                    index: index, 
                    size: CGSize(width: itemSize, height: itemSize)
                ) {
                    Image(uiImage: dummyImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: itemSize, height: itemSize)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                        .contentShape(Rectangle())
                        .opacity(0.7)
                        .overlay(
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text("더미")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(Color.black.opacity(0.6))
                                        )
                                        .padding(4)
                                }
                            }
                        )
                } else {
                    // Fallback to loading placeholder
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.secondaryBackground)
                        .frame(width: itemSize, height: itemSize)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.6)
                                .tint(theme.accentColor)
                        )
                }
            }
        }
        .shadow(color: Color.black.opacity(0.05), radius: 0.5, x: 0, y: 0.5)
    }
}

#Preview {
    PhotoGridView(photos: PreviewData.samplePhotos)
        .environment(\.theme, SpringThemeColors())
}