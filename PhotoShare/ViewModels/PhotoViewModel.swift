import Foundation
import Photos
import Combine

// MARK: - PhotoViewModel State
struct PhotoViewModelState: LoadableStateProtocol {
    var photos: [PhotoItem] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var isSharingMode: Bool = false
}

// MARK: - PhotoViewModel Actions
enum PhotoViewModelAction {
    case loadPhotos(for: Date)
    case toggleFavorite(PhotoItem)
    case markForDeletion(PhotoItem)
    case markForSaving(PhotoItem)
    case changeDate(Date)
    case requestPermission
    case processMarkedPhotos
    case clearMarks(PhotoItem)
    case clearAllMarks
    case setSharingMode(Bool)
}

// MARK: - PhotoViewModel
@MainActor
final class PhotoViewModel: ViewModelProtocol {
    typealias State = PhotoViewModelState
    typealias Action = PhotoViewModelAction
    
    @Published private(set) var state = PhotoViewModelState()
    @Published var selectedDate: Date = Date()
    
    private let photoService: PhotoServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var photos: [PhotoItem] { state.photos }
    var isLoading: Bool { state.isLoading }
    var errorMessage: String? { state.errorMessage }
    var isSharingMode: Bool { state.isSharingMode }
    
    /// 공유 모드에서는 복제/삭제 등의 위험한 작업을 제한
    var canModifyPhotos: Bool { !state.isSharingMode }
    
    // MARK: - Initialization
    init(photoService: PhotoServiceProtocol = PhotoService()) {
        self.photoService = photoService
        setupBindings()
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
        case .requestPermission:
            await requestPhotoPermission()
            
        case .loadPhotos(let date):
            await loadPhotos(for: date)
            
        case .changeDate(let date):
            await changeSelectedDate(date)
            
        case .toggleFavorite(let photo):
            await toggleFavorite(photo)
            
        case .markForDeletion(let photo):
            await markPhotoForDeletion(photo)
            
        case .markForSaving(let photo):
            await markPhotoForSaving(photo)
            
        case .processMarkedPhotos:
            await processMarkedPhotos()
            
        case .clearMarks(let photo):
            await clearMarks(photo)
            
        case .clearAllMarks:
            await clearAllMarks()
            
        case .setSharingMode(let isSharing):
            await setSharingMode(isSharing)
        }
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Setup any additional bindings if needed
    }
    
    private func requestPhotoPermission() async {
        print("🔐 사진 라이브러리 권한 요청 시작")
        
        // Set loading state
        state.isLoading = true
        state.errorMessage = nil
        
        let hasPermission = await photoService.requestPhotoPermission()
        
        if hasPermission {
            print("✅ 사진 라이브러리 권한 승인됨")
            // 단순히 선택된 날짜의 사진 로딩
            await loadPhotos(for: selectedDate)
        } else {
            print("❌ 사진 라이브러리 권한 거부됨")
            state.errorMessage = "PhotoShare가 제대로 작동하려면 사진 라이브러리 접근 권한이 필요합니다. 설정에서 권한을 허용해 주세요."
            state.isLoading = false
        }
    }
    
    private func loadPhotos(for date: Date) async {
        print("📸 사진 로딩 시작: \(DateFormatter.photoTitle.string(from: date))")
        
        state.isLoading = true
        state.errorMessage = nil
        state.photos = [] // 기존 사진 초기화
        
        let photos = await photoService.loadPhotos(for: date)
        
        print("📊 PhotoService에서 반환된 사진 수: \(photos.count)")
        
        // UI 업데이트는 메인 스레드에서
        await MainActor.run {
            state.photos = photos
            state.isLoading = false
            
            if photos.isEmpty {
                print("ℹ️ 선택한 날짜에 사진이 없습니다")
            } else {
                print("✅ UI 업데이트 완료: \(photos.count)장")
            }
        }
    }
    
    private func changeSelectedDate(_ date: Date) async {
        selectedDate = date
        await loadPhotos(for: date)
    }
    
    private func toggleFavorite(_ photo: PhotoItem) async {
        print("💖 즐겨찾기 토글 시작: \(photo.id), 현재 상태: \(photo.isFavorite)")
        
        // Find photo index
        guard let index = state.photos.firstIndex(where: { $0.id == photo.id }) else {
            print("❌ 사진을 찾을 수 없습니다: \(photo.id)")
            return
        }
        
        let originalState = photo.isFavorite
        let newState = !originalState
        
        // 1. Optimistic update with immediate UI feedback - MEMORY SAFE
        guard index >= 0 && index < state.photos.count else {
            print("❌ Invalid index for optimistic update: \(index)/\(state.photos.count)")
            return
        }
        
        // Create a copy of the array to avoid race conditions
        var updatedPhotos = state.photos
        updatedPhotos[index].localFavoriteState = newState
        state.photos = updatedPhotos
        
        print("⚡ 낙관적 업데이트: \(originalState) -> \(newState)")
        
        // TODO: Implement actual PHAsset favorite update when needed
        print("💖 즐겨찾기 상태 변경 완료: \(photo.id) -> \(newState)")
    }
    
    private func markPhotoForDeletion(_ photo: PhotoItem) async {
        // 공유 모드에서는 삭제 기능 제한
        guard !state.isSharingMode else {
            print("🔒 공유 모드에서는 사진을 삭제할 수 없습니다")
            state.errorMessage = "공유 모드에서는 사진을 삭제할 수 없습니다"
            return
        }
        
        // 안전한 마킹 업데이트
        guard let index = state.photos.firstIndex(where: { $0.id == photo.id }),
              index >= 0,
              index < state.photos.count else {
            print("❌ 마킹할 사진을 찾을 수 없음: \(photo.id)")
            return
        }
        
        // 완전히 새로운 배열 생성하여 메모리 안전성 보장
        var updatedPhotos = Array(state.photos)
        updatedPhotos[index].isMarkedForDeletion = true
        updatedPhotos[index].isMarkedForSaving = false // 상호 배타적
        state.photos = updatedPhotos
        print("📋 사진 삭제 마킹: \(photo.id)")
    }
    
    private func markPhotoForSaving(_ photo: PhotoItem) async {
        // 공유 모드에서는 보관(복제) 기능 제한
        guard !state.isSharingMode else {
            print("🔒 공유 모드에서는 사진을 보관할 수 없습니다")
            state.errorMessage = "공유 모드에서는 사진을 보관할 수 없습니다"
            return
        }
        
        // 안전한 보관 마킹
        guard let index = state.photos.firstIndex(where: { $0.id == photo.id }),
              index >= 0,
              index < state.photos.count else {
            print("❌ 보관할 사진을 찾을 수 없음: \(photo.id)")
            return
        }
        
        // 완전히 새로운 배열 생성하여 메모리 안전성 보장
        var updatedPhotos = Array(state.photos)
        updatedPhotos[index].isMarkedForSaving = true
        updatedPhotos[index].isMarkedForDeletion = false // 상호 배타적
        state.photos = updatedPhotos
        print("💚 사진 보관 마킹: \(photo.id) - 실제 복제 없음")
    }
    
    // MARK: - Additional Actions
    private func processMarkedPhotos() async {
        print("🔄 배치 처리 시작...")
        
        let photosToDelete = state.photos.filter { $0.isMarkedForDeletion }
        let photosToSave = state.photos.filter { $0.isMarkedForSaving }
        
        var resultMessages: [String] = []
        
        // 삭제 마킹된 사진들 처리 (실제 삭제는 하지 않고 마킹만 유지)
        if !photosToDelete.isEmpty {
            resultMessages.append("삭제 마킹: \(photosToDelete.count)장")
            print("🗑️ 삭제 마킹된 사진: \(photosToDelete.count)장")
        }
        
        // 보관 마킹된 사진들 처리 (실제 복제는 하지 않고 마킹만 유지)
        if !photosToSave.isEmpty {
            resultMessages.append("보관 마킹: \(photosToSave.count)장")
            print("💚 보관 마킹된 사진: \(photosToSave.count)장")
        }
        
        if !resultMessages.isEmpty {
            print("✅ 배치 처리 완료: \(resultMessages.joined(separator: ", "))")
        } else {
            print("ℹ️ 처리할 마킹된 사진이 없습니다")
        }
    }
    
    private func clearMarks(_ photo: PhotoItem) async {
        if let index = state.photos.firstIndex(where: { $0.id == photo.id }) {
            state.photos[index].isMarkedForDeletion = false
            state.photos[index].isMarkedForSaving = false
        }
    }
    
    private func clearAllMarks() async {
        for i in 0..<state.photos.count {
            state.photos[i].isMarkedForDeletion = false
            state.photos[i].isMarkedForSaving = false
        }
    }
    
    private func setSharingMode(_ isSharing: Bool) async {
        state.isSharingMode = isSharing
        
        if isSharing {
            print("🔒 공유 모드 활성화: 사진 조작 기능 제한됨")
            // 공유 모드에서는 기존 마킹된 사진들 초기화
            await clearAllMarks()
        } else {
            print("🔓 일반 모드 활성화: 사진 조작 기능 활성화됨")
        }
    }
    
}
