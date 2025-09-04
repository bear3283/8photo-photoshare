//
//  PerformanceMonitor.swift
//  PhotoShare
//
//  Enhanced performance monitoring for PhotoShare app
//

import Foundation
import UIKit
import os.log

/// Performance monitoring utility for debugging and optimization
final class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private let logger = Logger(subsystem: "com.photoshare.performance", category: "monitor")
    private var startTimes: [String: CFAbsoluteTime] = [:]
    private let queue = DispatchQueue(label: "performance.monitor", qos: .utility)
    
    private init() {}
    
    // MARK: - Timing Operations
    
    /// Start timing an operation
    func startTiming(_ operation: String) {
        queue.async { [weak self] in
            self?.startTimes[operation] = CFAbsoluteTimeGetCurrent()
            self?.logger.info("⏱️ Started timing: \(operation)")
        }
    }
    
    /// End timing an operation and log the duration
    func endTiming(_ operation: String) {
        queue.async { [weak self] in
            guard let self = self,
                  let startTime = self.startTimes[operation] else {
                self?.logger.warning("⚠️ No start time found for operation: \(operation)")
                return
            }
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            self.startTimes.removeValue(forKey: operation)
            
            let durationString = String(format: "%.3f", duration)
            self.logger.info("✅ \(operation): \(durationString)s")
            
            // Alert for slow operations
            if duration > 2.0 {
                self.logger.warning("🐌 Slow operation detected: \(operation) took \(durationString)s")
            }
        }
    }
    
    // MARK: - Memory Monitoring
    
    /// Get current memory usage
    func currentMemoryUsage() -> (used: Int64, total: Int64) {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Int64(taskInfo.resident_size)
            let totalMemory = Int64(ProcessInfo.processInfo.physicalMemory)
            return (usedMemory, totalMemory)
        } else {
            return (0, 0)
        }
    }
    
    /// Log current memory usage
    func logMemoryUsage(_ context: String = "") {
        let (used, total) = currentMemoryUsage()
        let usedMB = used / (1024 * 1024)
        let totalMB = total / (1024 * 1024)
        let percentage = total > 0 ? Double(used) / Double(total) * 100 : 0
        
        let contextString = context.isEmpty ? "" : " [\(context)]"
        logger.info("🧠 Memory\(contextString): \(usedMB)MB/\(totalMB)MB (\(String(format: "%.1f", percentage))%)")
        
        // Alert for high memory usage
        if percentage > 80 {
            logger.warning("⚠️ High memory usage detected: \(String(format: "%.1f", percentage))%")
        }
    }
    
    // MARK: - Photo Loading Performance
    
    /// Monitor photo loading performance
    func monitorPhotoLoading(photoCount: Int, startTime: CFAbsoluteTime) {
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let photosPerSecond = photoCount > 0 ? Double(photoCount) / duration : 0
        
        logger.info("📸 Photo loading: \(photoCount) photos in \(String(format: "%.2f", duration))s (\(String(format: "%.1f", photosPerSecond)) photos/s)")
        
        // Performance benchmarks
        if duration > 3.0 {
            logger.warning("🐌 Slow photo loading: \(String(format: "%.2f", duration))s for \(photoCount) photos")
        }
        
        if photosPerSecond < 5 && photoCount > 10 {
            logger.warning("🐌 Low photo loading throughput: \(String(format: "%.1f", photosPerSecond)) photos/s")
        }
    }
    
    // MARK: - UI Performance
    
    /// Monitor UI responsiveness (call this in main thread performance sensitive operations)
    @MainActor
    func checkUIResponsiveness(_ operation: String) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        DispatchQueue.main.async { [weak self] in
            let responseTime = CFAbsoluteTimeGetCurrent() - startTime
            
            if responseTime > 0.016 { // More than one frame at 60fps
                self?.logger.warning("🎨 UI lag detected in \(operation): \(String(format: "%.3f", responseTime))s")
            }
        }
    }
    
    // MARK: - Network Performance (for future sharing features)
    
    /// Monitor network operations
    func monitorNetworkOperation(_ operation: String, dataSize: Int64, duration: TimeInterval) {
        let dataMB = Double(dataSize) / (1024 * 1024)
        let throughput = duration > 0 ? dataMB / duration : 0
        
        logger.info("🌐 Network \(operation): \(String(format: "%.2f", dataMB))MB in \(String(format: "%.2f", duration))s (\(String(format: "%.1f", throughput))MB/s)")
        
        // Alert for slow network operations
        if throughput < 1.0 && dataMB > 5.0 {
            logger.warning("🐌 Slow network throughput: \(String(format: "%.1f", throughput))MB/s")
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Time a block of code
    func measure<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        startTiming(operation)
        defer { endTiming(operation) }
        return try block()
    }
    
    /// Time an async block of code
    func measureAsync<T>(_ operation: String, block: () async throws -> T) async rethrows -> T {
        startTiming(operation)
        defer { endTiming(operation) }
        return try await block()
    }
}

// MARK: - Extensions for easier usage

extension PerformanceMonitor {
    /// Start timing with automatic operation name from caller context
    static func startTiming(file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        let operation = "\(fileName).\(function):\(line)"
        shared.startTiming(operation)
    }
    
    /// End timing with automatic operation name from caller context
    static func endTiming(file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        let operation = "\(fileName).\(function):\(line)"
        shared.endTiming(operation)
    }
}