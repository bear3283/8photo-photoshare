import Foundation
import SwiftUI
import Combine

// MARK: - SharingViewModel State
struct SharingViewModelState: LoadableStateProtocol {
    var currentSession: ShareSession?
    var availablePhotos: [PhotoItem] = []
    var dragState: DragState = DragState()
    var isLoading: Bool = false
    var errorMessage: String? = nil
}

// MARK: - SharingViewModel Actions
enum SharingViewModelAction {
    case createSession(Date)
    case loadPhotos(for: Date)
    case addRecipient(String, ShareDirection)
    case removeRecipient(ShareRecipient)
    case startDrag(PhotoItem, CGPoint)
    case updateDrag(CGSize, CGPoint)
    case endDrag(ShareDirection?)
    case distributePhoto(PhotoItem, ShareDirection)
    case clearSession
    case shareAlbums
    case shareIndividualAlbum(TemporaryAlbum)
    case previewAlbum(TemporaryAlbum)
    case clearError
}

// MARK: - SharingViewModel
@MainActor
final class SharingViewModel: ViewModelProtocol {
    typealias State = SharingViewModelState
    typealias Action = SharingViewModelAction
    
    @Published private(set) var state = SharingViewModelState()
    
    private let photoService: PhotoServiceProtocol
    private let sharingService: SharingServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var currentSession: ShareSession? { state.currentSession }
    var availablePhotos: [PhotoItem] { state.availablePhotos }
    var dragState: DragState { state.dragState }
    var isLoading: Bool { state.isLoading }
    var errorMessage: String? { state.errorMessage }
    
    // Convenience properties
    var recipients: [ShareRecipient] { 
        state.currentSession?.recipients ?? []
    }
    
    var temporaryAlbums: [TemporaryAlbum] {
        state.currentSession?.temporaryAlbums ?? []
    }
    
    var isSessionActive: Bool {
        state.currentSession != nil
    }
    
    var canStartSharing: Bool {
        state.currentSession?.isReadyToShare ?? false
    }
    
    // MARK: - Initialization
    init(photoService: PhotoServiceProtocol = PhotoService(), 
         sharingService: SharingServiceProtocol = SharingService()) {
        self.photoService = photoService
        self.sharingService = sharingService
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
    
    // MARK: - Action Handling
    private func handleAction(_ action: Action) async {
        switch action {
        case .createSession(let date):
            await createSession(for: date)
            
        case .loadPhotos(let date):
            await loadPhotos(for: date)
            
        case .addRecipient(let name, let direction):
            await addRecipient(name: name, direction: direction)
            
        case .removeRecipient(let recipient):
            await removeRecipient(recipient)
            
        case .startDrag(let photo, let position):
            await startDrag(photo: photo, at: position)
            
        case .updateDrag(let offset, let position):
            await updateDrag(offset: offset, position: position)
            
        case .endDrag(let direction):
            await endDrag(at: direction)
            
        case .distributePhoto(let photo, let direction):
            await distributePhoto(photo, to: direction)
            
        case .clearSession:
            await clearSession()
            
        case .shareAlbums:
            await shareAlbums()
            
        case .shareIndividualAlbum(let album):
            await shareIndividualAlbum(album)
            
        case .previewAlbum(_):
            // Preview는 UI에서 처리
            break
            
        case .clearError:
            state.errorMessage = nil
        }
    }
    
    // MARK: - Private Methods
    
    private func createSession(for date: Date) async {
        print("🎯 새 공유 세션 생성: \(date)")
        state.currentSession = ShareSession(selectedDate: date)
        await loadPhotos(for: date)
    }
    
    private func loadPhotos(for date: Date) async {
        state.isLoading = true
        state.errorMessage = nil
        
        let photos = await photoService.loadPhotos(for: date)
        state.availablePhotos = photos
        state.isLoading = false
        
        print("📸 \(photos.count)개 사진 로드 완료")
    }
    
    private func addRecipient(name: String, direction: ShareDirection) async {
        guard var session = state.currentSession else { return }
        
        // 중복 방향 체크
        if session.recipients.contains(where: { $0.direction == direction }) {
            state.errorMessage = "\(direction.displayName) 방향은 이미 사용 중입니다."
            return
        }
        
        let recipient = ShareRecipient(name: name, direction: direction)
        session.addRecipient(recipient)
        state.currentSession = session
        
        print("👥 공유 대상자 추가: \(name) -> \(direction.displayName)")
    }
    
    private func removeRecipient(_ recipient: ShareRecipient) async {
        guard var session = state.currentSession else { return }
        
        session.removeRecipient(recipient)
        state.currentSession = session
        
        print("❌ 공유 대상자 제거: \(recipient.name)")
    }
    
    private func startDrag(photo: PhotoItem, at position: CGPoint) async {
        state.dragState.isDragging = true
        state.dragState.currentPhoto = photo
        state.dragState.startPosition = position
        state.dragState.dragOffset = .zero
        state.dragState.targetDirection = nil
        
        print("🎯 드래그 시작: \(photo.id)")
    }
    
    private func updateDrag(offset: CGSize, position: CGPoint) async {
        guard state.dragState.isDragging else { return }
        
        state.dragState.dragOffset = offset
        
        // 드래그 거리와 방향 계산
        let distance = sqrt(offset.width * offset.width + offset.height * offset.height)
        
        if distance > 50 { // 최소 드래그 거리
            let angle = atan2(offset.height, offset.width)
            state.dragState.targetDirection = calculateDirection(from: angle)
        } else {
            state.dragState.targetDirection = nil
        }
    }
    
    private func endDrag(at direction: ShareDirection?) async {
        defer { state.dragState.reset() }
        
        guard let photo = state.dragState.currentPhoto,
              let targetDirection = direction ?? state.dragState.targetDirection else {
            print("❌ 드래그 취소: 유효하지 않은 방향")
            return
        }
        
        await distributePhoto(photo, to: targetDirection)
    }
    
    private func distributePhoto(_ photo: PhotoItem, to direction: ShareDirection) async {
        guard var session = state.currentSession else { 
            state.errorMessage = "공유 세션이 유효하지 않습니다."
            return 
        }
        
        // 해당 방향의 대상자 찾기
        guard let recipient = session.recipients.first(where: { $0.direction == direction }) else {
            state.errorMessage = "\(direction.displayName) 방향에 공유 대상자가 없습니다."
            
            // Error haptic feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
            return
        }
        
        // Check if photo is already distributed to this recipient
        if let album = session.temporaryAlbums.first(where: { $0.recipient.id == recipient.id }),
           album.photos.contains(where: { $0.id == photo.id }) {
            print("⚠️ 사진이 이미 \(recipient.name)에게 분배됨")
            
            // Warning haptic feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
            return
        }
        
        // 임시 앨범에 사진 추가
        session.addPhotoToRecipient(photo: photo, recipientId: recipient.id)
        state.currentSession = session
        
        print("📤 사진 분배 성공: \(photo.id) -> \(recipient.name) (\(direction.displayName))")
        
        // Success haptic feedback - more satisfying
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        // Clear any previous error messages
        if state.errorMessage != nil {
            state.errorMessage = nil
        }
    }
    
    private func clearSession() async {
        state.currentSession = nil
        state.availablePhotos = []
        state.dragState.reset()
        
        print("🗑️ 공유 세션 초기화")
    }
    
    private func shareAlbums() async {
        guard let session = state.currentSession else { return }
        
        state.isLoading = true
        state.errorMessage = nil
        
        print("📤 앨범 공유 시작: \(session.temporaryAlbums.count)개 앨범")
        
        // 실제 공유 서비스 호출
        let result = await sharingService.shareAlbums(session.temporaryAlbums)
        
        state.isLoading = false
        
        // 결과 처리
        if result.isSuccess {
            // 모든 앨범 공유 성공
            if var updatedSession = state.currentSession {
                updatedSession.status = .completed
                updatedSession.totalPhotosShared = result.successful
                state.currentSession = updatedSession
            }
            print("✅ 모든 앨범 공유 완료: \(result.successful)개")
            
        } else if result.hasPartialSuccess {
            // 일부만 성공
            if var updatedSession = state.currentSession {
                updatedSession.status = .sharing // 부분 완료 상태
                updatedSession.totalPhotosShared = result.successful
                state.currentSession = updatedSession
            }
            
            state.errorMessage = "일부 앨범만 공유되었습니다 (\(result.successful)/\(result.total))"
            print("⚠️ 일부 공유 완료: \(result.successful)/\(result.total)")
            
        } else {
            // 공유 실패
            if let firstError = result.errors.first {
                state.errorMessage = firstError.localizedDescription
            } else {
                state.errorMessage = "공유에 실패했습니다"
            }
            print("❌ 공유 실패: \(result.errors.count)개 오류")
        }
        
        // 햅틱 피드백
        if result.isSuccess {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.success)
        } else if result.hasPartialSuccess {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.warning)
        } else {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.error)
        }
    }
    
    private func shareIndividualAlbum(_ album: TemporaryAlbum) async {
        guard !album.isEmpty else {
            state.errorMessage = "공유할 사진이 없습니다"
            return
        }
        
        state.isLoading = true
        state.errorMessage = nil
        
        print("📤 개별 앨범 공유: \(album.recipient.name)에게 \(album.photoCount)장")
        
        let success = await sharingService.sharePhotos(album.photos, withRecipientName: album.recipient.name)
        
        state.isLoading = false
        
        if success {
            print("✅ 개별 앨범 공유 완료: \(album.recipient.name)")
            
            // 성공 햅틱 피드백
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.success)
        } else {
            state.errorMessage = "공유에 실패했습니다"
            print("❌ 개별 앨범 공유 실패: \(album.recipient.name)")
            
            // 실패 햅틱 피드백
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.error)
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateDirection(from angle: Double) -> ShareDirection {
        let degrees = angle * 180 / .pi
        let normalizedDegrees = (degrees + 360).truncatingRemainder(dividingBy: 360)
        
        switch normalizedDegrees {
        case 337.5..<360, 0..<22.5:
            return .right
        case 22.5..<67.5:
            return .bottomRight
        case 67.5..<112.5:
            return .bottom
        case 112.5..<157.5:
            return .bottomLeft
        case 157.5..<202.5:
            return .left
        case 202.5..<247.5:
            return .topLeft
        case 247.5..<292.5:
            return .top
        case 292.5..<337.5:
            return .topRight
        default:
            return .right
        }
    }
    
    func getAvailableDirections() -> [ShareDirection] {
        let usedDirections = recipients.map { $0.direction }
        return ShareDirection.allCases.filter { !usedDirections.contains($0) }
    }
    
    func getAlbumFor(direction: ShareDirection) -> TemporaryAlbum? {
        return temporaryAlbums.first { $0.recipient.direction == direction }
    }
    
    func getTotalPhotosDistributed() -> Int {
        return temporaryAlbums.reduce(0) { $0 + $1.photoCount }
    }
}

// MARK: - Extensions
extension SharingViewModel {
    /// 디버깅용 상태 로깅
    func logCurrentState() {
        print("📊 === 공유 세션 상태 ===")
        if let session = currentSession {
            print("📅 선택된 날짜: \(session.selectedDate)")
            print("👥 대상자 수: \(session.recipients.count)")
            print("📁 임시 앨범 수: \(session.temporaryAlbums.count)")
            print("📸 분배된 총 사진: \(getTotalPhotosDistributed())")
            print("✅ 공유 준비: \(canStartSharing ? "완료" : "미완료")")
        } else {
            print("❌ 활성 세션 없음")
        }
        print("========================")
    }
}