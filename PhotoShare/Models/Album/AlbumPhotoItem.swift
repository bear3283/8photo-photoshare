import Foundation
import UIKit

// MARK: - AlbumPhotoItem Model
struct AlbumPhotoItem: Identifiable, Codable, Equatable, Hashable {
    let id = UUID()
    let assetLocalIdentifier: String
    let dateAdded: Date
    var image: UIImage?
    
    enum CodingKeys: String, CodingKey {
        case id, assetLocalIdentifier, dateAdded
    }
    
    // MARK: - Equatable & Hashable Conformance
    static func == (lhs: AlbumPhotoItem, rhs: AlbumPhotoItem) -> Bool {
        return lhs.id == rhs.id && 
               lhs.assetLocalIdentifier == rhs.assetLocalIdentifier &&
               lhs.dateAdded == rhs.dateAdded
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(assetLocalIdentifier)
        hasher.combine(dateAdded)
    }
}