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
        SimplifiedSharingView(
            photoViewModel: photoViewModel,
            themeViewModel: themeViewModel
        )
        .environment(\.theme, themeViewModel.colors)
        .onAppear {
            print("🏠 ContentView appeared - 앱 시작")
        }
    }
}

#Preview {
    ContentView()
}
