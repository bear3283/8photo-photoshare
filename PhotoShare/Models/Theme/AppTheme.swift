import Foundation

// MARK: - AppTheme Enum
enum AppTheme: String, CaseIterable {
    case spring = "spring"
    case sleek = "sleek"
    
    var displayName: String {
        switch self {
        case .spring: return "봄 테마"
        case .sleek: return "시크 테마"
        }
    }
}