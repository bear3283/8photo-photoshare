//
//  PhotoShareApp.swift
//  PhotoShare
//
//  Photo sharing app - standalone version
//

import SwiftUI

@main
struct PhotoShareApp: App {
    @StateObject private var onboardingManager = OnboardingManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingManager.isOnboardingCompleted {
                    ContentView()
                } else {
                    SimpleOnboardingView()
                        .environmentObject(onboardingManager)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: onboardingManager.isOnboardingCompleted)
        }
    }
}