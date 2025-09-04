//
//  OptimizedPhotoItem.swift
//  Phohoto
//
//  Created by Claude on 8/7/25.
//

import Foundation
import Photos
import UIKit

// MARK: - Optimized Photo Item
/// 메모리 효율적인 사진 아이템 - 이미지를 직접 저장하지 않고 필요시 로드
struct OptimizedPhotoItem: Identifiable, Equatable {
    let id = UUID()
    let asset: PHAsset
    let dateCreated: Date
    
    // 상태 관리 (기존 PhotoItem과 호환성 유지)
    var isMarkedForDeletion = false
    var isMarkedForSaving = false
    var localFavoriteState: Bool?
    
    var isFavorite: Bool {
        return localFavoriteState ?? asset.isFavorite
    }
    
    // Equatable 구현
    static func == (lhs: OptimizedPhotoItem, rhs: OptimizedPhotoItem) -> Bool {
        return lhs.asset.localIdentifier == rhs.asset.localIdentifier
    }
}

// MARK: - Image Quality Levels
enum ImageQuality: String, CaseIterable {
    case thumbnail = "thumbnail"    // 150x150, 그리드 스크롤용
    case preview = "preview"        // 512x512, 미리보기용
    case fullSize = "fullSize"      // 원본, 상세보기/편집용
    
    var targetSize: CGSize {
        switch self {
        case .thumbnail:
            return CGSize(width: 150, height: 150)
        case .preview:
            return CGSize(width: 512, height: 512)
        case .fullSize:
            return PHImageManagerMaximumSize
        }
    }
    
    var contentMode: PHImageContentMode {
        switch self {
        case .thumbnail, .preview:
            return .aspectFill
        case .fullSize:
            return .aspectFit
        }
    }
    
    var options: PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.deliveryMode = self == .thumbnail ? .fastFormat : .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        return options
    }
}

// MARK: - Pagination Configuration
struct PaginationConfig {
    /// 디바이스별 최적화된 페이지 크기
    static let pageSize: Int = {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        if totalMemory > 6_000_000_000 { // 6GB+
            return 100
        } else if totalMemory > 3_000_000_000 { // 3GB+
            return 50
        } else {
            return 25 // 3GB 미만
        }
    }()
    
    /// 스크롤 끝에서 몇 개 전에 다음 페이지 로드를 시작할지
    static let preloadDistance: Int = max(5, pageSize / 4)
    
    /// 메모리 캐시에 유지할 최대 이미지 수
    static let memoryCacheLimit: Int = pageSize * 3
    
    /// 메모리 캐시 최대 크기 (바이트)
    static let memoryCacheSizeLimit: Int = 100 * 1024 * 1024 // 100MB
    
    /// 디스크 캐시 최대 크기 (바이트) 
    static let diskCacheSizeLimit: Int = 500 * 1024 * 1024 // 500MB
}

// MARK: - Scroll Direction
enum ScrollDirection {
    case up
    case down
    case unknown
}

// MARK: - Pagination State
struct PaginationState {
    var currentPage: Int = 0
    var totalPages: Int = 0
    var totalPhotos: Int = 0
    var isLoading: Bool = false
    var hasMorePages: Bool = true
    var errorMessage: String?
    
    var displayedPhotosCount: Int {
        return min(totalPhotos, (currentPage + 1) * PaginationConfig.pageSize)
    }
    
    var progressPercentage: Double {
        guard totalPhotos > 0 else { return 0 }
        return Double(displayedPhotosCount) / Double(totalPhotos) * 100
    }
}