import Foundation
import Combine

// MARK: - Base ViewModel Protocol
@MainActor
protocol ViewModelProtocol: ObservableObject {
    associatedtype State
    associatedtype Action
    
    var state: State { get }
    func send(_ action: Action)              // Synchronous action dispatch
    func sendAsync(_ action: Action) async   // Asynchronous action dispatch
}

// MARK: - Default Implementation
extension ViewModelProtocol {
    /// Default async implementation that wraps synchronous send
    func sendAsync(_ action: Action) async {
        send(action)
    }
}

// MARK: - Loadable State Protocol
protocol LoadableStateProtocol {
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
}

// MARK: - Generic Loading State
struct LoadingState: LoadableStateProtocol {
    var isLoading: Bool = false
    var errorMessage: String? = nil
}

// MARK: - Result Extensions for ViewModels
extension Result {
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
    
    var isFailure: Bool {
        return !isSuccess
    }
    
    var error: Failure? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
}