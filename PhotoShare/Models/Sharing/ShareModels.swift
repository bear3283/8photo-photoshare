import Foundation
import SwiftUI

// MARK: - 공유 방향 (8방향) - 우선순위: 위아래왼오른 후 대각선
enum ShareDirection: String, CaseIterable, Identifiable, Codable {
    case top = "top"
    case bottom = "bottom"
    case left = "left"
    case right = "right"
    case topLeft = "topLeft"
    case topRight = "topRight"
    case bottomLeft = "bottomLeft"
    case bottomRight = "bottomRight"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .top: return "위"
        case .topRight: return "우상"
        case .right: return "오른쪽"
        case .bottomRight: return "우하"
        case .bottom: return "아래"
        case .bottomLeft: return "좌하"
        case .left: return "왼쪽"
        case .topLeft: return "좌상"
        }
    }
    
    var icon: String {
        switch self {
        case .top: return "⬆️"
        case .topRight: return "↗️"
        case .right: return "➡️"
        case .bottomRight: return "↘️"
        case .bottom: return "⬇️"
        case .bottomLeft: return "↙️"
        case .left: return "⬅️"
        case .topLeft: return "↖️"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .top: return "arrow.up"
        case .topRight: return "arrow.up.right"
        case .right: return "arrow.right"
        case .bottomRight: return "arrow.down.right"
        case .bottom: return "arrow.down"
        case .bottomLeft: return "arrow.down.left"
        case .left: return "arrow.left"
        case .topLeft: return "arrow.up.left"
        }
    }
    
    var angle: Angle {
        switch self {
        case .top: return .degrees(0)
        case .topRight: return .degrees(45)
        case .right: return .degrees(90)
        case .bottomRight: return .degrees(135)
        case .bottom: return .degrees(180)
        case .bottomLeft: return .degrees(225)
        case .left: return .degrees(270)
        case .topLeft: return .degrees(315)
        }
    }
    
    var offsetMultiplier: (x: Double, y: Double) {
        switch self {
        case .top: return (0, -1)
        case .topRight: return (1, -1)
        case .right: return (1, 0)
        case .bottomRight: return (1, 1)
        case .bottom: return (0, 1)
        case .bottomLeft: return (-1, 1)
        case .left: return (-1, 0)
        case .topLeft: return (-1, -1)
        }
    }
}

// MARK: - 공유 대상자
struct ShareRecipient: Identifiable {
    let id = UUID()
    var name: String
    var direction: ShareDirection
    var color: String // 색상 코드
    var createdAt: Date = Date()
    
    init(name: String, direction: ShareDirection) {
        self.name = name
        self.direction = direction
        self.color = Self.generateColor(for: direction)
    }
    
    private static func generateColor(for direction: ShareDirection) -> String {
        switch direction {
        case .top: return "#E85A5A"        // 상: 부드러운 빨강 (Spring 톤)
        case .topRight: return "#E87A3E"   // 우상: 따뜻한 주황 (Spring 톤)
        case .right: return "#D4A65A"      // 우: 차분한 황금 (Spring 톤)
        case .bottomRight: return "#6BB26B" // 우하: 자연스러운 녹색 (Spring 톤)
        case .bottom: return "#4A8FB3"     // 하: 부드러운 파랑 (Spring 톤)
        case .bottomLeft: return "#7A6BB2" // 좌하: 차분한 보라 (Spring 톤)
        case .left: return "#B26BA8"       // 좌: 부드러운 자주 (Spring 톤)
        case .topLeft: return "#E85A99"    // 좌상: 자연스러운 분홍 (Spring 톤)
        }
    }
    
    var swiftUIColor: Color {
        Color(hex: color) ?? .blue
    }
}

// MARK: - 임시 앨범
struct TemporaryAlbum: Identifiable {
    let id = UUID()
    let recipient: ShareRecipient
    var photos: [PhotoItem] = []
    var createdAt: Date = Date()
    
    var isEmpty: Bool { photos.isEmpty }
    var photoCount: Int { photos.count }
    
    mutating func addPhoto(_ photo: PhotoItem) {
        // 중복 방지
        if !photos.contains(where: { $0.id == photo.id }) {
            photos.append(photo)
        }
    }
    
    mutating func removePhoto(_ photo: PhotoItem) {
        photos.removeAll { $0.id == photo.id }
    }
}

// MARK: - 공유 세션
struct ShareSession: Identifiable {
    let id = UUID()
    var selectedDate: Date
    var recipients: [ShareRecipient] = []
    var temporaryAlbums: [TemporaryAlbum] = []
    var totalPhotosShared: Int = 0
    var createdAt: Date = Date()
    var status: ShareSessionStatus = .setup
    
    enum ShareSessionStatus: String, CaseIterable {
        case setup = "setup"
        case distributing = "distributing"
        case ready = "ready"
        case sharing = "sharing"
        case completed = "completed"
        case cancelled = "cancelled"
    }
    
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
    }
    
    mutating func addRecipient(_ recipient: ShareRecipient) {
        recipients.append(recipient)
        temporaryAlbums.append(TemporaryAlbum(recipient: recipient))
    }
    
    mutating func removeRecipient(_ recipient: ShareRecipient) {
        recipients.removeAll { $0.id == recipient.id }
        temporaryAlbums.removeAll { $0.recipient.id == recipient.id }
    }
    
    mutating func addPhotoToRecipient(photo: PhotoItem, recipientId: UUID) {
        if let index = temporaryAlbums.firstIndex(where: { $0.recipient.id == recipientId }) {
            temporaryAlbums[index].addPhoto(photo)
        }
    }
    
    func getAlbum(for recipient: ShareRecipient) -> TemporaryAlbum? {
        return temporaryAlbums.first { $0.recipient.id == recipient.id }
    }
    
    var isReadyToShare: Bool {
        // 개선: 최소 하나의 앨범에 사진이 있으면 공유 가능
        return !temporaryAlbums.isEmpty && temporaryAlbums.contains { !$0.isEmpty }
    }
    
    var hasDistributedPhotos: Bool {
        return temporaryAlbums.reduce(0) { $0 + $1.photoCount } > 0
    }
    
    var distributedPhotosCount: Int {
        return temporaryAlbums.reduce(0) { $0 + $1.photoCount }
    }
}

// MARK: - 드래그 상태
struct DragState {
    var isDragging: Bool = false
    var currentPhoto: PhotoItem?
    var dragOffset: CGSize = .zero
    var targetDirection: ShareDirection?
    var startPosition: CGPoint = .zero
    
    mutating func reset() {
        isDragging = false
        currentPhoto = nil
        dragOffset = .zero
        targetDirection = nil
        startPosition = .zero
    }
}

// MARK: - 공유 통계
struct ShareStatistics {
    var totalSessions: Int = 0
    var totalPhotosShared: Int = 0
    var favoriteDirection: ShareDirection?
    var averageRecipientsPerSession: Double = 0
    
    static let empty = ShareStatistics()
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview Helpers
extension ShareRecipient {
    static let sampleRecipients: [ShareRecipient] = [
        ShareRecipient(name: "친구1", direction: .top),
        ShareRecipient(name: "친구2", direction: .right),
        ShareRecipient(name: "친구3", direction: .bottom),
        ShareRecipient(name: "친구4", direction: .left)
    ]
}

extension ShareSession {
    static let sampleSession: ShareSession = {
        var session = ShareSession(selectedDate: Date())
        session.recipients = ShareRecipient.sampleRecipients
        session.temporaryAlbums = session.recipients.map { TemporaryAlbum(recipient: $0) }
        return session
    }()
}
