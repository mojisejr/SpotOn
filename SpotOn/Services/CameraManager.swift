//
//  CameraManager.swift
//  SpotOn
//
//  Created by Claude on 11/29/25.
//

import Foundation
import AVFoundation
import UIKit
import SwiftData
import Combine

/// CameraManager handles all camera operations for the SpotOn app
/// Provides a clean interface for camera initialization, permission handling, and photo capture
@MainActor
class CameraManager: ObservableObject {

    // MARK: - Published Properties

    @Published var isInitialized: Bool = false
    @Published var isCapturingPhoto: Bool = false
    @Published var lastError: Error?
    @Published var capturedImage: UIImage?

    // MARK: - Private Properties

    private let imageManager: ImageManager?
    private let modelContext: ModelContext?
    private var captureSession: AVCaptureSession?
    private var captureDevice: AVCaptureDevice?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoCaptureCompletion: ((UIImage?, Error?) -> Void)?

    // MARK: - Initialization

    /// Initialize CameraManager with required dependencies
    /// - Parameters:
    ///   - imageManager: Optional ImageManager for saving photos
    ///   - modelContext: Optional ModelContext for creating LogEntry objects
    init(imageManager: ImageManager? = nil, modelContext: ModelContext? = nil) {
        self.imageManager = imageManager
        self.modelContext = modelContext
    }

    // MARK: - Camera Permission

    /// Check current camera permission status
    /// - Parameter completion: Returns true if camera permission is granted
    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                completion(true)
            case .notDetermined:
                self.requestCameraPermission(completion: completion)
            case .denied, .restricted:
                self.lastError = CameraError.permissionDenied
                completion(false)
            @unknown default:
                self.lastError = CameraError.permissionUnknown
                completion(false)
            }
        }
    }

    /// Request camera permission from user
    /// - Parameter completion: Returns true if permission is granted
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    completion(true)
                } else {
                    self.lastError = CameraError.permissionDenied
                    completion(false)
                }
            }
        }
    }

    // MARK: - Camera Initialization

    /// Initialize camera for photo capture
    /// Throws error if camera cannot be initialized
    func initializeCamera() async throws {
        // Check permission first
        let hasPermission = await withCheckedContinuation { continuation in
            checkCameraPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        guard hasPermission else {
            throw CameraError.permissionRequired
        }

        // Setup capture session
        await setupCaptureSession()
    }

    /// Setup the AVFoundation capture session
    private func setupCaptureSession() async {
        print("🔍 [CameraManager.setupCaptureSession] START - Thread: \(Task.currentPriority != nil ? "MAIN" : "BACKGROUND")")

        do {
            let session = AVCaptureSession()
            session.sessionPreset = .photo

            // Get back camera device
            guard let device = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .back
            ).devices.first else {
                print("❌ [CameraManager.setupCaptureSession] No camera device available")
                await MainActor.run {
                    lastError = CameraError.cameraUnavailable
                }
                return
            }

            // Setup input
            let input = try AVCaptureDeviceInput(device: device)

            // Setup output
            let output = AVCapturePhotoOutput()

            // Configure session
            if session.canAddInput(input) && session.canAddOutput(output) {
                session.addInput(input)
                session.addOutput(output)

                // Store references - ensure thread safety
            await MainActor.run {
                print("🔍 [CameraManager.setupCaptureSession] Storing references on main thread")
                self.captureSession = session
                self.captureDevice = device
                self.photoOutput = output
                self.isInitialized = true
                self.lastError = nil

                // Start session - CRITICAL: AVFoundation must run on main thread
                print("🔍 [CameraManager.setupCaptureSession] Starting session on main thread")
                session.startRunning()
                print("✅ [CameraManager.setupCaptureSession] Session started successfully")
            }
        } else {
            print("❌ [CameraManager.setupCaptureSession] Failed to add input")
            await MainActor.run {
                lastError = CameraError.configurationFailed
            }
        }
        } catch {
            print("❌ [CameraManager.setupCaptureSession] Configuration error: \(error.localizedDescription)")
            await MainActor.run {
                lastError = CameraError.configurationFailed
            }
        }
    }

    // MARK: - Photo Capture

    /// Capture a photo using the camera
    /// Throws error if camera is not initialized or capture fails
    func capturePhoto() async throws {
        print("🔍 [CameraManager.capturePhoto] START - Thread: \(Task.currentPriority != nil ? "MAIN" : "BACKGROUND")")

        guard isInitialized else {
            print("❌ [CameraManager.capturePhoto] Camera not initialized")
            throw CameraError.notInitialized
        }

        guard !isCapturingPhoto else {
            print("❌ [CameraManager.capturePhoto] Capture already in progress")
            throw CameraError.captureInProgress
        }

        return try await withCheckedThrowingContinuation { continuation in
            print("🔍 [CameraManager.capturePhoto] Setting up continuation - Thread: \(Thread.isMainThread ? "MAIN" : "BACKGROUND")")
            isCapturingPhoto = true
            lastError = nil

            // Setup photo capture completion
            photoCaptureCompletion = { image, error in
                print("🔍 [CameraManager.photoCaptureCompletion] Callback - Thread: \(Thread.isMainThread ? "MAIN" : "BACKGROUND")")
                DispatchQueue.main.async {
                    print("🔍 [CameraManager.photoCaptureCompletion] Main async block - Thread: \(Thread.isMainThread ? "MAIN" : "BACKGROUND")")
                    self.isCapturingPhoto = false

                    if let error = error {
                        print("❌ [CameraManager.photoCaptureCompletion] Error: \(error.localizedDescription)")
                        self.lastError = error
                        continuation.resume(throwing: error)
                    } else if let image = image {
                        print("✅ [CameraManager.photoCaptureCompletion] Success - Image captured")
                        self.capturedImage = image
                        self.lastError = nil
                        continuation.resume()
                    } else {
                        print("❌ [CameraManager.photoCaptureCompletion] No image captured")
                        self.lastError = CameraError.captureFailed
                        continuation.resume(throwing: CameraError.captureFailed)
                    }
                }
            }

            // Capture photo
            let settings = AVCapturePhotoSettings()
            settings.isHighResolutionPhotoEnabled = true

            print("🔍 [CameraManager.capturePhoto] About to call capturePhoto - Thread: \(Task.currentPriority != nil ? "MAIN" : "BACKGROUND")")
            photoOutput?.capturePhoto(with: settings, delegate: PhotoCaptureDelegate(completion: photoCaptureCompletion!))
            print("🔍 [CameraManager.capturePhoto] capturePhoto called - Thread: \(Task.currentPriority != nil ? "MAIN" : "BACKGROUND")")
        }

        print("✅ [CameraManager.capturePhoto] COMPLETED - Thread: \(Task.currentPriority != nil ? "MAIN" : "BACKGROUND")")
    }

    /// Create a LogEntry with the captured image
    /// - Parameters:
    ///   - spot: The Spot to associate with the LogEntry
    ///   - note: Optional medical notes
    ///   - painScore: Pain score (0-10)
    ///   - hasBleeding: Whether there is bleeding
    ///   - hasItching: Whether there is itching
    ///   - isSwollen: Whether the area is swollen
    ///   - estimatedSize: Estimated size in cm
    /// - Returns: Created LogEntry object
    func createLogEntry(
        spot: Spot,
        note: String = "",
        painScore: Int = 0,
        hasBleeding: Bool = false,
        hasItching: Bool = false,
        isSwollen: Bool = false,
        estimatedSize: Double? = nil
    ) async throws -> LogEntry {
        guard let image = capturedImage else {
            throw CameraError.noImageCaptured
        }

        guard let imageManager = imageManager else {
            throw CameraError.imageManagerNotAvailable
        }

        // Generate unique filename
        let filename = generateImageFilename()

        // Save image
        try imageManager.saveImage(image: image, filename: filename)

        // Create log entry
        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: filename,
            note: note,
            painScore: painScore,
            hasBleeding: hasBleeding,
            hasItching: hasItching,
            isSwollen: isSwollen,
            estimatedSize: estimatedSize,
            spot: spot
        )

        // Save to database if model context is available
        if let modelContext = modelContext {
            modelContext.insert(logEntry)
            try modelContext.save()
        }

        return logEntry
    }

    // MARK: - Camera Controls

    /// Switch between front and back cameras
    func switchCamera() async throws {
        guard isInitialized else {
            throw CameraError.notInitialized
        }

        // This is a simplified implementation
        // In a production app, you'd want to handle device switching more carefully
        let newPosition: AVCaptureDevice.Position = captureDevice?.position == .back ? .front : .back

        guard let newDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: newPosition
        ).devices.first else {
            throw CameraError.deviceNotFound
        }

        // Reconfigure session with new device
        captureSession?.beginConfiguration()

        // Remove current input
        if let currentInput = captureSession?.inputs.first as? AVCaptureDeviceInput {
            captureSession?.removeInput(currentInput)
        }

        // Add new input
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            if captureSession?.canAddInput(newInput) == true {
                captureSession?.addInput(newInput)
                captureDevice = newDevice
            } else {
                throw CameraError.configurationFailed
            }
        } catch {
            throw CameraError.configurationFailed
        }

        captureSession?.commitConfiguration()
    }

    // MARK: - Camera Preview

    /// Get preview layer for camera display
    /// - Returns: AVCaptureVideoPreviewLayer configured with current session
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        print("🔍 [CameraManager.getPreviewLayer] START - Thread: \(Task.currentPriority != nil ? "MAIN" : "BACKGROUND")")

        guard let session = captureSession else {
            print("❌ [CameraManager.getPreviewLayer] No session available")
            return nil
        }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        previewLayer = layer

        print("✅ [CameraManager.getPreviewLayer] Success - Layer created on thread: \(Task.currentPriority != nil ? "MAIN" : "BACKGROUND")")
        return layer
    }

    /// Update preview layer bounds
    /// - Parameter bounds: New bounds for the preview layer
    func updatePreviewLayer(bounds: CGRect) {
        print("🔍 [CameraManager.updatePreviewLayer] Thread: \(Task.currentPriority != nil ? "MAIN" : "BACKGROUND")")

        // CRITICAL: Force preview layer updates to main thread
        DispatchQueue.main.async {
            print("🔍 [CameraManager.updatePreviewLayer] Main async block - Thread: \(Task.currentPriority != nil ? "MAIN" : "BACKGROUND")")
            self.previewLayer?.frame = bounds
        }
    }

    // MARK: - Cleanup

    /// Stop camera and cleanup resources
    func stopCamera() {
        captureSession?.stopRunning()
        captureSession = nil
        captureDevice = nil
        photoOutput = nil
        previewLayer = nil
        isInitialized = false
        isCapturingPhoto = false
        photoCaptureCompletion = nil
    }

    // MARK: - Utility Methods

    /// Generate unique filename for captured image
    private func generateImageFilename() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString.prefix(8)
        return "spoton_\(timestamp)_\(uuid).jpg"
    }
}

// MARK: - Camera Error Types

enum CameraError: Error, LocalizedError {
    case permissionRequired
    case permissionDenied
    case permissionUnknown
    case cameraUnavailable
    case configurationFailed
    case notInitialized
    case captureInProgress
    case captureFailed
    case noImageCaptured
    case deviceNotFound
    case imageManagerNotAvailable

    var errorDescription: String? {
        switch self {
        case .permissionRequired:
            return "Camera permission is required to take photos"
        case .permissionDenied:
            return "Camera access was denied. Please enable it in Settings."
        case .permissionUnknown:
            return "Unknown camera permission status"
        case .cameraUnavailable:
            return "Camera is not available on this device"
        case .configurationFailed:
            return "Failed to configure camera"
        case .notInitialized:
            return "Camera is not initialized"
        case .captureInProgress:
            return "Photo capture is already in progress"
        case .captureFailed:
            return "Failed to capture photo"
        case .noImageCaptured:
            return "No image has been captured"
        case .deviceNotFound:
            return "Camera device not found"
        case .imageManagerNotAvailable:
            return "Image manager is not available"
        }
    }
}

// MARK: - Photo Capture Delegate

private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?, Error?) -> Void

    init(completion: @escaping (UIImage?, Error?) -> Void) {
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("🔍 [PhotoCaptureDelegate.photoOutput] START - Thread: \(Task.currentPriority != nil ? "MAIN" : "BACKGROUND")")

        // CRITICAL: Force completion callback to main thread
        DispatchQueue.main.async {
            print("🔍 [PhotoCaptureDelegate.photoOutput] Main async block - Thread: \(Task.currentPriority != nil ? "MAIN" : "BACKGROUND")")

            if let error = error {
                print("❌ [PhotoCaptureDelegate.photoOutput] Error: \(error.localizedDescription)")
                self.completion(nil, error)
                return
            }

            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                print("❌ [PhotoCaptureDelegate.photoOutput] Failed to process image data")
                self.completion(nil, CameraError.captureFailed)
                return
            }

            print("✅ [PhotoCaptureDelegate.photoOutput] Success - Image processed on main thread")
            self.completion(image, nil)
        }
    }
}