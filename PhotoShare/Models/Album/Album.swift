import Foundation
import Photos
import UIKit

// MARK: - Album Types
enum AlbumType: CaseIterable {
    case system        // PHAssetCollection 시스템 앨범
    case user          // PHAssetCollection 사용자 앨범  
    case personal      // 앱 내부 커스텀 앨범
    
    var displayName: String {
        switch self {
        case .system: return "시스템 앨범"
        case .user: return "사용자 앨범"
        case .personal: return "개인 앨범"
        }
    }
}

// MARK: - Album Model
struct Album: Identifiable {
    let id: String
    let name: String
    let type: AlbumType
    let assetCount: Int
    let coverImage: UIImage?
    let createdDate: Date
    
    // PHAssetCollection 관련
    let assetCollection: PHAssetCollection?
    let localIdentifier: String?
    
    // PersonalAlbum 관련 (앱 내부 커스텀 앨범)
    let personalAlbum: PersonalAlbum?
    
    init(from assetCollection: PHAssetCollection, coverImage: UIImage? = nil) {
        self.id = assetCollection.localIdentifier
        self.name = assetCollection.localizedTitle ?? "이름 없음"
        self.type = assetCollection.assetCollectionType == .smartAlbum ? .system : .user
        self.assetCount = assetCollection.estimatedAssetCount == NSNotFound ? 0 : assetCollection.estimatedAssetCount
        self.coverImage = coverImage
        self.createdDate = assetCollection.startDate ?? Date()
        self.assetCollection = assetCollection
        self.localIdentifier = assetCollection.localIdentifier
        self.personalAlbum = nil
    }
    
    init(from personalAlbum: PersonalAlbum, coverImage: UIImage? = nil) {
        self.id = personalAlbum.id.uuidString
        self.name = personalAlbum.name
        self.type = .personal
        self.assetCount = personalAlbum.photoCount
        self.coverImage = coverImage ?? personalAlbum.displayCoverImage
        self.createdDate = personalAlbum.createdDate
        self.assetCollection = nil
        self.localIdentifier = nil
        self.personalAlbum = personalAlbum
    }
    
    // MARK: - Helper Properties
    var isSystemAlbum: Bool { type == .system }
    var isUserAlbum: Bool { type == .user }
    var isPersonalAlbum: Bool { type == .personal }
    var isEmpty: Bool { assetCount == 0 }
    
    var subtitle: String {
        let countText = assetCount == 1 ? "1장" : "\(assetCount)장"
        return "\(countText) · \(type.displayName)"
    }
    
    var iconName: String {
        switch type {
        case .system:
            // 시스템 앨범별 아이콘
            if name.contains("즐겨찾기") || name.contains("Favorites") {
                return "heart.fill"
            } else if name.contains("최근") || name.contains("Recent") {
                return "clock.fill"
            } else if name.contains("셀피") || name.contains("Selfie") {
                return "person.crop.circle.fill"
            } else if name.contains("스크린샷") || name.contains("Screenshot") {
                return "camera.viewfinder"
            } else {
                return "folder.fill"
            }
        case .user:
            return "folder"
        case .personal:
            return "folder.badge.plus"
        }
    }
    
    var sortPriority: Int {
        switch type {
        case .system: return 1
        case .user: return 2  
        case .personal: return 3
        }
    }
}

// MARK: - Album Section for UI
struct AlbumSection: Identifiable {
    let id = UUID()
    let type: AlbumType
    let title: String
    let albums: [Album]
    
    var isEmpty: Bool { albums.isEmpty }
    var count: Int { albums.count }
}

// MARK: - Smart Album Types
enum SmartAlbumType: String, CaseIterable {
    case favorites = "Favorites"
    case recentlyAdded = "RecentlyAdded" 
    case recentlyDeleted = "RecentlyDeleted"
    case screenshots = "Screenshots"
    case selfies = "Selfies"
    case panoramas = "Panoramas"
    case videos = "Videos"
    case timelapses = "Timelapses"
    case slowmo = "SloMo"
    case bursts = "Bursts"
    case portraits = "DepthEffect"
    case livePhotos = "LivePhotos"
    
    var subtype: PHAssetCollectionSubtype {
        switch self {
        case .favorites: return .smartAlbumFavorites
        case .recentlyAdded: return .smartAlbumRecentlyAdded
        case .recentlyDeleted: return .smartAlbumAllHidden
        case .screenshots: return .smartAlbumScreenshots
        case .selfies: return .smartAlbumSelfPortraits
        case .panoramas: return .smartAlbumPanoramas
        case .videos: return .smartAlbumVideos
        case .timelapses: return .smartAlbumTimelapses
        case .slowmo: return .smartAlbumSlomoVideos
        case .bursts: return .smartAlbumBursts
        case .portraits: return .smartAlbumDepthEffect
        case .livePhotos: return .smartAlbumLivePhotos
        }
    }
    
    var displayName: String {
        switch self {
        case .favorites: return "즐겨찾기"
        case .recentlyAdded: return "최근 항목"
        case .recentlyDeleted: return "최근 삭제된 항목"
        case .screenshots: return "스크린샷"
        case .selfies: return "셀피"
        case .panoramas: return "파노라마"
        case .videos: return "비디오"
        case .timelapses: return "타임랩스"
        case .slowmo: return "슬로모"
        case .bursts: return "연속촬영"
        case .portraits: return "인물"
        case .livePhotos: return "Live Photos"
        }
    }
    
    var isImportant: Bool {
        switch self {
        case .favorites, .recentlyAdded, .screenshots, .selfies:
            return true
        default:
            return false
        }
    }
}