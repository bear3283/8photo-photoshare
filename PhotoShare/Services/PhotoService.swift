import Foundation
import Photos
import UIKit

// Use existing constants from PhotoConstants and PerformanceConstants

// MARK: - Image Loading Context
enum ImageLoadingContext: Hashable {
    case thumbnail
    case fullscreen
    
    var targetSize: CGSize {
        switch self {
        case .thumbnail:
            return CGSize(width: 500, height: 500)
        case .fullscreen:
            return CGSize(width: PhotoConstants.maxImageSize, height: PhotoConstants.maxImageSize)
        }
    }
    
    var requestOptions: PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        switch self {
        case .thumbnail:
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
        case .fullscreen:
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
        }
        
        return options
    }
}

// MARK: - PhotoService Protocol
protocol PhotoServiceProtocol {
    func requestPhotoPermission() async -> Bool
    func loadPhotos(for date: Date) async -> [PhotoItem]
    func loadImage(for asset: PHAsset, context: ImageLoadingContext) async -> UIImage?
    func toggleFavorite(for asset: PHAsset) async -> Bool
    func savePhotoToCameraRoll(_ asset: PHAsset) async -> Bool
    func deletePhoto(_ asset: PHAsset) async -> Bool
}

// MARK: - PhotoService Implementation
final class PhotoService: PhotoServiceProtocol {
    private let imageManager = PHCachingImageManager()
    private let imageCache = NSCache<NSString, UIImage>()
    private let accessQueue = DispatchQueue(label: "PhotoService.access", attributes: .concurrent)
    
    init() {
        setupImageCache()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupImageCache() {
        imageCache.countLimit = PhotoConstants.imageCacheLimit
        imageCache.totalCostLimit = 100 * 1024 * 1024 // 100MB limit
        
        // Handle memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    // MARK: - Permission Management
    func requestPhotoPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return newStatus == .authorized || newStatus == .limited
        default:
            return false
        }
    }
    
    // MARK: - Photo Loading (Memory Safe Version)
    func loadPhotos(for date: Date) async -> [PhotoItem] {
        let dateKey = DateFormatter.photoTitle.string(from: date)
        
        print("📸 사진 로딩 시작: \(dateKey)")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            print("❌ 날짜 계산 실패")
            return []
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(
            format: "creationDate >= %@ AND creationDate < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        guard assets.count > 0 else {
            print("📭 선택한 날짜에 사진 없음: \(dateKey)")
            return []
        }
        
        // Convert PHAssets to array
        let assetArray = (0..<assets.count).map { assets.object(at: $0) }
        print("🔍 발견된 사진: \(assetArray.count)장")
        
        // Memory-safe sequential loading
        var photoItems: [PhotoItem] = []
        photoItems.reserveCapacity(assetArray.count)
        
        // Process assets sequentially to avoid memory issues
        for (index, asset) in assetArray.enumerated() {
            // Enhanced asset validation to prevent crashes
            guard !asset.localIdentifier.isEmpty,
                  asset.localIdentifier.count > 0 else {
                print("⚠️ Invalid PHAsset at index \(index), skipping")
                continue
            }
            
            let image = await loadImage(for: asset, context: .thumbnail)
            
            // Safe date extraction
            let creationDate = asset.creationDate ?? date
            
            let photoItem = PhotoItem(
                asset: asset,
                image: image,
                dateCreated: creationDate
            )
            
            photoItems.append(photoItem)
        }
        
        // Sort by creation date (newest first)
        photoItems.sort { $0.dateCreated > $1.dateCreated }
        
        let loadTime = CFAbsoluteTimeGetCurrent() - startTime
        print("⚡ 사진 로딩 완료: \(photoItems.count)장 (\(String(format: "%.2f", loadTime))초)")
        
        return photoItems
    }
    
    // MARK: - Image Loading (Memory Safe Version)
    func loadImage(for asset: PHAsset, context: ImageLoadingContext) async -> UIImage? {
        // Enhanced asset validation to prevent crashes
        guard !asset.localIdentifier.isEmpty,
              asset.localIdentifier.count > 0 else {
            print("❌ Invalid asset identifier for image loading")
            return nil
        }
        
        let cacheKey = "\(asset.localIdentifier)_\(context)"
        
        // Check cache first
        if let cachedImage = imageCache.object(forKey: cacheKey as NSString) {
            return cachedImage
        }
        
        // Simple and safe image loading without continuation issues
        let image = await withCheckedContinuation { (continuation: CheckedContinuation<UIImage?, Never>) in
            let requestOptions = context.requestOptions
            let targetSize = context.targetSize
            
            requestOptions.isNetworkAccessAllowed = true
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode = .fastFormat // Fast delivery to avoid multiple callbacks
            
            if #available(iOS 13.0, *) {
                requestOptions.version = .current
            }
            
            var hasCompleted = false
            let completionLock = NSLock()
            
            // Set up timeout
            DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
                completionLock.lock()
                if !hasCompleted {
                    hasCompleted = true
                    completionLock.unlock()
                    continuation.resume(returning: nil)
                } else {
                    completionLock.unlock()
                }
            }
            
            // Request image
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: requestOptions
            ) { image, info in
                completionLock.lock()
                
                guard !hasCompleted else {
                    completionLock.unlock()
                    return
                }
                
                // Check for errors
                if let error = info?[PHImageErrorKey] as? Error {
                    print("❌ 이미지 로딩 에러: \(error.localizedDescription)")
                    hasCompleted = true
                    completionLock.unlock()
                    continuation.resume(returning: nil)
                    return
                }
                
                // Check if cancelled
                if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                    hasCompleted = true
                    completionLock.unlock()
                    continuation.resume(returning: nil)
                    return
                }
                
                // Accept the image
                hasCompleted = true
                completionLock.unlock()
                continuation.resume(returning: image)
            }
        }
        
        // Cache the result if successful
        if let image = image {
            let cost = Int(image.size.width * image.size.height * 4) // Approximate memory cost
            imageCache.setObject(image, forKey: cacheKey as NSString, cost: cost)
        }
        
        return image
    }
    
    // MARK: - Photo Operations
    func toggleFavorite(for asset: PHAsset) async -> Bool {
        // Check if we have write permissions
        let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard authorizationStatus == .authorized else {
            print("❌ Insufficient permissions to toggle favorite: \(authorizationStatus)")
            return false
        }
        
        let originalState = asset.isFavorite
        print("🔄 Toggling favorite for asset: \(asset.localIdentifier) from \(originalState) to \(!originalState)")
        
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest(for: asset)
                request.isFavorite = !originalState
                print("📝 Change request created: setting isFavorite to \(!originalState)")
            }) { success, error in
                if let error = error {
                    print("❌ Failed to toggle favorite: \(error.localizedDescription)")
                    if let nsError = error as? NSError {
                        print("   Error domain: \(nsError.domain), code: \(nsError.code)")
                    }
                } else if success {
                    print("✅ Successfully toggled favorite: \(asset.localIdentifier) -> \(!originalState)")
                } else {
                    print("⚠️ Toggle favorite returned false but no error")
                }
                continuation.resume(returning: success)
            }
        }
    }
    
    func savePhotoToCameraRoll(_ asset: PHAsset) async -> Bool {
        return await withCheckedContinuation { continuation in
            let options = PHContentEditingInputRequestOptions()
            options.isNetworkAccessAllowed = true
            
            asset.requestContentEditingInput(with: options) { editingInput, _ in
                guard let input = editingInput,
                      let imageURL = input.fullSizeImageURL else {
                    continuation.resume(returning: false)
                    return
                }
                
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: imageURL)
                }) { success, error in
                    if let error = error {
                        print("❌ Failed to save photo: \(error.localizedDescription)")
                    }
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    func deletePhoto(_ asset: PHAsset) async -> Bool {
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets([asset] as NSArray)
            }) { success, error in
                if let error = error {
                    print("❌ Failed to delete photo: \(error.localizedDescription)")
                }
                continuation.resume(returning: success)
            }
        }
    }
    
    // MARK: - Cache Management
    func clearImageCache() {
        accessQueue.async(flags: .barrier) { [weak self] in
            self?.imageCache.removeAllObjects()
            DispatchQueue.main.async {
                print("🗑️ 이미지 캐시 정리 완료")
            }
        }
    }
    
    func getCacheInfo() -> (count: Int, cost: Int) {
        return (count: imageCache.countLimit, cost: imageCache.totalCostLimit)
    }
    
    private func handleMemoryWarning() {
        print("⚠️ 메모리 경고 - 캐시 정리 시작")
        
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Aggressively clear cache on memory warnings
            self.imageManager.stopCachingImagesForAllAssets()
            self.imageCache.removeAllObjects()
            
            DispatchQueue.main.async {
                print("💾 메모리 경고 캐시 정리 완료")
            }
        }
    }
}
