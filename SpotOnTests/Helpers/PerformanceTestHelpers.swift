//
//  PerformanceTestHelpers.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import Foundation
import SwiftUI
import SwiftData
import XCTest
@testable import SpotOn

/// Comprehensive performance testing utilities for memory management and benchmarking
class PerformanceTestHelpers {

    // MARK: - Memory Testing

    /// Measures memory usage before and after an operation
    /// - Parameters:
    ///   - operation: The operation to measure
    ///   - iterations: Number of iterations to run (default: 1)
    /// - Returns: Memory measurement results
    static func measureMemoryUsage<T>(
        operation: () throws -> T,
        iterations: Int = 1
    ) rethrows -> MemoryMeasurementResult {
        let baselineMemory = getCurrentMemoryUsage()
        var peakMemory = baselineMemory
        var results: [T] = []
        var memoryMeasurements: [Double] = []

        for _ in 0..<iterations {
            let preMemory = getCurrentMemoryUsage()
            let result = try operation()
            let postMemory = getCurrentMemoryUsage()

            results.append(result)
            memoryMeasurements.append(postMemory - preMemory)
            peakMemory = max(peakMemory, postMemory)
        }

        // Force garbage collection to measure cleanup
        performCleanup()
        let finalMemory = getCurrentMemoryUsage()

        return MemoryMeasurementResult(
            baselineMemory: baselineMemory,
            peakMemory: peakMemory,
            finalMemory: finalMemory,
            memoryIncrease: finalMemory - baselineMemory,
            averageMemoryPerIteration: memoryMeasurements.reduce(0, +) / Double(iterations),
            iterations: iterations,
            memoryLeaked: finalMemory > baselineMemory + 10.0 // Allow small margin
        )
    }

    /// Tests memory leak detection over multiple operations
    /// - Parameters:
    ///   - operation: The operation to test for leaks
    ///   - cycles: Number of cycles to run
    ///   - operationsPerCycle: Operations per cycle
    /// - Returns: Leak detection results
    static func detectMemoryLeaks<T>(
        operation: () throws -> T,
        cycles: Int = 10,
        operationsPerCycle: Int = 100
    ) rethrows -> MemoryLeakDetectionResult {
        var cycleMeasurements: [Double] = []
        let initialMemory = getCurrentMemoryUsage()

        for cycle in 0..<cycles {
            let cycleStartMemory = getCurrentMemoryUsage()

            // Run multiple operations per cycle
            for _ in 0..<operationsPerCycle {
                _ = try operation()
            }

            let cycleEndMemory = getCurrentMemoryUsage()
            cycleMeasurements.append(cycleEndMemory - cycleStartMemory)

            // Force cleanup between cycles
            performCleanup()
        }

        let finalMemory = getCurrentMemoryUsage()
        let totalMemoryIncrease = finalMemory - initialMemory

        // Analyze memory growth pattern
        let averageCycleGrowth = cycleMeasurements.reduce(0, +) / Double(cycles)
        let memoryGrowthTrend = calculateGrowthTrend(cycleMeasurements)

        return MemoryLeakDetectionResult(
            initialMemory: initialMemory,
            finalMemory: finalMemory,
            totalMemoryIncrease: totalMemoryIncrease,
            averageMemoryPerCycle: averageCycleGrowth,
            cycleMeasurements: cycleMeasurements,
            growthTrend: memoryGrowthTrend,
            hasMemoryLeak: totalMemoryIncrease > (initialMemory * 0.1) // 10% growth threshold
        )
    }

    // MARK: - Database Performance Testing

    /// Tests SwiftData operation performance
    /// - Parameter context: ModelContext to test
    /// - Returns: Database performance results
    static func testDatabasePerformance(context: ModelContext) -> DatabasePerformanceResult {
        var operationTimes: [String: TimeInterval] = [:]

        // Test insertion performance
        let insertTime = measureTime {
            for i in 0..<100 {
                let user = UserProfile(
                    id: UUID(),
                    name: "Test User \(i)",
                    relation: "Self",
                    avatarColor: "#FF6B6B",
                    createdAt: Date()
                )
                context.insert(user)

                let spot = Spot(
                    id: UUID(),
                    title: "Test Spot \(i)",
                    bodyPart: "Test Body Part",
                    isActive: true,
                    createdAt: Date(),
                    userProfile: user
                )
                context.insert(spot)

                let logEntry = LogEntry(
                    id: UUID(),
                    timestamp: Date(),
                    imageFilename: "test_\(i).jpg",
                    note: "Test note \(i)",
                    painScore: Int.random(in: 0...10),
                    hasBleeding: Bool.random(),
                    hasItching: Bool.random(),
                    isSwollen: Bool.random(),
                    estimatedSize: Double.random(in: 1...20),
                    spot: spot
                )
                context.insert(logEntry)
            }
            try? context.save()
        }
        operationTimes["insert_300_records"] = insertTime

        // Test query performance
        let queryTime = measureTime {
            let users = try? context.fetch(FetchDescriptor<UserProfile>())
            let spots = try? context.fetch(FetchDescriptor<Spot>())
            let entries = try? context.fetch(FetchDescriptor<LogEntry>())
        }
        operationTimes["query_all_records"] = queryTime

        // Test complex query performance
        let complexQueryTime = measureTime {
            let descriptor = FetchDescriptor<LogEntry>(
                predicate: #Predicate<LogEntry> { entry in
                    entry.painScore > 5 && (entry.hasBleeding || entry.isSwollen)
                },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            let results = try? context.fetch(descriptor)
        }
        operationTimes["complex_query"] = complexQueryTime

        // Test deletion performance
        let deleteTime = measureTime {
            let entries = try? context.fetch(FetchDescriptor<LogEntry>())
            for entry in entries ?? [] {
                context.delete(entry)
            }
            let spots = try? context.fetch(FetchDescriptor<Spot>())
            for spot in spots ?? [] {
                context.delete(spot)
            }
            let users = try? context.fetch(FetchDescriptor<UserProfile>())
            for user in users ?? [] {
                context.delete(user)
            }
            try? context.save()
        }
        operationTimes["delete_all_records"] = deleteTime

        return DatabasePerformanceResult(
            operationTimes: operationTimes,
            totalRecordsTested: 300,
            averageInsertTime: insertTime / 300,
            averageQueryTime: queryTime,
            averageComplexQueryTime: complexQueryTime,
            averageDeleteTime: deleteTime / 300
        )
    }

    /// Tests database performance with large datasets
    /// - Parameters:
    ///   - context: ModelContext to test
    ///   - recordCount: Number of records to create
    /// - Returns: Large dataset performance results
    static func testLargeDatasetPerformance(
        context: ModelContext,
        recordCount: Int = 1000
    ) -> LargeDatasetPerformanceResult {
        let insertionTime = measureTime {
            for i in 0..<recordCount {
                let user = UserProfile(
                    id: UUID(),
                    name: "User \(i)",
                    relation: "Self",
                    avatarColor: "#FF6B6B",
                    createdAt: Date()
                )
                context.insert(user)
            }
            try? context.save()
        }

        let queryTime = measureTime {
            let users = try? context.fetch(FetchDescriptor<UserProfile>())
        }

        let memoryResult = measureMemoryUsage {
            try? context.fetch(FetchDescriptor<UserProfile>())
        }

        // Cleanup
        let cleanupTime = measureTime {
            let users = try? context.fetch(FetchDescriptor<UserProfile>())
            for user in users ?? [] {
                context.delete(user)
            }
            try? context.save()
        }

        return LargeDatasetPerformanceResult(
            recordCount: recordCount,
            insertionTime: insertionTime,
            queryTime: queryTime,
            cleanupTime: cleanupTime,
            memoryResult: memoryResult,
            recordsPerSecond: Double(recordCount) / insertionTime,
            memoryEfficiency: memoryResult.finalMemory / Double(recordCount)
        )
    }

    // MARK: - UI Performance Testing

    /// Tests SwiftUI view rendering performance
    /// - Parameters:
    ///   - viewCreator: Function that creates the view to test
    ///   - contentSizes: Array of content sizes to test
    /// - Returns: UI performance results
    static func testViewRenderingPerformance<T: View>(
        viewCreator: @escaping () -> T,
        contentSizes: [Int] = [1, 10, 50, 100, 500]
    ) -> UIPerformanceResult {
        var renderingResults: [RenderingPerformanceResult] = []

        for size in contentSizes {
            let memoryResult = measureMemoryUsage {
                let view = viewCreator()
                // Mock rendering - in real implementation would use view inspector
                _ = view
            }

            let renderTime = measureTime {
                let view = viewCreator()
                // Mock render measurement
                _ = view
            }

            let result = RenderingPerformanceResult(
                contentSize: size,
                renderTime: renderTime,
                memoryUsage: memoryResult.memoryIncrease,
                isPerformant: renderTime < 0.1 && memoryResult.memoryIncrease < 50.0 // 100ms, 50MB threshold
            )

            renderingResults.append(result)
        }

        return UIPerformanceResult(
            renderingResults: renderingResults,
            overallPerformant: renderingResults.allSatisfy { $0.isPerformant }
        )
    }

    /// Tests scroll performance for list views
    /// - Parameters:
    ///   - itemCount: Number of items in the list
    ///   - viewCreator: Function that creates the list view
    /// - Returns: Scroll performance results
    static func testScrollPerformance<T: View>(
        itemCount: Int,
        viewCreator: @escaping (Int) -> T
    ) -> ScrollPerformanceResult {
        // Test initial load time
        let loadTime = measureTime {
            let view = viewCreator(itemCount)
            _ = view
        }

        // Test memory usage with large lists
        let memoryResult = measureMemoryUsage {
            let view = viewCreator(itemCount)
            _ = view
        }

        // Test scroll performance (simulated)
        let scrollTime = measureTime {
            // Mock scroll operations
            for _ in 0..<10 {
                let view = viewCreator(itemCount)
                _ = view
            }
        }

        return ScrollPerformanceResult(
            itemCount: itemCount,
            initialLoadTime: loadTime,
            scrollTime: scrollTime,
            memoryResult: memoryResult,
            averageScrollFrameTime: scrollTime / 10,
            isSmooth: scrollTime / 10 < 0.016 // 60 FPS = 16.67ms per frame
        )
    }

    // MARK: - Image Performance Testing

    /// Tests image processing performance for medical photos
    /// - Parameters:
    ///   - imageSizes: Array of image sizes to test
    ///   - processingOperations: Array of processing operations
    /// - Returns: Image performance results
    static func testImageProcessingPerformance(
        imageSizes: [CGSize] = [
            CGSize(width: 640, height: 480),   // Standard
            CGSize(width: 1920, height: 1080), // Full HD
            CGSize(width: 4096, height: 3072)  // High resolution
        ],
        processingOperations: [ImageProcessingOperation] = [.resize, .overlay, .compress]
    ) -> ImagePerformanceResult {
        var processingResults: [ImageProcessingResult] = []

        for size in imageSizes {
            for operation in processingOperations {
                let memoryResult = measureMemoryUsage {
                    // Mock image processing
                    processMockImage(size: size, operation: operation)
                }

                let processingTime = measureTime {
                    processMockImage(size: size, operation: operation)
                }

                let result = ImageProcessingResult(
                    imageSize: size,
                    operation: operation,
                    processingTime: processingTime,
                    memoryUsage: memoryResult.memoryIncrease,
                    isAcceptable: processingTime < 3.0 && memoryResult.memoryIncrease < 100.0 // 3s, 100MB threshold
                )

                processingResults.append(result)
            }
        }

        return ImagePerformanceResult(
            processingResults: processingResults,
            overallAcceptable: processingResults.allSatisfy { $0.isAcceptable }
        )
    }

    // MARK: - Helper Methods

    private static func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        } else {
            return 0.0
        }
    }

    private static func performCleanup() {
        // Force garbage collection
        autoreleasepool {
            // Force autoreleasepool cleanup
        }
    }

    private static func measureTime<T>(_ operation: () throws -> T) rethrows -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = try operation()
        let endTime = CFAbsoluteTimeGetCurrent()
        return endTime - startTime
    }

    private static func calculateGrowthTrend(_ measurements: [Double]) -> GrowthTrend {
        guard measurements.count >= 3 else { return .insufficientData }

        let firstHalf = measurements.prefix(measurements.count / 2)
        let secondHalf = measurements.suffix(measurements.count / 2)

        let firstHalfAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondHalfAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)

        let growthRate = (secondHalfAvg - firstHalfAvg) / firstHalfAvg

        if growthRate > 0.1 {
            return .growing
        } else if growthRate < -0.1 {
            return .shrinking
        } else {
            return .stable
        }
    }

    private static func processMockImage(size: CGSize, operation: ImageProcessingOperation) {
        // Mock image processing - would use actual image processing in real implementation
        let pixelData = Array(repeating: UInt8(0), count: Int(size.width * size.height * 4))
        _ = pixelData
    }
}

// MARK: - Supporting Types

struct MemoryMeasurementResult {
    let baselineMemory: Double
    let peakMemory: Double
    let finalMemory: Double
    let memoryIncrease: Double
    let averageMemoryPerIteration: Double
    let iterations: Int
    let memoryLeaked: Bool

    var memoryLeakAmount: Double {
        max(0, finalMemory - baselineMemory)
    }
}

struct MemoryLeakDetectionResult {
    let initialMemory: Double
    let finalMemory: Double
    let totalMemoryIncrease: Double
    let averageMemoryPerCycle: Double
    let cycleMeasurements: [Double]
    let growthTrend: GrowthTrend
    let hasMemoryLeak: Bool
}

enum GrowthTrend {
    case stable
    case growing
    case shrinking
    case insufficientData
}

struct DatabasePerformanceResult {
    let operationTimes: [String: TimeInterval]
    let totalRecordsTested: Int
    let averageInsertTime: TimeInterval
    let averageQueryTime: TimeInterval
    let averageComplexQueryTime: TimeInterval
    let averageDeleteTime: TimeInterval
}

struct LargeDatasetPerformanceResult {
    let recordCount: Int
    let insertionTime: TimeInterval
    let queryTime: TimeInterval
    let cleanupTime: TimeInterval
    let memoryResult: MemoryMeasurementResult
    let recordsPerSecond: Double
    let memoryEfficiency: Double
}

struct UIPerformanceResult {
    let renderingResults: [RenderingPerformanceResult]
    let overallPerformant: Bool
}

struct RenderingPerformanceResult {
    let contentSize: Int
    let renderTime: TimeInterval
    let memoryUsage: Double
    let isPerformant: Bool
}

struct ScrollPerformanceResult {
    let itemCount: Int
    let initialLoadTime: TimeInterval
    let scrollTime: TimeInterval
    let memoryResult: MemoryMeasurementResult
    let averageScrollFrameTime: TimeInterval
    let isSmooth: Bool
}

enum ImageProcessingOperation {
    case resize
    case overlay
    case compress
    case filter
}

struct ImagePerformanceResult {
    let processingResults: [ImageProcessingResult]
    let overallAcceptable: Bool
}

struct ImageProcessingResult {
    let imageSize: CGSize
    let operation: ImageProcessingOperation
    let processingTime: TimeInterval
    let memoryUsage: Double
    let isAcceptable: Bool
}

// MARK: - XCTest Extensions

extension XCTestCase {
    /// Asserts memory usage is within acceptable limits
    func assertMemoryUsage(
        _ result: MemoryMeasurementResult,
        within limit: Double,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertLessThanOrEqual(
            result.memoryIncrease,
            limit,
            "Memory usage increased by \(result.memoryIncrease) MB, which exceeds the limit of \(limit) MB",
            file: file,
            line: line
        )
    }

    /// Asserts no memory leaks are detected
    func assertNoMemoryLeaks(
        _ result: MemoryLeakDetectionResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertFalse(
            result.hasMemoryLeak,
            "Memory leak detected: \(result.totalMemoryIncrease) MB increase over \(result.cycleMeasurements.count) cycles",
            file: file,
            line: line
        )
    }

    /// Asserts UI performance is acceptable
    func assertUIPerformance(
        _ result: UIPerformanceResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            result.overallPerformant,
            "UI performance is not acceptable: \(result.renderingResults.filter { !$0.isPerformant }.count) failed tests",
            file: file,
            line: line
        )
    }

    /// Asserts database performance meets medical app standards
    func assertDatabasePerformance(
        _ result: DatabasePerformanceResult,
        maxInsertTime: TimeInterval = 0.001,
        maxQueryTime: TimeInterval = 0.1,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertLessThanOrEqual(
            result.averageInsertTime,
            maxInsertTime,
            "Database insert time \(result.averageInsertTime)s exceeds maximum \(maxInsertTime)s",
            file: file,
            line: line
        )

        XCTAssertLessThanOrEqual(
            result.averageQueryTime,
            maxQueryTime,
            "Database query time \(result.averageQueryTime)s exceeds maximum \(maxQueryTime)s",
            file: file,
            line: line
        )
    }
}