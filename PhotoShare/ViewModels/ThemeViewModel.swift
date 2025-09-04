import Foundation
import Combine

// MARK: - ThemeViewModel State
struct ThemeViewModelState {
    var currentTheme: AppTheme = .spring
    var availableThemes: [AppTheme] = []
}

// MARK: - ThemeViewModel Actions
enum ThemeViewModelAction {
    case loadTheme
    case setTheme(AppTheme)
    case loadAvailableThemes
}

// MARK: - ThemeViewModel
@MainActor
final class ThemeViewModel: ViewModelProtocol {
    typealias State = ThemeViewModelState
    typealias Action = ThemeViewModelAction
    
    @Published private(set) var state = ThemeViewModelState()
    
    private let themeService: ThemeServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var currentTheme: AppTheme { state.currentTheme }
    var availableThemes: [AppTheme] { state.availableThemes }
    
    var colors: ThemeColors {
        switch state.currentTheme {
        case .spring:
            return SpringThemeColors()
        case .sleek:
            return SleekThemeColors()
        }
    }
    
    // MARK: - Initialization
    init(themeService: ThemeServiceProtocol = ThemeService()) {
        self.themeService = themeService
        setupBindings()
    }
    
    // MARK: - Public Interface
    func send(_ action: Action) {
        Task { @MainActor in
            await handleAction(action)
        }
    }
    
    func sendAsync(_ action: Action) async {
        await handleAction(action)
    }
    
    // MARK: - Convenience Methods
    func setTheme(_ theme: AppTheme) {
        send(.setTheme(theme))
    }
    
    // MARK: - Action Handling
    private func handleAction(_ action: Action) async {
        switch action {
        case .loadTheme:
            await loadSavedTheme()
            
        case .setTheme(let theme):
            await setCurrentTheme(theme)
            
        case .loadAvailableThemes:
            await loadAvailableThemes()
        }
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Load theme and available themes on initialization
        Task {
            await loadSavedTheme()
            await loadAvailableThemes()
        }
    }
    
    private func loadSavedTheme() async {
        let savedTheme = themeService.loadSavedTheme()
        state.currentTheme = savedTheme
    }
    
    private func setCurrentTheme(_ theme: AppTheme) async {
        state.currentTheme = theme
        themeService.saveTheme(theme)
    }
    
    private func loadAvailableThemes() async {
        let themes = themeService.getAvailableThemes()
        state.availableThemes = themes
    }
}