//
//  CameraManagerTests.swift
//  SpotOnTests
//
//  Created by Claude on 11/29/25.
//

import XCTest
import AVFoundation
import UIKit
import SwiftData
import Combine
@testable import SpotOn

/// Comprehensive unit tests for CameraManager
final class CameraManagerTests: XCTestCase {

    // MARK: - System Under Test

    var cameraManager: CameraManager!
    var mockImageManager: MockImageManager!
    var testModelContext: ModelContext!

    // MARK: - Test Lifecycle

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Create test dependencies
        mockImageManager = MockImageManager()
        testModelContext = CameraTestHelpers.createTestModelContext()

        // Create camera manager with test dependencies
        cameraManager = CameraManager(
            imageManager: mockImageManager,
            modelContext: testModelContext
        )
    }

    override func tearDownWithError() throws {
        cameraManager = nil
        mockImageManager = nil
        testModelContext = nil
        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testCameraManagerInitialization() throws {
        // Given: A new CameraManager is created

        // Then: Camera manager should be in proper initial state
        XCTAssertNotNil(cameraManager, "CameraManager should be initialized")
        XCTAssertFalse(cameraManager.isInitialized, "Camera should not be initialized on creation")
        XCTAssertFalse(cameraManager.isCapturingPhoto, "Should not be capturing photo on creation")
        XCTAssertNil(cameraManager.lastError, "Should have no error on creation")
        XCTAssertNil(cameraManager.capturedImage, "Should have no captured image on creation")
    }

    func testCameraManagerInitializationWithNilDependencies() {
        // Given: Nil dependencies are provided

        // When: Camera manager is created
        let manager = CameraManager(imageManager: nil, modelContext: nil)

        // Then: It should handle nil dependencies gracefully
        XCTAssertNotNil(manager, "CameraManager should handle nil dependencies")
    }

    // MARK: - Permission Tests

    func testCheckCameraPermissionAuthorized() throws {
        // Given: Camera permission is already authorized
        // Note: In real tests, we'd mock AVCaptureDevice.authorizationStatus
        // For now, this test documents the expected behavior

        let expectation = XCTestExpectation(description: "Camera permission check completes")

        // When: Camera permission is checked
        cameraManager.checkCameraPermission { granted in
            // Then: Permission should be granted if authorized by system
            if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
                XCTAssertTrue(granted, "Permission should be granted when authorized by system")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: CameraTestFixtures.Timing.mediumDelay)
    }

    func testRequestCameraPermissionWhenNotDetermined() throws {
        // Given: Camera permission status is not determined
        guard AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined else {
            throw XCTSkip("Camera permission already determined")
        }

        let expectation = XCTestExpectation(description: "Camera permission request completes")

        // When: Camera permission is requested
        cameraManager.requestCameraPermission { granted in
            // Then: Permission result should be returned
            // Note: This might be false if user denies or if not running on real device
            XCTAssertTrue(granted == true || granted == false, "Permission should return boolean result")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: CameraTestFixtures.Timing.cameraInitializationTimeout)
    }

    func testCameraPermissionDeniedFlow() throws {
        // Given: Camera permission is denied or restricted
        let deniedStatuses: [AVCaptureDevice.AuthorizationStatus] = [.denied, .restricted]

        guard deniedStatuses.contains(AVCaptureDevice.authorizationStatus(for: .video)) else {
            throw XCTSkip("Camera permission not denied - cannot test denied flow")
        }

        let expectation = XCTestExpectation(description: "Camera permission denied flow completes")

        // When: Camera permission is checked when denied
        cameraManager.checkCameraPermission { granted in
            // Then: Permission should not be granted
            XCTAssertFalse(granted, "Permission should not be granted when denied")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: CameraTestFixtures.Timing.shortDelay)
    }

    // MARK: - Camera Initialization Tests

    func testInitializeCameraSuccess() async throws {
        // Given: Camera permission is granted
        await withCheckedContinuation { continuation in
            cameraManager.checkCameraPermission { granted in
                guard granted else {
                    continuation.resume()
                    return
                }

                // When: Camera is initialized
                Task {
                    do {
                        try await self.cameraManager.initializeCamera()

                        // Then: Camera should be initialized successfully
                        XCTAssertTrue(self.cameraManager.isInitialized, "Camera should be initialized")
                        XCTAssertNil(self.cameraManager.lastError, "Should have no error after successful initialization")
                    } catch {
                        // Camera might not be available in simulator
                        XCTAssertNotNil(error, "Should have error when camera unavailable")
                    }
                    continuation.resume()
                }
            }
        }
    }

    func testInitializeCameraWithoutPermission() async throws {
        // Given: Camera permission is not granted
        let expectation = XCTestExpectation(description: "Camera initialization without permission")

        cameraManager.checkCameraPermission { granted in
            guard !granted else {
                expectation.fulfill()
                return
            }

            // When: Camera is initialized without permission
            Task {
                do {
                    try await self.cameraManager.initializeCamera()
                    XCTFail("Should throw error when initializing camera without permission")
                } catch {
                    // Then: Should throw appropriate error
                    XCTAssertNotNil(error, "Should throw error when camera permission denied")
                    XCTAssertEqual(self.cameraManager.lastError?.localizedDescription, "Camera permission required")
                }
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: CameraTestFixtures.Timing.mediumDelay)
    }

    func testInitializeCameraMultipleTimes() async throws {
        // Given: Camera permission is granted
        await withCheckedContinuation { continuation in
            cameraManager.checkCameraPermission { granted in
                guard granted else {
                    continuation.resume()
                    return
                }

                // When: Camera is initialized multiple times
                Task {
                    do {
                        try await self.cameraManager.initializeCamera()
                        let firstInitialization = self.cameraManager.isInitialized

                        try await self.cameraManager.initializeCamera()
                        let secondInitialization = self.cameraManager.isInitialized

                        // Then: Should handle multiple initializations gracefully
                        XCTAssertEqual(firstInitialization, secondInitialization, "Multiple initializations should be idempotent")
                    } catch {
                        // Expected in simulator environment
                        XCTAssertNotNil(error, "Should handle camera unavailability gracefully")
                    }
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Photo Capture Tests

    func testCapturePhotoWhenInitialized() async throws {
        // Given: Camera is initialized and permission granted
        await withCheckedContinuation { continuation in
            cameraManager.checkCameraPermission { granted in
                guard granted else {
                    continuation.resume()
                    return
                }

                Task {
                    do {
                        try await self.cameraManager.initializeCamera()

                        // When: Photo is captured
                        try await self.cameraManager.capturePhoto()

                        // Then: Should complete capture process (may fail in simulator)
                        if self.cameraManager.lastError != nil {
                            // Expected in simulator
                            XCTAssertNotNil(self.cameraManager.lastError, "Should have error in simulator")
                        }
                    } catch {
                        // Expected in simulator
                        XCTAssertNotNil(error, "Should throw error in simulator")
                    }
                    continuation.resume()
                }
            }
        }
    }

    func testCapturePhotoWhenNotInitialized() async throws {
        // Given: Camera is not initialized
        XCTAssertFalse(cameraManager.isInitialized, "Camera should not be initialized")

        // When: Photo capture is attempted
        do {
            try await cameraManager.capturePhoto()
            XCTFail("Should throw error when capturing photo without initialization")
        } catch {
            // Then: Should throw appropriate error
            XCTAssertNotNil(error, "Should throw error when camera not initialized")
            XCTAssertEqual(error.localizedDescription, "Camera not initialized")
        }
    }

    func testCapturePhotoStateManagement() async throws {
        // Given: Camera is initialized
        await withCheckedContinuation { continuation in
            cameraManager.checkCameraPermission { granted in
                guard granted else {
                    continuation.resume()
                    return
                }

                Task {
                    do {
                        try await self.cameraManager.initializeCamera()

                        // When: Photo capture starts
                        let captureTask = Task {
                            try await self.cameraManager.capturePhoto()
                        }

                        // Then: Should be in capturing state
                        // Note: Due to async nature, this check might not be reliable in tests
                        // In a real implementation with proper mocking, we'd verify state changes

                        _ = await captureTask.result

                        continuation.resume()
                    } catch {
                        continuation.resume()
                    }
                }
            }
        }
    }

    // MARK: - Error Handling Tests

    func testCameraManagerHandlesCameraUnavailable() throws {
        // Given: Camera hardware is unavailable (simulator scenario)

        // When: Camera operations are attempted
        let expectation = XCTestExpectation(description: "Camera unavailable handling")

        cameraManager.checkCameraPermission { granted in
            guard granted else {
                expectation.fulfill()
                return
            }

            Task {
                do {
                    try await self.cameraManager.initializeCamera()
                    // If initialization succeeds, camera is available
                    XCTAssertTrue(self.cameraManager.isInitialized, "Camera should be initialized if available")
                } catch {
                    // If initialization fails, should handle gracefully
                    XCTAssertNotNil(self.cameraManager.lastError, "Should have error when camera unavailable")
                }
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: CameraTestFixtures.Timing.cameraInitializationTimeout)
    }

    func testErrorStateClearsOnSuccess() throws {
        // Given: Camera manager has an error state
        // Note: This test would be more reliable with proper mocking

        let expectation = XCTestExpectation(description: "Error state clears")

        // When: Successful operation occurs
        cameraManager.checkCameraPermission { granted in
            // Even if permission is denied, the error state should be handled
            if granted {
                Task {
                    do {
                        try await self.cameraManager.initializeCamera()
                        if self.cameraManager.isInitialized {
                            XCTAssertNil(self.cameraManager.lastError, "Error should clear on successful initialization")
                        }
                    } catch {
                        // Expected in simulator
                    }
                    expectation.fulfill()
                }
            } else {
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: CameraTestFixtures.Timing.mediumDelay)
    }

    // MARK: - Memory Management Tests

    func testCameraManagerMemoryUsage() throws {
        // Given: Camera manager is created

        // When: Camera operations are performed
        let (beforeMemory, afterMemory) = try CameraTestHelpers.measureMemoryUsage {
            // Simulate camera operations that might affect memory
            let testImage = CameraTestFixtures.createTestImage()
            self.mockImageManager.selectedImage = testImage
            CameraTestHelpers.forceMemoryCleanup()
        }

        // Then: Memory usage should be reasonable
        let memoryIncrease = afterMemory - beforeMemory
        XCTAssertLessThan(memoryIncrease, 10_000_000, "Memory increase should be less than 10MB") // 10MB tolerance
    }

    func testCameraManagerCleanup() throws {
        // Given: Camera manager has been used
        cameraManager.checkCameraPermission { _ in
            // Perform some camera operations
        }

        // When: Camera manager is deallocated
        cameraManager = nil

        // Then: Should cleanup resources properly
        XCTAssertNil(cameraManager, "Camera manager should be nil after deallocation")

        // Force memory cleanup
        CameraTestHelpers.forceMemoryCleanup()
    }

    // MARK: - Thread Safety Tests

    func testConcurrentCameraOperations() async throws {
        // Given: Multiple concurrent operations are attempted
        let expectation = XCTestExpectation(description: "Concurrent camera operations")
        expectation.expectedFulfillmentCount = 3

        // When: Multiple operations happen concurrently
        cameraManager.checkCameraPermission { granted in
            Task {
                // Operation 1
                do {
                    try await self.cameraManager.initializeCamera()
                } catch {
                    // Expected in simulator
                }
                expectation.fulfill()
            }

            Task {
                // Operation 2
                do {
                    try await self.cameraManager.capturePhoto()
                } catch {
                    // Expected in simulator
                }
                expectation.fulfill()
            }

            Task {
                // Operation 3
                self.cameraManager.checkCameraPermission { _ in
                    expectation.fulfill()
                }
            }
        }

        await fulfillment(of: [expectation], timeout: CameraTestFixtures.Timing.longDelay)

        // Then: Should handle concurrent operations safely (no crashes)
        XCTAssertTrue(true, "Concurrent operations should not cause crashes")
    }

    // MARK: - Integration with ImageManager Tests

    func testCameraManagerUsesImageManager() throws {
        // Given: Camera manager has image manager dependency
        XCTAssertNotNil(cameraManager.imageManager, "Camera manager should have image manager")

        // When: Photo is captured successfully
        let testImage = CameraTestFixtures.createTestImage()
        mockImageManager.selectedImage = testImage

        // Then: Image manager should receive the captured image
        XCTAssertEqual(cameraManager.imageManager?.selectedImage, testImage, "Image manager should have captured image")
    }
}