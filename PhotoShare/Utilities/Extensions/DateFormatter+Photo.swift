import Foundation

/// 사진 앱 전용 날짜 포매터 확장
extension DateFormatter {
    /// 사진 정보 헤더용 날짜 포매터 (yyyy.MM.dd HH:mm)
    static let photoDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter
    }()
    
    /// 네비게이션 타이틀용 날짜 포매터 (yyyy.MM.dd)
    static let photoTitle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()
    
    /// 앨범 리스트용 짧은 날짜 포매터 (MM.dd)
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return formatter
    }()
}

/// Date 확장 - 편의 메서드 제공
extension Date {
    /// 사진 정보 헤더용 포맷 (2024.12.15 14:30)
    var photoDisplayString: String {
        DateFormatter.photoDate.string(from: self)
    }
    
    /// 네비게이션 타이틀용 포맷 (2024.12.15)
    var photoTitleString: String {
        DateFormatter.photoTitle.string(from: self)
    }
}