import SwiftUI

// MARK: - ThemeColors Protocol
protocol ThemeColors {
    // Primary Colors
    var primaryGradient: LinearGradient { get }
    var secondaryGradient: LinearGradient { get }
    var accentColor: Color { get }
    
    // Background Colors
    var primaryBackground: LinearGradient { get }
    var secondaryBackground: LinearGradient { get }
    var cardBackground: LinearGradient { get }
    var overlayBackground: Color { get }
    
    // Text Colors
    var primaryText: Color { get }
    var secondaryText: Color { get }
    var accentText: LinearGradient { get }
    
    // Interactive Colors
    var buttonBackground: LinearGradient { get }
    var buttonBorder: LinearGradient { get }
    var favoriteActive: Color { get }
    var favoriteInactive: Color { get }
    
    // Status Colors
    var saveColor: LinearGradient { get }
    var deleteColor: LinearGradient { get }
    
    // Shadow Colors
    var primaryShadow: Color { get }
    var secondaryShadow: Color { get }
}

// MARK: - Theme Environment Key
private struct ThemeKey: EnvironmentKey {
    static let defaultValue: ThemeColors = SpringThemeColors()
}

extension EnvironmentValues {
    var theme: ThemeColors {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}