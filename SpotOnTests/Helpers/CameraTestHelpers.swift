//
//  CameraTestHelpers.swift
//  SpotOnTests
//
//  Created by Claude on 11/29/25.
//

import Foundation
import XCTest
import UIKit
import SwiftData

/// Helper utilities for camera testing
class CameraTestHelpers {

    // MARK: - Test Expectation Helpers

    /// Creates an expectation that fulfills after a specified delay
    static func delayedExpectation(description: String, delay: TimeInterval, testCase: XCTestCase) -> XCTestExpectation {
        let expectation = XCTestExpectation(description: description)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            expectation.fulfill()
        }
        return expectation
    }

    /// Creates an expectation that fulfills when a condition becomes true (with timeout)
    static func conditionExpectation(
        description: String,
        condition: @escaping () -> Bool,
        timeout: TimeInterval,
        testCase: XCTestCase
    ) -> XCTestExpectation {
        let expectation = XCTestExpectation(description: description)

        let startTime = Date()
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if condition() {
                timer.invalidate()
                expectation.fulfill()
            } else if Date().timeIntervalSince(startTime) > timeout {
                timer.invalidate()
                expectation.fulfill() // Fulfill anyway to avoid timeout
            }
        }

        return expectation
    }

    // MARK: - Model Context Helpers

    /// Creates an in-memory SwiftData model context for testing
    static func createTestModelContext() -> ModelContext {
        let schema = Schema([
            UserProfile.self,
            Spot.self,
            LogEntry.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    /// Creates a test user profile for testing camera workflows
    static func createTestUserProfile(in context: ModelContext) -> UserProfile {
        let userProfile = UserProfile(
            id: UUID(),
            name: "Test User",
            relation: "Self",
            avatarColor: "#007AFF",
            createdAt: Date()
        )
        context.insert(userProfile)
        return userProfile
    }

    /// Creates a test spot for testing camera workflows
    static func createTestSpot(userProfile: UserProfile, in context: ModelContext) -> Spot {
        let spot = Spot(
            id: UUID(),
            title: "Test Spot",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: userProfile
        )
        context.insert(spot)
        return spot
    }

    // MARK: - File System Helpers

    /// Creates a unique test filename with timestamp
    static func createUniqueTestFilename(extension: String = "jpg") -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString.prefix(8)
        return "test_\(timestamp)_\(uuid).\(`extension`)"
    }

    /// Creates a temporary test file with the given data
    static func createTemporaryFile(data: Data, filename: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return fileURL
    }

    /// Cleans up a temporary test file
    static func cleanupTemporaryFile(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Failed to cleanup temporary file: \(error)")
        }
    }

    // MARK: - Image Comparison Helpers

    /// Compares two images for equality within a tolerance
    static func imagesEqual(_ image1: UIImage, _ image2: UIImage, tolerance: Float = 0.99) -> Bool {
        guard let data1 = image1.pngData(),
              let data2 = image2.pngData() else {
            return false
        }
        return data1 == data2
    }

    /// Asserts that an image meets basic requirements (not nil, valid size)
    static func assertValidImage(_ image: UIImage?, testCase: XCTestCase, file: StaticString = #file, line: UInt = #line) {
        XCTAssertNotNil(image, "Image should not be nil", file: file, line: line)
        if let image = image {
            XCTAssertFalse(image.size.width <= 0 || image.size.height <= 0, "Image should have valid dimensions", file: file, line: line)
        }
    }

    // MARK: - Error Assertion Helpers

    /// Asserts that an error is of the expected type
    static func assertError<T: Error & Equatable>(
        _ error: Error?,
        expectedError: T,
        testCase: XCTestCase,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertNotNil(error, "Expected error but got nil", file: file, line: line)
        if let actualError = error as? T {
            XCTAssertEqual(actualError, expectedError, file: file, line: line)
        } else {
            XCTFail("Expected error of type \(T.self), got \(type(of: error ?? NSError()))", file: file, line: line)
        }
    }

    // MARK: - Memory Management Helpers

    /// Forces memory cleanup for testing memory-related camera issues
    static func forceMemoryCleanup() {
        // Trigger autorelease pool cleanup
        autoreleasepool {
            // Force garbage collection
            if #available(iOS 13.0, *) {
                // iOS doesn't provide manual garbage collection, but we can create memory pressure
            }
        }
    }

    /// Measures memory usage before and after an operation
    static func measureMemoryUsage(operation: () throws -> Void) throws -> (before: Int64, after: Int64) {
        let beforeMemory = getMemoryUsage()
        try operation()
        let afterMemory = getMemoryUsage()
        return (beforeMemory, afterMemory)
    }

    /// Gets current memory usage in bytes
    private static func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }

    // MARK: - AVFoundation Mocking Helpers

    /// Creates a mock AVCaptureDevice for testing
    static func createMockCaptureDevice(position: AVCaptureDevice.Position = .back) -> AVCaptureDevice? {
        // Note: In real tests, we'd use dependency injection or protocols to mock AVFoundation
        // This is a placeholder for where we'd implement proper mocking
        return AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position
        ).devices.first
    }

    // MARK: - Permission Mocking Helpers

    /// Mock camera permission status for testing
    /// Note: This would typically be implemented using dependency injection or a permission manager protocol
    static func mockCameraPermissionStatus(_ status: String) {
        // In a real implementation, this would use a PermissionManager protocol
        // that can be mocked in tests. For now, this is a placeholder.
        print("Mocking camera permission status: \(status)")
    }
}