import Foundation
import UIKit

// MARK: - PersonalAlbum Model
struct PersonalAlbum: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id = UUID()
    let name: String
    let createdDate: Date
    var photoItems: [AlbumPhotoItem]
    var coverImage: UIImage?
    
    enum CodingKeys: String, CodingKey {
        case id, name, createdDate, photoItems
    }
    
    // MARK: - Computed Properties
    var photoCount: Int {
        return photoItems.count
    }
    
    var displayCoverImage: UIImage? {
        return coverImage ?? photoItems.first?.image
    }
}
