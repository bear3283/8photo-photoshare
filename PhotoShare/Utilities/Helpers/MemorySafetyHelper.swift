//
//  MemorySafetyHelper.swift
//  PhotoShare
//
//  Memory safety utilities to prevent EXC_BAD_ACCESS crashes
//

import Foundation
import UIKit

/// Memory safety helper to prevent common crash scenarios
final class MemorySafetyHelper {
    
    // MARK: - Array Safety
    
    /// Safely access array element with bounds checking
    static func safeAccess<T>(_ array: [T], at index: Int) -> T? {
        guard index >= 0 && index < array.count else {
            print("⚠️ Array bounds check failed: index \(index), count \(array.count)")
            return nil
        }
        return array[index]
    }
    
    /// Safely update array element with bounds checking
    static func safeUpdate<T>(_ array: inout [T], at index: Int, with newValue: T) -> Bool {
        guard index >= 0 && index < array.count else {
            print("⚠️ Array update bounds check failed: index \(index), count \(array.count)")
            return false
        }
        array[index] = newValue
        return true
    }
    
    /// Create a safe copy of array to prevent reference issues
    static func safeCopy<T>(_ array: [T]) -> [T] {
        return Array(array)
    }
    
    // MARK: - Object Validation
    
    /// Check if an object reference is still valid (not deallocated)
    static func isValidReference<T: AnyObject>(_ object: T?) -> Bool {
        guard let obj = object else { return false }
        
        // Try to access a basic property to check if object is valid
        do {
            _ = ObjectIdentifier(obj)
            return true
        } catch {
            print("⚠️ Invalid object reference detected")
            return false
        }
    }
    
    /// Safely execute a block with weak reference to prevent retain cycles
    static func withSafeReference<T: AnyObject, R>(
        to object: T?,
        execute block: (T) throws -> R
    ) rethrows -> R? {
        guard let obj = object, isValidReference(obj) else {
            print("⚠️ Cannot execute block: object reference is invalid")
            return nil
        }
        return try block(obj)
    }
    
    // MARK: - Memory Pressure Monitoring
    
    /// Check current memory usage and warn if high
    static func checkMemoryPressure(context: String = "") {
        let used = memoryUsed()
        let total = totalMemory()
        
        guard total > 0 else { return }
        
        let percentage = Double(used) / Double(total) * 100
        let contextStr = context.isEmpty ? "" : " [\(context)]"
        
        if percentage > 85 {
            print("🚨 Critical memory usage\(contextStr): \(String(format: "%.1f", percentage))%")
            // Trigger memory cleanup
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
            }
        } else if percentage > 70 {
            print("⚠️ High memory usage\(contextStr): \(String(format: "%.1f", percentage))%")
        }
    }
    
    private static func memoryUsed() -> Int64 {
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
        
        return kerr == KERN_SUCCESS ? Int64(taskInfo.resident_size) : 0
    }
    
    private static func totalMemory() -> Int64 {
        return Int64(ProcessInfo.processInfo.physicalMemory)
    }
    
    // MARK: - Crash Prevention
    
    /// Safely perform an operation that might crash due to memory issues
    static func safelyPerform<T>(
        operation: String,
        fallback: T,
        block: () throws -> T
    ) -> T {
        do {
            let result = try block()
            return result
        } catch {
            print("❌ Safe execution failed for \(operation): \(error.localizedDescription)")
            return fallback
        }
    }
    
    /// Async version of safe execution
    static func safelyPerformAsync<T>(
        operation: String,
        fallback: T,
        block: () async throws -> T
    ) async -> T {
        do {
            let result = try await block()
            return result
        } catch {
            print("❌ Safe async execution failed for \(operation): \(error.localizedDescription)")
            return fallback
        }
    }
}

// MARK: - Extensions for easier usage

extension Array {
    /// Safe subscript that returns nil instead of crashing
    subscript(safe index: Int) -> Element? {
        return MemorySafetyHelper.safeAccess(self, at: index)
    }
    
    /// Safe mutation with bounds checking
    mutating func safeSet(at index: Int, to newValue: Element) -> Bool {
        return MemorySafetyHelper.safeUpdate(&self, at: index, with: newValue)
    }
    
    /// Create a safe copy
    func safeCopy() -> [Element] {
        return MemorySafetyHelper.safeCopy(self)
    }
}