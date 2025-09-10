//
//  SimplifiedSharingView.swift
//  PhotoShare
//
//  Simplified photo sharing with theme support and PhotoGridView
//

import SwiftUI
import Photos

struct SimplifiedSharingView: View {
    @ObservedObject var photoViewModel: PhotoViewModel
    @ObservedObject var themeViewModel: ThemeViewModel
    @State private var showingDatePicker = false
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // Photo content
                if photoViewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(theme.accentColor)
                        
                        Text("사진 로딩 중...")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !photoViewModel.photos.isEmpty {
                    // Use the existing PhotoGridView
                    PhotoGridView(photos: photoViewModel.photos)
                } else {
                    // Empty or error state
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
                            
                            Text("설정에서 PhotoShare에 사진 접근 권한을 허용해주세요")
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
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                            
                        } else {
                            // No photos state
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 48))
                                .foregroundColor(theme.secondaryText.opacity(0.6))
                            
                            Text("선택한 날짜에 사진이 없습니다")
                                .font(.title3)
                                .foregroundColor(theme.primaryText)
                            
                            Text("다른 날짜를 선택해보세요")
                                .font(.subheadline)
                                .foregroundColor(theme.secondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Share button
                if !photoViewModel.photos.isEmpty {
                    Button(action: {
                        let imagesToShare = photoViewModel.photos.compactMap { $0.image }
                        let activityVC = UIActivityViewController(
                            activityItems: imagesToShare,
                            applicationActivities: nil
                        )
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootViewController = windowScene.windows.first?.rootViewController {
                            rootViewController.present(activityVC, animated: true)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                            Text("사진 공유하기")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(
                            color: theme.accentColor.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    }
                }
            }
            .padding()
            .background(theme.primaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingDatePicker = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .medium))
                            Text(DateFormatter.photoTitle.string(from: photoViewModel.selectedDate))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(theme.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(theme.accentColor.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .preferredColorScheme(themeViewModel.currentTheme == .sleek ? .dark : .light)
        }
        .sheet(isPresented: $showingDatePicker) {
            VStack(spacing: 20) {
                Text("날짜 선택")
                    .font(.headline)
                    .foregroundColor(theme.primaryText)
                    .padding(.top)
                
                DatePicker(
                    "날짜 선택",
                    selection: $photoViewModel.selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .accentColor(theme.accentColor)
                
                Button("완료") {
                    showingDatePicker = false
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.accentColor)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(theme.primaryBackground)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            photoViewModel.send(.setSharingMode(true))
            
            Task {
                await photoViewModel.sendAsync(.requestPermission)
            }
        }
        .onChange(of: photoViewModel.selectedDate) { _, newValue in
            Task {
                await photoViewModel.sendAsync(.changeDate(newValue))
            }
        }
    }
}

#Preview {
    let photoViewModel = PhotoViewModel()
    let themeViewModel = ThemeViewModel()
    
    return SimplifiedSharingView(
        photoViewModel: photoViewModel,
        themeViewModel: themeViewModel
    )
    .environment(\.theme, themeViewModel.colors)
}
