import Foundation
import UIKit
import Photos

/// 프리뷰용 더미 데이터 생성
enum PreviewData {
    
    // MARK: - Album Preview Data
    static let sampleAlbums: [Album] = {
        var albums: [Album] = []
        
        // Personal Albums
        let personalAlbumNames = ["여행 사진", "가족 모임", "음식 사진", "일상", "풍경 사진"]
        for (index, name) in personalAlbumNames.enumerated() {
            let personalAlbum = PersonalAlbum(
                name: name,
                createdDate: Calendar.current.date(byAdding: .day, value: -index * 7, to: Date()) ?? Date(),
                photoItems: generateSampleAlbumPhotoItems(count: Int.random(in: 5...20)),
                coverImage: DummyImageGenerator.generateAlbumCover(albumName: name)
            )
            albums.append(Album(from: personalAlbum))
        }
        
        // User Albums (simulated)
        let userAlbumNames = ["내 앨범", "추억", "특별한 순간"]
        for (index, name) in userAlbumNames.enumerated() {
            // PersonalAlbum으로 시뮬레이션 (실제로는 PHAssetCollection이어야 함)
            let userAlbum = PersonalAlbum(
                name: name,
                createdDate: Calendar.current.date(byAdding: .month, value: -index, to: Date()) ?? Date(),
                photoItems: generateSampleAlbumPhotoItems(count: Int.random(in: 10...30)),
                coverImage: DummyImageGenerator.generateAlbumCover(albumName: name)
            )
            var album = Album(from: userAlbum)
            // type을 user로 변경하기 위해 새로 생성
            albums.append(Album(
                id: album.id,
                name: album.name,
                type: .user,
                assetCount: album.assetCount,
                coverImage: album.coverImage,
                createdDate: album.createdDate,
                assetCollection: nil,
                localIdentifier: nil,
                personalAlbum: nil
            ))
        }
        
        // System Albums (simulated)
        let systemAlbumNames = ["즐겨찾기", "최근 항목", "스크린샷", "셀피"]
        for (index, name) in systemAlbumNames.enumerated() {
            let systemAlbum = PersonalAlbum(
                name: name,
                createdDate: Calendar.current.date(byAdding: .month, value: -index * 2, to: Date()) ?? Date(),
                photoItems: generateSampleAlbumPhotoItems(count: Int.random(in: 3...15)),
                coverImage: DummyImageGenerator.generateAlbumCover(albumName: name)
            )
            var album = Album(from: systemAlbum)
            albums.append(Album(
                id: album.id,
                name: album.name,
                type: .system,
                assetCount: album.assetCount,
                coverImage: album.coverImage,
                createdDate: album.createdDate,
                assetCollection: nil,
                localIdentifier: nil,
                personalAlbum: nil
            ))
        }
        
        return albums
    }()
    
    static let sampleAlbumSections: [AlbumSection] = {
        let systemAlbums = sampleAlbums.filter { $0.type == .system }
        let userAlbums = sampleAlbums.filter { $0.type == .user }
        let personalAlbums = sampleAlbums.filter { $0.type == .personal }
        
        return [
            AlbumSection(type: .system, title: "시스템 앨범", albums: systemAlbums),
            AlbumSection(type: .user, title: "사용자 앨범", albums: userAlbums),
            AlbumSection(type: .personal, title: "개인 앨범", albums: personalAlbums)
        ].filter { !$0.isEmpty }
    }()
    
    // MARK: - Photo Preview Data
    static let samplePhotos: [PhotoItem] = {
        generateSamplePhotoItems(count: 20)
    }()
    
    private static func generateSamplePhotoItems(count: Int) -> [PhotoItem] {
        var photos: [PhotoItem] = []
        
        for i in 0..<count {
            let date = Calendar.current.date(
                byAdding: .hour,
                value: -i * Int.random(in: 1...6),
                to: Date()
            ) ?? Date()
            
            let dummyImage = DummyImageGenerator.generatePhoto(index: i)
            
            let photoItem = PhotoItem.createPreviewItem(
                image: dummyImage,
                dateCreated: date,
                isFavorite: Bool.random()
            )
            
            photos.append(photoItem)
        }
        
        return photos.sorted(by: { $0.dateCreated > $1.dateCreated })
    }
    
    private static func generateSampleAlbumPhotoItems(count: Int) -> [AlbumPhotoItem] {
        var albumItems: [AlbumPhotoItem] = []
        
        for i in 0..<count {
            let date = Calendar.current.date(
                byAdding: .hour,
                value: -i * Int.random(in: 1...6),
                to: Date()
            ) ?? Date()
            
            let dummyImage = DummyImageGenerator.generatePhoto(index: i)
            
            var albumItem = AlbumPhotoItem(
                assetLocalIdentifier: "dummy-asset-\(UUID().uuidString)",
                dateAdded: date
            )
            albumItem.image = dummyImage
            
            albumItems.append(albumItem)
        }
        
        return albumItems.sorted(by: { $0.dateAdded > $1.dateAdded })
    }
    
    private static func generateRandomLocation() -> String? {
        let locations = [
            "서울, 대한민국",
            "부산, 대한민국",
            "제주도, 대한민국",
            "경주, 대한민국",
            "강릉, 대한민국",
            "전주, 대한민국",
            nil, nil, nil // 일부는 위치 정보 없음
        ]
        return locations.randomElement() ?? nil
    }
    
    // MARK: - Theme Preview Data
    static let sampleThemeColors: ThemeColors = SpringThemeColors()
    
    // MARK: - Recipients Preview Data (for Sharing)
    static let sampleRecipients: [ShareRecipient] = [
        ShareRecipient(name: "김철수", direction: .top),
        ShareRecipient(name: "이영희", direction: .right),
        ShareRecipient(name: "박민수", direction: .bottom),
        ShareRecipient(name: "최유진", direction: .left)
    ]
    
    // MARK: - Individual Sample Objects
    static let sampleAlbum: Album = {
        let personalAlbum = PersonalAlbum(
            name: "여행 사진",
            createdDate: Date(),
            photoItems: generateSampleAlbumPhotoItems(count: 12),
            coverImage: DummyImageGenerator.generateAlbumCover(albumName: "여행 사진")
        )
        return Album(from: personalAlbum)
    }()
    
    static let sampleEmptyAlbum: Album = {
        let personalAlbum = PersonalAlbum(
            name: "빈 앨범",
            createdDate: Date(),
            photoItems: [],
            coverImage: nil
        )
        return Album(from: personalAlbum)
    }()
    
    static let samplePhoto: PhotoItem = {
        PhotoItem.createPreviewItem(
            image: DummyImageGenerator.generatePhoto(index: 0),
            dateCreated: Date(),
            isFavorite: true
        )
    }()
    
    // MARK: - Landscape Photos for Different Scenarios
    static let landscapePhotos: [PhotoItem] = {
        var photos: [PhotoItem] = []
        let landscapeTypes: [DummyImageGenerator.LandscapeType] = [.sunset, .mountain, .ocean, .forest]
        
        for (index, type) in landscapeTypes.enumerated() {
            let photo = PhotoItem.createPreviewItem(
                image: DummyImageGenerator.generateLandscapePhoto(type: type, size: CGSize(width: 400, height: 300)),
                dateCreated: Calendar.current.date(byAdding: .day, value: -index, to: Date()) ?? Date(),
                isFavorite: index % 2 == 0
            )
            photos.append(photo)
        }
        
        return photos
    }()
    
    // MARK: - View Model Helper Methods
    @MainActor
    static func createPreviewPhotoViewModel() -> PhotoViewModel {
        let viewModel = PhotoViewModel()
        
        // 더미 데이터로 상태 설정 (실제 구현에서는 내부 메서드 접근 필요)
        // 이는 프리뷰에서만 사용되므로 실제 앱에서는 정상적인 로딩 과정을 거침
        return viewModel
    }
    
    // Album view model not needed in photo sharing app
    
    @MainActor
    static func createPreviewThemeViewModel() -> ThemeViewModel {
        let viewModel = ThemeViewModel()
        return viewModel
    }
    
    // MARK: - Date Helper
    static let sampleDateRange: ClosedRange<Date> = {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        return startDate...endDate
    }()
}

// MARK: - Extensions for Preview Data
extension DummyImageGenerator.LandscapeType {
    var locationName: String {
        switch self {
        case .sunset:
            return "해운대, 부산"
        case .mountain:
            return "설악산, 강원도"
        case .ocean:
            return "제주도"
        case .forest:
            return "지리산, 전남"
        case .randomType:
            return "알 수 없는 위치"
        }
    }
}

// MARK: - Album Extension for Preview
extension Album {
    /// 프리뷰에서 더미 커버 이미지가 필요한 경우 사용
    func withDummyCover() -> Album {
        if self.coverImage != nil {
            return self
        }
        
        let dummyCover = DummyImageGenerator.generateAlbumCover(albumName: self.name)
        
        return Album(
            id: self.id,
            name: self.name,
            type: self.type,
            assetCount: self.assetCount,
            coverImage: dummyCover,
            createdDate: self.createdDate,
            assetCollection: self.assetCollection,
            localIdentifier: self.localIdentifier,
            personalAlbum: self.personalAlbum
        )
    }
}

// MARK: - Album Initializer Extensions for Preview
extension Album {
    init(
        id: String,
        name: String,
        type: AlbumType,
        assetCount: Int,
        coverImage: UIImage?,
        createdDate: Date,
        assetCollection: PHAssetCollection?,
        localIdentifier: String?,
        personalAlbum: PersonalAlbum?
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.assetCount = assetCount
        self.coverImage = coverImage
        self.createdDate = createdDate
        self.assetCollection = assetCollection
        self.localIdentifier = localIdentifier
        self.personalAlbum = personalAlbum
    }
}