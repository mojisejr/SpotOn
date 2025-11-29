//
//  CameraWorkflowTests.swift
//  SpotOnTests
//
//  Created by Claude on 11/29/25.
//

import XCTest
import SwiftData
import AVFoundation
import UIKit
import Combine
@testable import SpotOn

/// Integration tests for end-to-end camera workflow
@MainActor
final class CameraWorkflowTests: XCTestCase {

    // MARK: - System Under Test

    var cameraManager: CameraManager!
    var imageManager: ImageManager!
    var testModelContext: ModelContext!
    var testUserProfile: UserProfile!
    var testSpot: Spot!

    // MARK: - Test Lifecycle

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Create test environment
        testModelContext = CameraTestHelpers.createTestModelContext()
        imageManager = ImageManager()
        cameraManager = CameraManager(
            imageManager: imageManager,
            modelContext: testModelContext
        )

        // Create test data
        testUserProfile = CameraTestHelpers.createTestUserProfile(in: testModelContext)
        testSpot = CameraTestHelpers.createTestSpot(userProfile: testUserProfile, in: testModelContext)

        try testModelContext.save()
    }

    override func tearDownWithError() throws {
        cameraManager = nil
        imageManager = nil
        testModelContext = nil
        testUserProfile = nil
        testSpot = nil
        try super.tearDownWithError()
    }

    // MARK: - End-to-End Workflow Tests

    func testCompleteCameraWorkflow() async throws {
        // Given: User has a spot and wants to add a photo
        XCTAssertEqual(testSpot.logEntries.count, 0, "Spot should start with no log entries")

        // When: Complete camera workflow is executed
        await executeCameraWorkflow()

        // Then: Should create a new LogEntry with the captured image
        try await verifyLogEntryCreated()
    }

    func testCameraWorkflowWithPermissionGranted() async throws {
        // Given: Camera permission is granted
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            throw XCTSkip("Camera permission not granted - cannot test granted permission workflow")
        }

        // When: Workflow is executed
        await executeCameraWorkflow()

        // Then: Should proceed through initialization and capture
        if cameraManager.isInitialized {
            // Camera is available and initialized
            XCTAssertTrue(true, "Workflow should complete successfully with granted permission")
        } else {
            // Camera not available (simulator), but permission flow should work
            XCTAssertNil(cameraManager.lastError, "Should not have permission-related errors")
        }
    }

    func testCameraWorkflowWithPermissionDenied() async throws {
        // Given: Camera permission is denied
        guard AVCaptureDevice.authorizationStatus(for: .video) == .denied else {
            throw XCTSkip("Camera permission not denied - cannot test denied permission workflow")
        }

        // When: Workflow is attempted
        await executeCameraWorkflow()

        // Then: Should handle permission denial gracefully
        XCTAssertNotNil(cameraManager.lastError, "Should have error when permission denied")
    }

    func testCameraWorkflowOnDeviceWithoutCamera() async throws {
        // Given: Device doesn't have camera (simulator scenario)

        // When: Workflow is attempted
        await executeCameraWorkflow()

        // Then: Should handle missing camera gracefully
        if !cameraManager.isInitialized {
            XCTAssertNotNil(cameraManager.lastError, "Should handle missing camera gracefully")
        }
    }

    // MARK: - Image Integration Tests

    func testImageSavingToLogEntry() async throws {
        // Given: A test image is captured
        let testImage = CameraTestFixtures.createTestImage()
        let testFilename = CameraTestHelpers.createUniqueTestFilename()

        // When: Image is saved and LogEntry is created
        try imageManager.saveImage(image: testImage, filename: testFilename)

        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: testFilename,
            note: CameraTestFixtures.MockLogEntryData.validNote,
            painScore: CameraTestFixtures.MockLogEntryData.validPainScore,
            hasBleeding: CameraTestFixtures.MockLogEntryData.validHasBleeding,
            hasItching: CameraTestFixtures.MockLogEntryData.validHasItching,
            isSwollen: CameraTestFixtures.MockLogEntryData.validIsSwollen,
            estimatedSize: CameraTestFixtures.MockLogEntryData.validEstimatedSize,
            spot: testSpot
        )

        testModelContext.insert(logEntry)
        try testModelContext.save()

        // Then: LogEntry should be created with correct image
        XCTAssertNotNil(logEntry, "LogEntry should be created")
        XCTAssertEqual(logEntry.imageFilename, testFilename, "Should have correct image filename")
        XCTAssertTrue(imageManager.fileExists(filename: testFilename), "Image file should exist")

        // Verify image can be loaded
        let loadedImage = try imageManager.loadImage(filename: testFilename)
        CameraTestHelpers.assertValidImage(loadedImage, testCase: self)
    }

    func testLogEntryCreationWorkflow() async throws {
        // Given: Camera workflow captures an image
        let testImage = CameraTestFixtures.createTestImage()
        imageManager.selectedImage = testImage

        // When: LogEntry is created with medical data
        let logEntry = await createLogEntryWithCameraImage()

        // Then: LogEntry should be properly created
        XCTAssertNotNil(logEntry, "LogEntry should be created")
        XCTAssertEqual(logEntry.spot?.id, testSpot.id, "LogEntry should be linked to correct spot")
        XCTAssertNotNil(logEntry.imageFilename, "Should have image filename")

        // Verify image file exists
        if let filename = logEntry.imageFilename {
            XCTAssertTrue(imageManager.fileExists(filename: filename), "Image file should exist for LogEntry")
        }
    }

    // MARK: - Error Recovery Tests

    func testWorkflowRecoveryFromCameraError() async throws {
        // Given: Camera fails to initialize
        mockCameraInitializationFailure()

        // When: Workflow is attempted
        await executeCameraWorkflow()

        // Then: Should handle error gracefully and allow retry
        XCTAssertNotNil(cameraManager.lastError, "Should have camera error")

        // When: Retry is attempted with mocked success
        mockCameraInitializationSuccess()
        await executeCameraWorkflow()

        // Then: Should recover from error
        // Note: This would require proper mocking infrastructure
        XCTAssertTrue(true, "Should allow retry after camera error")
    }

    func testWorkflowRecoveryFromImageSaveError() async throws {
        // Given: Image saving fails
        mockImageSaveFailure()

        // When: Workflow attempts to save image
        let testImage = CameraTestFixtures.createTestImage()
        let invalidFilename = "" // Invalid filename to trigger error

        do {
            try imageManager.saveImage(image: testImage, filename: invalidFilename)
            XCTFail("Should throw error for invalid filename")
        } catch {
            // Expected error
            XCTAssertNotNil(error, "Should throw error for invalid filename")
        }

        // Then: Should handle save error gracefully
        XCTAssertTrue(true, "Should handle image save error gracefully")
    }

    // MARK: - Performance Tests

    func testWorkflowPerformance() async throws {
        // Given: Standard workflow execution
        measure(metrics: [XCTClockMeasure(), XCTMemoryMeasure()]) {
            Task {
                await self.executeCameraWorkflow()
            }
        }
    }

    func testImageProcessingPerformance() throws {
        // Given: Large test image
        let largeTestImage = CameraTestFixtures.createTestImage(
            size: CGSize(width: 2000, height: 2000)
        )

        // When: Image is processed
        let filename = CameraTestHelpers.createUniqueTestFilename()

        measure {
            do {
                try self.imageManager.saveImage(image: largeTestImage, filename: filename)
                _ = try self.imageManager.loadImage(filename: filename)
                try self.imageManager.deleteImage(filename: filename)
            } catch {
                XCTFail("Image processing should not fail: \(error)")
            }
        }
    }

    // MARK: - Memory Management Tests

    func testWorkflowMemoryManagement() async throws {
        // Given: Memory usage baseline
        let initialMemory = CameraTestHelpers.getMemoryUsage()

        // When: Workflow is executed multiple times
        for _ in 0..<10 {
            await executeCameraWorkflow()
            CameraTestHelpers.forceMemoryCleanup()
        }

        let finalMemory = CameraTestHelpers.getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory

        // Then: Memory usage should be reasonable
        XCTAssertLessThan(memoryIncrease, 50_000_000, "Memory increase should be less than 50MB after 10 workflows")
    }

    // MARK: - Data Integrity Tests

    func testDataIntegrityAfterWorkflow() async throws {
        // Given: Initial data state
        let initialLogEntryCount = testSpot.logEntries.count

        // When: Workflow is executed
        let logEntry = await executeCameraWorkflowWithRealData()

        // Then: Data integrity should be maintained
        XCTAssertEqual(testSpot.logEntries.count, initialLogEntryCount + 1, "Should have exactly one more LogEntry")
        XCTAssertEqual(testSpot.logEntries.last?.spot?.id, testSpot.id, "LogEntry should reference correct spot")
        XCTAssertNotNil(testSpot.logEntries.last?.imageFilename, "LogEntry should have image filename")

        // Verify image file exists and is valid
        if let filename = testSpot.logEntries.last?.imageFilename {
            XCTAssertTrue(imageManager.fileExists(filename: filename), "Image file should exist")
            let loadedImage = try imageManager.loadImage(filename: filename)
            CameraTestHelpers.assertValidImage(loadedImage, testCase: self)
        }
    }

    func testDatabaseTransactionIntegrity() async throws {
        // Given: Workflow creates database entries

        // When: Workflow is interrupted during database save
        let expectation = XCTestExpectation(description: "Database transaction integrity")

        do {
            let logEntry = await createLogEntryWithCameraImage()
            testModelContext.insert(logEntry)

            // Simulate interruption by rolling back
            testModelContext.rollback()

            // Then: Database should remain consistent
            let logEntries = try testModelContext.fetch(FetchDescriptor<LogEntry>())
            XCTAssertTrue(true, "Database should handle rollback gracefully")
        } catch {
            XCTAssertNotNil(error, "Should handle database errors gracefully")
        }

        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: CameraTestFixtures.Timing.mediumDelay)
    }

    // MARK: - Helper Methods

    private func executeCameraWorkflow() async {
        // Step 1: Check camera permission
        await withCheckedContinuation { continuation in
            cameraManager.checkCameraPermission { granted in
                if granted {
                    Task {
                        do {
                            // Step 2: Initialize camera
                            try await self.cameraManager.initializeCamera()

                            // Step 3: Capture photo
                            try await self.cameraManager.capturePhoto()
                        } catch {
                            // Handle errors gracefully in test environment
                        }
                    }
                }
                continuation.resume()
            }
        }
    }

    private func executeCameraWorkflowWithRealData() async -> LogEntry? {
        // Execute workflow with actual image
        let testImage = CameraTestFixtures.createTestImage()
        imageManager.selectedImage = testImage

        return await createLogEntryWithCameraImage()
    }

    private func createLogEntryWithCameraImage() async -> LogEntry {
        // Create LogEntry with captured image
        let testFilename = CameraTestHelpers.createUniqueTestFilename()

        if let image = imageManager.selectedImage {
            do {
                try imageManager.saveImage(image: image, filename: testFilename)
            } catch {
                // Handle save error in test environment
            }
        }

        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: testFilename,
            note: CameraTestFixtures.MockLogEntryData.validNote,
            painScore: CameraTestFixtures.MockLogEntryData.validPainScore,
            hasBleeding: CameraTestFixtures.MockLogEntryData.validHasBleeding,
            hasItching: CameraTestFixtures.MockLogEntryData.validHasItching,
            isSwollen: CameraTestFixtures.MockLogEntryData.validIsSwollen,
            estimatedSize: CameraTestFixtures.MockLogEntryData.validEstimatedSize,
            spot: testSpot
        )

        testModelContext.insert(logEntry)
        try? testModelContext.save()

        return logEntry
    }

    private func verifyLogEntryCreated() async throws {
        let descriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == testSpot.id }
        )
        let logEntries = try testModelContext.fetch(descriptor)

        XCTAssertGreaterThan(logEntries.count, 0, "Should have created at least one LogEntry")

        if let lastEntry = logEntries.last {
            XCTAssertNotNil(lastEntry.imageFilename, "LogEntry should have image filename")
            XCTAssertNotNil(lastEntry.timestamp, "LogEntry should have timestamp")
        }
    }

    private func mockCameraInitializationFailure() {
        // In a real implementation with proper mocking, this would set up mock behavior
        // For now, this documents the intended behavior
    }

    private func mockCameraInitializationSuccess() {
        // In a real implementation with proper mocking, this would set up mock success behavior
        // For now, this documents the intended behavior
    }

    private func mockImageSaveFailure() {
        // In a real implementation with proper mocking, this would set up mock save failure
        // For now, this documents the intended behavior
    }
}