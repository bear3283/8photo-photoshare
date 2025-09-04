import SwiftUI

// MARK: - Spring Theme Implementation
struct SpringThemeColors: ThemeColors {
    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.1, green: 0.6, blue: 0.8)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var secondaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.3, green: 0.6, blue: 0.5), Color(red: 0.2, green: 0.5, blue: 0.6)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var accentColor: Color {
        Color(red: 0.2, green: 0.7, blue: 0.4)
    }
    
    var primaryBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 1.0, blue: 0.95),
                Color(red: 0.95, green: 0.98, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var secondaryBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.98, blue: 0.95),
                Color(red: 0.92, green: 0.96, blue: 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var cardBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.97, green: 0.99, blue: 0.96),
                Color(red: 0.94, green: 0.97, blue: 0.99)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var overlayBackground: Color {
        Color.black.opacity(0.4)
    }
    
    var primaryText: Color {
        Color(red: 0.3, green: 0.6, blue: 0.5)
    }
    
    var secondaryText: Color {
        Color(red: 0.4, green: 0.6, blue: 0.5)
    }
    
    var accentText: LinearGradient {
        primaryGradient
    }
    
    var buttonBackground: LinearGradient {
        primaryBackground
    }
    
    var buttonBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.7, blue: 0.4).opacity(0.3),
                Color(red: 0.1, green: 0.6, blue: 0.8).opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var favoriteActive: Color {
        .yellow
    }
    
    var favoriteInactive: Color {
        Color.yellow.opacity(0.4)
    }
    
    var saveColor: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.2, green: 0.8, blue: 0.4), Color(red: 0.1, green: 0.7, blue: 0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var deleteColor: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.6, blue: 0.6), Color(red: 0.9, green: 0.4, blue: 0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var primaryShadow: Color {
        Color(red: 0.1, green: 0.6, blue: 0.8).opacity(0.15)
    }
    
    var secondaryShadow: Color {
        Color(red: 0.1, green: 0.7, blue: 0.4).opacity(0.1)
    }
}