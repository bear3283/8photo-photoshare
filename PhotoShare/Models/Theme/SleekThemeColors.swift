import SwiftUI

// MARK: - Sleek Theme Implementation
struct SleekThemeColors: ThemeColors {
    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.2, green: 0.6, blue: 1.0)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var secondaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.4, green: 0.4, blue: 0.4), Color(red: 0.5, green: 0.5, blue: 0.5)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var accentColor: Color {
        Color(red: 0.0, green: 0.48, blue: 1.0) // System blue
    }
    
    var primaryBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.05),
                Color(red: 0.1, green: 0.1, blue: 0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var secondaryBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.12, blue: 0.12),
                Color(red: 0.08, green: 0.08, blue: 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var cardBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.15, green: 0.15, blue: 0.15),
                Color(red: 0.12, green: 0.12, blue: 0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var overlayBackground: Color {
        Color.black.opacity(0.7)
    }
    
    var primaryText: Color {
        Color(red: 0.95, green: 0.95, blue: 0.95) // 약간 부드러운 흰색
    }
    
    var secondaryText: Color {
        Color(red: 0.8, green: 0.8, blue: 0.8) // 더 읽기 쉬운 회색
    }
    
    var accentText: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.3, green: 0.7, blue: 1.0), Color(red: 0.5, green: 0.8, blue: 1.0)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var buttonBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.2, blue: 0.2),
                Color(red: 0.15, green: 0.15, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var buttonBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.6),
                Color(red: 0.4, green: 0.4, blue: 0.4).opacity(0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var favoriteActive: Color {
        Color(red: 1.0, green: 0.8, blue: 0.0) // Golden yellow
    }
    
    var favoriteInactive: Color {
        Color.white.opacity(0.3)
    }
    
    var saveColor: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.2, green: 0.8, blue: 0.2), Color(red: 0.1, green: 0.6, blue: 0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var deleteColor: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.9, green: 0.2, blue: 0.2), Color(red: 0.7, green: 0.1, blue: 0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var primaryShadow: Color {
        Color.black.opacity(0.3)
    }
    
    var secondaryShadow: Color {
        Color.black.opacity(0.2)
    }
}