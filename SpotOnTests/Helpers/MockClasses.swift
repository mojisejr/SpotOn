//
//  MockClasses.swift
//  SpotOnTests
//
//  Created by Claude on 11/29/25.
//

import Foundation
import AVFoundation
import UIKit
import SwiftData
import Combine
@testable import SpotOn

/// Mock CameraManager for testing
class MockCameraManager: CameraManagerProtocol {

    // MARK: - Mock Properties

    var isInitialized: Bool = false
    var isInitializing: Bool = false
    var hasPermission: Bool = false
    var permissionDenied: Bool = false
    var canSwitchCamera: Bool = true
    var sessionPreset: AVCaptureSession.Preset = .photo
    var lastError: Error?
    var capturedImage: UIImage?

    // MARK: - Call Tracking

    var initializeCameraCalled = false
    var capturePhotoCalled = false
    var switchCameraCalled = false
    var checkPermissionCalled = false
    var requestPermissionCalled = false

    // MARK: - CameraManagerProtocol Implementation

    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        checkPermissionCalled = true

        // Simulate async permission check
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion(self.hasPermission)
        }
    }

    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        requestPermissionCalled = true

        // Simulate async permission request
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.hasPermission = true
            completion(self.hasPermission)
        }
    }

    func initializeCamera() async throws {
        initializeCameraCalled = true
        isInitializing = true

        // Simulate async initialization
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        isInitializing = false

        if hasPermission {
            isInitialized = true
            lastError = nil
        } else {
            isInitialized = false
            lastError = CameraTestFixtures.MockCameraError.permissionDenied
        }
    }

    func capturePhoto() async throws {
        capturePhotoCalled = true

        guard isInitialized else {
            throw CameraTestFixtures.MockCameraError.configurationFailed
        }

        guard hasPermission else {
            throw CameraTestFixtures.MockCameraError.permissionDenied
        }

        // Simulate photo capture
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Create mock captured image
        capturedImage = CameraTestFixtures.createTestImage()
        lastError = nil
    }

    func switchCamera() async throws {
        switchCameraCalled = true

        guard canSwitchCamera else {
            throw CameraTestFixtures.MockCameraError.deviceNotFound
        }

        // Simulate camera switch
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
    }

    // MARK: - Mock Configuration Methods

    func setPermissionGranted(_ granted: Bool) {
        hasPermission = granted
        permissionDenied = !granted
    }

    func setCameraInitialized(_ initialized: Bool) {
        isInitialized = initialized
    }

    func simulateCameraError(_ error: CameraTestFixtures.MockCameraError) {
        lastError = error
        isInitialized = false
    }

    func reset() {
        isInitialized = false
        isInitializing = false
        hasPermission = false
        permissionDenied = false
        canSwitchCamera = true
        lastError = nil
        capturedImage = nil

        initializeCameraCalled = false
        capturePhotoCalled = false
        switchCameraCalled = false
        checkPermissionCalled = false
        requestPermissionCalled = false
    }
}

/// Mock ImageManager for testing
class MockImageManager: ImageManagerProtocol {

    // MARK: - Mock Properties

    var selectedImage: UIImage?
    var savedImages: [ImageInfo] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Call Tracking

    var saveImageCalled = false
    var loadImageCalled = false
    var deleteImageCalled = false
    var fileExistsCalled = false

    private var savedImageData: [String: Data] = [:]

    // MARK: - ImageManagerProtocol Implementation

    func saveImage(image: UIImage?, filename: String) throws {
        saveImageCalled = true

        guard let image = image else {
            throw ImageManagerError.invalidImage
        }

        guard !filename.isEmpty else {
            throw ImageManagerError.invalidFilename
        }

        // Convert image to data
        guard let imageData = image.pngData() else {
            throw ImageManagerError.saveError
        }

        // Store in memory for testing
        savedImageData[filename] = imageData

        // Create image info
        let imageInfo = ImageManager.ImageInfo(
            id: UUID(),
            filename: filename,
            url: URL(fileURLWithPath: "/tmp/\(filename)"),
            size: Int64(imageData.count),
            creationDate: Date(),
            format: "PNG"
        )

        savedImages.append(imageInfo)
    }

    func loadImage(filename: String) throws -> UIImage {
        loadImageCalled = true

        guard !filename.isEmpty else {
            throw ImageManagerError.invalidFilename
        }

        guard let imageData = savedImageData[filename] else {
            throw ImageManagerError.fileNotFound
        }

        guard let image = UIImage(data: imageData) else {
            throw ImageManagerError.loadError
        }

        return image
    }

    func deleteImage(filename: String) throws {
        deleteImageCalled = true

        guard !filename.isEmpty else {
            throw ImageManagerError.invalidFilename
        }

        savedImageData.removeValue(forKey: filename)

        savedImages.removeAll { $0.filename == filename }
    }

    func fileExists(filename: String) -> Bool {
        fileExistsCalled = true
        return savedImageData[filename] != nil
    }

    func getDocumentsDirectory() -> URL {
        return URL(fileURLWithPath: "/tmp")
    }

    // MARK: - Mock Configuration Methods

    func simulateSaveError(_ error: ImageManagerError) {
        errorMessage = error.localizedDescription
    }

    func setSelectedImage(_ image: UIImage?) {
        selectedImage = image
    }

    func reset() {
        selectedImage = nil
        savedImages.removeAll()
        savedImageData.removeAll()
        isLoading = false
        errorMessage = nil

        saveImageCalled = false
        loadImageCalled = false
        deleteImageCalled = false
        fileExistsCalled = false
    }
}

/// Protocol for CameraManager to enable testing
protocol CameraManagerProtocol: AnyObject {
    var isInitialized: Bool { get }
    var lastError: Error? { get }
    var capturedImage: UIImage? { get }

    func checkCameraPermission(completion: @escaping (Bool) -> Void)
    func requestCameraPermission(completion: @escaping (Bool) -> Void)
    func initializeCamera() async throws
    func capturePhoto() async throws
    func switchCamera() async throws
}

/// ImageInfo struct for testing
struct ImageInfo {
    let id: UUID
    let filename: String
    let url: URL
    let size: Int64
    let creationDate: Date
    let format: String
}

/// Protocol for ImageManager to enable testing
protocol ImageManagerProtocol: AnyObject {
    var selectedImage: UIImage? { get set }
    var savedImages: [ImageInfo] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }

    func saveImage(image: UIImage?, filename: String) throws
    func loadImage(filename: String) throws -> UIImage
    func deleteImage(filename: String) throws
    func fileExists(filename: String) -> Bool
    func getDocumentsDirectory() -> URL
}

// MARK: - Extend Real Classes to Implement Protocols

extension CameraManager: CameraManagerProtocol {}

extension ImageManager: ImageManagerProtocol {
    var savedImages: [ImageInfo] {
        return getAllSavedImages().map { realInfo in
            ImageInfo(
                id: realInfo.id,
                filename: realInfo.filename,
                url: realInfo.url,
                size: realInfo.size,
                creationDate: realInfo.creationDate,
                format: realInfo.format
            )
        }
    }
}