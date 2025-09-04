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
        
        do {
            let hasPermission = await photoService.requestPhotoPermission()
            
            if hasPermission {
                print("✅ 사진 라이브러리 권한 승인됨")
                
                // Try to find the most recent date with photos instead of using today's date
                let dateWithPhotos = await findRecentDateWithPhotos()
                
                if let foundDate = dateWithPhotos {
                    print("📅 사진이 있는 최근 날짜 발견: \(DateFormatter.photoTitle.string(from: foundDate))")
                    selectedDate = foundDate
                    await loadPhotos(for: foundDate)
                } else {
                    print("📅 사진이 있는 날짜를 찾지 못함, 오늘 날짜로 로드")
                    await loadPhotos(for: selectedDate)
                }
            } else {
                print("❌ 사진 라이브러리 권한 거부됨")
                state.errorMessage = "PhotoShare가 제대로 작동하려면 사진 라이브러리 접근 권한이 필요합니다. 설정에서 권한을 허용해 주세요."
                
                // Clear loading state on error
                state.isLoading = false
            }
        } catch {
            print("❌ 권한 요청 중 오류 발생: \(error.localizedDescription)")
            state.errorMessage = "권한 요청 중 오류가 발생했습니다. 다시 시도해주세요."
            state.isLoading = false
        }
    }
    
    private func loadPhotos(for date: Date) async {
        // Skip if already loading the same date
        if state.isLoading {
            print("⏭️ 이미 로딩 중이므로 건너뜀: \(DateFormatter.photoTitle.string(from: date))")
            return
        }
        
        print("📸 사진 로딩 시작: \(DateFormatter.photoTitle.string(from: date))")
        
        state.isLoading = true
        state.errorMessage = nil
        
        let photos = await photoService.loadPhotos(for: date)
        state.photos = photos
        state.isLoading = false
        
        print("📊 사진 로딩 완료: \(photos.count)장")
        
        if photos.isEmpty {
            print("ℹ️ 선택한 날짜에 사진이 없습니다")
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
        
        // 2. Perform actual PHAsset update
        let success = await photoService.toggleFavorite(for: photo.asset)
        
        if success {
            print("✅ 즐겨찾기 성공: \(photo.id) -> \(newState)")
            
            // Wait a bit for PHAsset to update, then clear local state
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Memory safe update - check bounds again after async operation
            guard index >= 0 && index < state.photos.count else {
                print("⚠️ Index out of bounds after async operation: \(index)/\(state.photos.count)")
                return
            }
            
            // Atomic update using array replacement
            var refreshedPhotos = state.photos
            refreshedPhotos[index].localFavoriteState = nil
            state.photos = refreshedPhotos
            
            print("🔄 UI 새로 고침 완룄")
            
            // Clear any error messages
            state.errorMessage = nil
            
        } else {
            print("❌ 즐겨찾기 실패: \(photo.id)")
            
            // Rollback optimistic update - MEMORY SAFE
            guard index >= 0 && index < state.photos.count else {
                print("⚠️ Cannot rollback: index out of bounds \(index)/\(state.photos.count)")
                return
            }
            
            // Atomic rollback using array replacement  
            var rolledBackPhotos = state.photos
            rolledBackPhotos[index].localFavoriteState = originalState
            state.photos = rolledBackPhotos
            
            state.errorMessage = "즐겨찾기 변경에 실패했습니다. 다시 시도해 주세요."
            
            // Clear error message after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if state.errorMessage?.contains("즐겨찾기") == true {
                    state.errorMessage = nil
                }
            }
        }
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
        
        var deletedCount = 0
        var savedCount = 0
        
        // 삭제 마킹된 사진들 실제 삭제
        for photo in photosToDelete {
            let success = await photoService.deletePhoto(photo.asset)
            if success {
                state.photos.removeAll { $0.id == photo.id }
                deletedCount += 1
                print("🗑️ 사진 삭제 완료: \(photo.id)")
            } else {
                // 실패 시 마킹 해제
                if let index = state.photos.firstIndex(where: { $0.id == photo.id }) {
                    state.photos[index].isMarkedForDeletion = false
                }
                print("❌ 사진 삭제 실패: \(photo.id)")
            }
        }
        
        // 보관 마킹된 사진들 - 실제로는 아무 작업도 하지 않음 (실제 사진앱처럼)
        for photo in photosToSave {
            if state.photos.firstIndex(where: { $0.id == photo.id }) != nil {
                // 마킹만 유지하고 실제 복제는 하지 않음
                savedCount += 1
                print("💚 사진 보관 처리 완료: \(photo.id) - 복제 없이 마킹만 유지")
            }
        }
        
        // 결과 메시지 설정
        var resultMessages: [String] = []
        if deletedCount > 0 { resultMessages.append("\(deletedCount)개 삭제") }
        if savedCount > 0 { resultMessages.append("\(savedCount)개 보관") }
        
        if !resultMessages.isEmpty {
            print("✅ 배치 처리 완료: \(resultMessages.joined(separator: ", "))")
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
    
    // MARK: - Smart Date Finding with Performance Optimization
    private func findRecentDateWithPhotos() async -> Date? {
        let calendar = Calendar.current
        let today = Date()
        
        // Check the last 60 days to find a date with photos, but optimize the search
        let searchDays = min(60, 30) // Start with 30 days for better performance
        
        print("🔍 최근 \(searchDays)일 내 사진 검색 시작")
        
        // Use a more efficient approach - check weekends and recent days first
        let priorityDays: [Int] = [0, 1, 2, 6, 7, 13, 14] // Today, yesterday, day before, last weekend, previous weekend
        
        // First check priority days
        for daysBack in priorityDays {
            guard daysBack < searchDays,
                  let checkDate = calendar.date(byAdding: .day, value: -daysBack, to: today) else {
                continue
            }
            
            let photos = await photoService.loadPhotos(for: checkDate)
            if !photos.isEmpty {
                print("✅ 사진 발견: \(DateFormatter.photoTitle.string(from: checkDate)) (\(photos.count)장)")
                return checkDate
            }
        }
        
        // If no photos found in priority days, check remaining days
        for daysBack in 0..<searchDays {
            guard !priorityDays.contains(daysBack),
                  let checkDate = calendar.date(byAdding: .day, value: -daysBack, to: today) else {
                continue
            }
            
            let photos = await photoService.loadPhotos(for: checkDate)
            if !photos.isEmpty {
                print("✅ 사진 발견: \(DateFormatter.photoTitle.string(from: checkDate)) (\(photos.count)장)")
                return checkDate
            }
        }
        
        print("❌ 최근 \(searchDays)일 내 사진을 찾지 못함")
        return nil
    }
}