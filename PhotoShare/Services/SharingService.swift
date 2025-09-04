import Foundation
import SwiftUI
import UIKit
import Photos

// MARK: - Sharing Service Protocol
protocol SharingServiceProtocol {
    func sharePhotos(_ photos: [PhotoItem], withRecipientName name: String) async -> Bool
    func shareAlbums(_ albums: [TemporaryAlbum]) async -> SharingResult
}

// MARK: - Sharing Result
struct SharingResult {
    let successful: Int
    let failed: Int
    let total: Int
    let errors: [SharingError]
    
    var isSuccess: Bool { successful > 0 && failed == 0 }
    var hasPartialSuccess: Bool { successful > 0 && failed > 0 }
}

// MARK: - Sharing Error
enum SharingError: Error, LocalizedError {
    case noPhotos
    case userCancelled
    case serviceUnavailable
    case permissionDenied
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .noPhotos:
            return "공유할 사진이 없습니다"
        case .userCancelled:
            return "사용자가 공유를 취소했습니다"
        case .serviceUnavailable:
            return "공유 서비스를 사용할 수 없습니다"
        case .permissionDenied:
            return "공유 권한이 거부되었습니다"
        case .unknown(let message):
            return "알 수 없는 오류: \(message)"
        }
    }
}

// MARK: - Sharing Service Implementation
final class SharingService: SharingServiceProtocol {
    private weak var rootViewController: UIViewController?
    
    init(rootViewController: UIViewController? = nil) {
        if let rootVC = rootViewController {
            self.rootViewController = rootVC
        } else {
            Task { @MainActor in
                self.rootViewController = Self.getRootViewController()
            }
        }
    }
    
    // MARK: - Public Methods
    
    @MainActor
    func sharePhotos(_ photos: [PhotoItem], withRecipientName name: String) async -> Bool {
        guard let rootVC = rootViewController ?? Self.getRootViewController() else { return false }
        
        print("📤 공유 시작: \(name)에게 \(photos.count)장 사진")
        
        // UIImage 배열로 변환
        let images = photos.compactMap { $0.image }
        guard !images.isEmpty else { return false }
        
        return await withCheckedContinuation { continuation in
            let activityVC = createActivityViewController(
                for: images,
                recipientName: name
            )
            
            // Completion handler 설정
            activityVC.completionWithItemsHandler = { activityType, completed, items, error in
                if let error = error {
                    print("❌ 공유 오류: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                } else if completed {
                    print("✅ 공유 완료: \(name)")
                    continuation.resume(returning: true)
                } else {
                    print("📝 공유 취소: \(name)")
                    continuation.resume(returning: false)
                }
            }
            
            // iPad에서 popover 설정
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(
                    x: rootVC.view.bounds.midX,
                    y: rootVC.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true)
        }
    }
    
    func shareAlbums(_ albums: [TemporaryAlbum]) async -> SharingResult {
        var successful = 0
        var failed = 0
        var errors: [SharingError] = []
        
        let nonEmptyAlbums = albums.filter { !$0.isEmpty }
        
        for album in nonEmptyAlbums {
            do {
                let success = await sharePhotos(album.photos, withRecipientName: album.recipient.name)
                if success {
                    successful += 1
                } else {
                    failed += 1
                    errors.append(.userCancelled)
                }
                
                // 연속 공유 간 짧은 딜레이
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5초
                
            } catch {
                failed += 1
                errors.append(.unknown(error.localizedDescription))
            }
        }
        
        return SharingResult(
            successful: successful,
            failed: failed,
            total: nonEmptyAlbums.count,
            errors: errors
        )
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func createActivityViewController(
        for images: [UIImage],
        recipientName: String
    ) -> UIActivityViewController {
        
        // 공유할 아이템 준비
        var shareItems: [Any] = images
        
        // 메시지 추가
        let message = "📸 \(recipientName)님과 공유하는 사진들입니다 (\(images.count)장)"
        shareItems.append(message)
        
        let activityVC = UIActivityViewController(
            activityItems: shareItems,
            applicationActivities: nil
        )
        
        // 제외할 액티비티 타입들 (선택적)
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks
        ]
        
        return activityVC
    }
    
    @MainActor
    private static func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            return nil
        }
        
        return windowScene.windows.first?.rootViewController
    }
}

// MARK: - SwiftUI Integration

/// SwiftUI에서 공유 기능을 사용하기 위한 View Modifier
struct ShareSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let photos: [PhotoItem]
    let recipientName: String
    let onCompletion: (Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                ActivityViewController(
                    photos: photos,
                    recipientName: recipientName,
                    onCompletion: onCompletion
                )
            }
    }
}

extension View {
    func shareSheet(
        isPresented: Binding<Bool>,
        photos: [PhotoItem],
        recipientName: String,
        onCompletion: @escaping (Bool) -> Void = { _ in }
    ) -> some View {
        modifier(ShareSheetModifier(
            isPresented: isPresented,
            photos: photos,
            recipientName: recipientName,
            onCompletion: onCompletion
        ))
    }
}

// MARK: - UIViewControllerRepresentable for SwiftUI

struct ActivityViewController: UIViewControllerRepresentable {
    let photos: [PhotoItem]
    let recipientName: String
    let onCompletion: (Bool) -> Void
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let images = photos.compactMap { $0.image }
        let message = "📸 \(recipientName)님과 공유하는 사진들입니다 (\(images.count)장)"
        
        let shareItems: [Any] = images + [message]
        
        let activityVC = UIActivityViewController(
            activityItems: shareItems,
            applicationActivities: nil
        )
        
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks
        ]
        
        activityVC.completionWithItemsHandler = { _, completed, _, error in
            DispatchQueue.main.async {
                if error != nil {
                    onCompletion(false)
                } else {
                    onCompletion(completed)
                }
            }
        }
        
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview Helpers

#if DEBUG
final class MockSharingService: SharingServiceProtocol {
    func sharePhotos(_ photos: [PhotoItem], withRecipientName name: String) async -> Bool {
        print("🧪 Mock 공유: \(name)에게 \(photos.count)장")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return true
    }
    
    func shareAlbums(_ albums: [TemporaryAlbum]) async -> SharingResult {
        let nonEmpty = albums.filter { !$0.isEmpty }
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        return SharingResult(
            successful: nonEmpty.count,
            failed: 0,
            total: nonEmpty.count,
            errors: []
        )
    }
}
#endif