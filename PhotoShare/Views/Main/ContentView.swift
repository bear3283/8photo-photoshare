//
//  ContentView.swift
//  PhotoShare
//
//  Main content view for photo sharing
//

import SwiftUI

struct ContentView: View {
    @StateObject private var photoViewModel = PhotoViewModel()
    @StateObject private var themeViewModel = ThemeViewModel()
    
    var body: some View {
        SharingView(
            photoViewModel: photoViewModel,
            themeViewModel: themeViewModel
        )
        .accentColor(themeViewModel.colors.accentColor)
        .environment(\.theme, themeViewModel.colors)
        .preferredColorScheme(themeViewModel.currentTheme == .sleek ? .dark : .light)
        .onAppear {
            print("🏠 ContentView appeared - 앱 시작")
            // Initialize photo sharing mode - SharingView handles photo loading
            photoViewModel.send(.setSharingMode(true))
        }
        .task {
            // Ensure permission check happens early
            print("🔐 ContentView task - 초기 권한 확인")
        }
    }
}

#Preview {
    ContentView()
        .environment(\.theme, PreviewData.sampleThemeColors)
}
