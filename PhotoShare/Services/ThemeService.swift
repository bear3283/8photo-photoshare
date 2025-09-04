import Foundation

// MARK: - ThemeService Protocol
protocol ThemeServiceProtocol {
    func loadSavedTheme() -> AppTheme
    func saveTheme(_ theme: AppTheme)
    func getAvailableThemes() -> [AppTheme]
}

// MARK: - ThemeService Implementation
final class ThemeService: ThemeServiceProtocol {
    private let userDefaults = UserDefaults.standard
    private let themeKey = "selectedTheme"
    
    func loadSavedTheme() -> AppTheme {
        guard let savedTheme = userDefaults.string(forKey: themeKey),
              let theme = AppTheme(rawValue: savedTheme) else {
            return .spring // Default theme
        }
        return theme
    }
    
    func saveTheme(_ theme: AppTheme) {
        userDefaults.set(theme.rawValue, forKey: themeKey)
    }
    
    func getAvailableThemes() -> [AppTheme] {
        return AppTheme.allCases
    }
}