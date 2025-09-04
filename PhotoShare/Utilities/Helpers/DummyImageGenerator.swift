import UIKit
import SwiftUI

/// 더미 이미지 생성 유틸리티
enum DummyImageGenerator {
    
    // MARK: - Color Palette for Dummy Images
    private static let colors: [UIColor] = [
        UIColor.systemBlue,
        UIColor.systemGreen,
        UIColor.systemOrange,
        UIColor.systemPink,
        UIColor.systemPurple,
        UIColor.systemRed,
        UIColor.systemTeal,
        UIColor.systemYellow,
        UIColor.systemIndigo,
        UIColor.systemBrown
    ]
    
    private static let photoColors: [UIColor] = [
        UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0), // Sky blue
        UIColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 1.0), // Nature green
        UIColor(red: 0.9, green: 0.6, blue: 0.2, alpha: 1.0), // Sunset orange
        UIColor(red: 0.8, green: 0.3, blue: 0.6, alpha: 1.0), // Flower pink
        UIColor(red: 0.4, green: 0.3, blue: 0.8, alpha: 1.0), // Evening purple
        UIColor(red: 0.9, green: 0.8, blue: 0.2, alpha: 1.0), // Sunny yellow
        UIColor(red: 0.2, green: 0.8, blue: 0.7, alpha: 1.0), // Ocean teal
        UIColor(red: 0.7, green: 0.4, blue: 0.2, alpha: 1.0)  // Earth brown
    ]
    
    // MARK: - Album Cover Generation
    static func generateAlbumCover(
        albumName: String,
        size: CGSize = CGSize(width: 200, height: 200)
    ) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background gradient
            let colorIndex = abs(albumName.hashValue) % colors.count
            let baseColor = colors[colorIndex]
            let lightColor = baseColor.withAlphaComponent(0.3)
            
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [baseColor.cgColor, lightColor.cgColor] as CFArray,
                locations: [0.0, 1.0]
            ) {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }
            
            // Album icon
            let iconSize: CGFloat = size.width * 0.3
            let iconRect = CGRect(
                x: (size.width - iconSize) / 2,
                y: (size.height - iconSize) / 2 - 10,
                width: iconSize,
                height: iconSize
            )
            
            baseColor.withAlphaComponent(0.8).setFill()
            let iconPath = UIBezierPath(roundedRect: iconRect, cornerRadius: iconSize * 0.2)
            iconPath.fill()
            
            // Album name text
            let firstLetter = String(albumName.prefix(1)).uppercased()
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: iconSize * 0.6, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = firstLetter.size(withAttributes: attributes)
            let textPoint = CGPoint(
                x: iconRect.midX - textSize.width / 2,
                y: iconRect.midY - textSize.height / 2
            )
            
            firstLetter.draw(at: textPoint, withAttributes: attributes)
            
            // Bottom label
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.width * 0.08, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
            
            let truncatedName = albumName.count > 8 ? String(albumName.prefix(8)) + "..." : albumName
            let labelSize = truncatedName.size(withAttributes: labelAttributes)
            let labelPoint = CGPoint(
                x: (size.width - labelSize.width) / 2,
                y: size.height - labelSize.height - 15
            )
            
            truncatedName.draw(at: labelPoint, withAttributes: labelAttributes)
        }
    }
    
    // MARK: - Photo Generation
    static func generatePhoto(
        index: Int,
        size: CGSize = CGSize(width: 300, height: 300)
    ) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background with photo-like colors
            let colorIndex = index % photoColors.count
            let baseColor = photoColors[colorIndex]
            let lightColor = baseColor.withAlphaComponent(0.7)
            
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [baseColor.cgColor, lightColor.cgColor] as CFArray,
                locations: [0.0, 1.0]
            ) {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }
            
            // Photo elements (circles representing objects/people)
            let numberOfElements = (index % 3) + 1
            for i in 0..<numberOfElements {
                let elementSize = CGFloat.random(in: size.width * 0.15...size.width * 0.3)
                let x = CGFloat.random(in: elementSize/2...size.width - elementSize/2)
                let y = CGFloat.random(in: elementSize/2...size.height - elementSize/2)
                
                let elementRect = CGRect(
                    x: x - elementSize/2,
                    y: y - elementSize/2,
                    width: elementSize,
                    height: elementSize
                )
                
                UIColor.white.withAlphaComponent(0.3).setFill()
                let path = UIBezierPath(ovalIn: elementRect)
                path.fill()
            }
            
            // Photo number indicator
            let numberText = "\(index + 1)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.width * 0.12, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            
            let textSize = numberText.size(withAttributes: attributes)
            let textPoint = CGPoint(
                x: size.width - textSize.width - 10,
                y: size.height - textSize.height - 10
            )
            
            // Text background
            let backgroundRect = CGRect(
                x: textPoint.x - 5,
                y: textPoint.y - 2,
                width: textSize.width + 10,
                height: textSize.height + 4
            )
            
            UIColor.black.withAlphaComponent(0.3).setFill()
            let backgroundPath = UIBezierPath(roundedRect: backgroundRect, cornerRadius: 8)
            backgroundPath.fill()
            
            numberText.draw(at: textPoint, withAttributes: attributes)
        }
    }
    
    // MARK: - Profile Image Generation
    static func generateProfileImage(
        name: String,
        size: CGSize = CGSize(width: 100, height: 100)
    ) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background circle
            let colorIndex = abs(name.hashValue) % colors.count
            let backgroundColor = colors[colorIndex]
            
            backgroundColor.setFill()
            let circlePath = UIBezierPath(ovalIn: rect)
            circlePath.fill()
            
            // Initial letter
            let firstLetter = String(name.prefix(1)).uppercased()
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.width * 0.4, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = firstLetter.size(withAttributes: attributes)
            let textPoint = CGPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            )
            
            firstLetter.draw(at: textPoint, withAttributes: attributes)
        }
    }
    
    // MARK: - Landscape Photo Generation
    static func generateLandscapePhoto(
        type: LandscapeType = .random,
        size: CGSize = CGSize(width: 400, height: 300)
    ) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Choose colors based on landscape type
            let (topColor, bottomColor) = type.colors
            
            // Sky gradient
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [topColor.cgColor, bottomColor.cgColor] as CFArray,
                locations: [0.0, 1.0]
            ) {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: 0, y: size.height),
                    options: []
                )
            }
            
            // Add landscape elements
            switch type {
            case .sunset:
                addSunsetElements(context: context.cgContext, size: size)
            case .mountain:
                addMountainElements(context: context.cgContext, size: size)
            case .ocean:
                addOceanElements(context: context.cgContext, size: size)
            case .forest:
                addForestElements(context: context.cgContext, size: size)
            case .randomType:
                break
            }
        }
    }
    
    enum LandscapeType: CaseIterable {
        case sunset, mountain, ocean, forest, randomType
        
        static var random: LandscapeType {
            let types: [LandscapeType] = [.sunset, .mountain, .ocean, .forest]
            return types.randomElement() ?? .sunset
        }
        
        var colors: (UIColor, UIColor) {
            switch self {
            case .sunset:
                return (UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0),
                        UIColor(red: 0.9, green: 0.3, blue: 0.5, alpha: 1.0))
            case .mountain:
                return (UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0),
                        UIColor(red: 0.4, green: 0.6, blue: 0.3, alpha: 1.0))
            case .ocean:
                return (UIColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 1.0),
                        UIColor(red: 0.2, green: 0.6, blue: 0.8, alpha: 1.0))
            case .forest:
                return (UIColor(red: 0.7, green: 0.9, blue: 0.8, alpha: 1.0),
                        UIColor(red: 0.2, green: 0.5, blue: 0.3, alpha: 1.0))
            case .randomType:
                return LandscapeType.random.colors
            }
        }
    }
    
    // MARK: - Private Helper Methods
    private static func addSunsetElements(context: CGContext, size: CGSize) {
        // Sun
        let sunSize: CGFloat = size.width * 0.15
        let sunRect = CGRect(
            x: size.width * 0.7,
            y: size.height * 0.2,
            width: sunSize,
            height: sunSize
        )
        
        context.setFillColor(UIColor.yellow.withAlphaComponent(0.8).cgColor)
        context.fillEllipse(in: sunRect)
    }
    
    private static func addMountainElements(context: CGContext, size: CGSize) {
        // Mountain silhouette
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: size.height))
        path.addLine(to: CGPoint(x: size.width * 0.3, y: size.height * 0.6))
        path.addLine(to: CGPoint(x: size.width * 0.7, y: size.height * 0.4))
        path.addLine(to: CGPoint(x: size.width, y: size.height * 0.7))
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.close()
        
        context.setFillColor(UIColor.black.withAlphaComponent(0.3).cgColor)
        context.addPath(path.cgPath)
        context.fillPath()
    }
    
    private static func addOceanElements(context: CGContext, size: CGSize) {
        // Waves
        for i in 0..<3 {
            let waveY = size.height * 0.7 + CGFloat(i * 10)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: waveY))
            
            for x in stride(from: 0, through: size.width, by: 20) {
                let y = waveY + sin(x * 0.02) * 5
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.5).cgColor)
            context.setLineWidth(2)
            context.addPath(path.cgPath)
            context.strokePath()
        }
    }
    
    private static func addForestElements(context: CGContext, size: CGSize) {
        // Tree silhouettes
        for i in 0..<5 {
            let treeX = size.width * CGFloat(i) / 5.0
            let treeHeight = size.height * CGFloat.random(in: 0.3...0.6)
            let treeWidth = size.width * 0.1
            
            let treeRect = CGRect(
                x: treeX,
                y: size.height - treeHeight,
                width: treeWidth,
                height: treeHeight
            )
            
            context.setFillColor(UIColor.black.withAlphaComponent(0.4).cgColor)
            context.fillEllipse(in: treeRect)
        }
    }
}

// MARK: - SwiftUI Extensions
extension DummyImageGenerator {
    /// SwiftUI Image 생성
    static func albumCoverImage(albumName: String, size: CGSize = CGSize(width: 200, height: 200)) -> Image? {
        guard let uiImage = generateAlbumCover(albumName: albumName, size: size) else { return nil }
        return Image(uiImage: uiImage)
    }
    
    static func photoImage(index: Int, size: CGSize = CGSize(width: 300, height: 300)) -> Image? {
        guard let uiImage = generatePhoto(index: index, size: size) else { return nil }
        return Image(uiImage: uiImage)
    }
    
    static func profileImage(name: String, size: CGSize = CGSize(width: 100, height: 100)) -> Image? {
        guard let uiImage = generateProfileImage(name: name, size: size) else { return nil }
        return Image(uiImage: uiImage)
    }
    
    static func landscapeImage(type: LandscapeType = .random, size: CGSize = CGSize(width: 400, height: 300)) -> Image? {
        guard let uiImage = generateLandscapePhoto(type: type, size: size) else { return nil }
        return Image(uiImage: uiImage)
    }
}