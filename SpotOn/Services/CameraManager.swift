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
    @MainActor
    func initializeCamera() async throws {
        // Check permission first
        let hasPermission = await checkCameraPermissionAsync()

        guard hasPermission else {
            throw CameraError.permissionRequired
        }

        // Setup capture session
        await setupCaptureSession()
    }

    /// Async camera permission check for better thread safety
    private func checkCameraPermissionAsync() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await requestCameraPermissionAsync()
        case .denied, .restricted:
            await MainActor.run {
                self.lastError = CameraError.permissionDenied
            }
            return false
        @unknown default:
            await MainActor.run {
                self.lastError = CameraError.permissionUnknown
            }
            return false
        }
    }

    /// Async camera permission request
    private func requestCameraPermissionAsync() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Setup the AVFoundation capture session
    @MainActor
    private func setupCaptureSession() async {
        print("🔍 [CameraManager.setupCaptureSession] START")
        do {
            print("🔍 [CameraManager.setupCaptureSession] Creating AVCaptureSession")
            let session = AVCaptureSession()
            session.sessionPreset = .photo
            print("🔍 [CameraManager.setupCaptureSession] Session created with preset: .photo")

            // Get back camera device
            print("🔍 [CameraManager.setupCaptureSession] Looking for back camera device")
            guard let device = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .back
            ).devices.first else {
                print("❌ [CameraManager.setupCaptureSession] No back camera found")
                await MainActor.run {
                    self.lastError = CameraError.cameraUnavailable
                }
                return
            }
            print("🔍 [CameraManager.setupCaptureSession] Found back camera device: \(device.localizedName)")

            // Setup input
            print("🔍 [CameraManager.setupCaptureSession] Creating device input")
            let input = try AVCaptureDeviceInput(device: device)
            print("🔍 [CameraManager.setupCaptureSession] Device input created successfully")

            // Setup output
            print("🔍 [CameraManager.setupCaptureSession] Creating photo output")
            let output = AVCapturePhotoOutput()
            print("🔍 [CameraManager.setupCaptureSession] Photo output created successfully")

            // Configure session
            print("🔍 [CameraManager.setupCaptureSession] Checking if session can add input/output")
            if session.canAddInput(input) && session.canAddOutput(output) {
                print("🔍 [CameraManager.setupCaptureSession] Adding input to session")
                session.addInput(input)
                print("🔍 [CameraManager.setupCaptureSession] Adding output to session")
                session.addOutput(output)

                // Store references
                await MainActor.run {
                    self.captureSession = session
                    self.captureDevice = device
                    self.photoOutput = output
                    self.isInitialized = true
                    self.lastError = nil
                }
                print("🔍 [CameraManager.setupCaptureSession] Session configured successfully")

                // Start session - OPTIMIZED: Start on background thread for better performance
                print("🔍 [CameraManager.setupCaptureSession] Starting session - OPTIMIZED BACKGROUND THREAD")
                await Task.detached(priority: .high) {
                    session.startRunning()
                }.value
                print("🔍 [CameraManager.setupCaptureSession] Session started successfully")
            } else {
                print("❌ [CameraManager.setupCaptureSession] Cannot add input/output to session")
                await MainActor.run {
                    self.lastError = CameraError.configurationFailed
                }
            }
        } catch {
            print("❌ [CameraManager.setupCaptureSession] Error: \(error.localizedDescription)")
            await MainActor.run {
                self.lastError = CameraError.configurationFailed
            }
        }
        print("🔍 [CameraManager.setupCaptureSession] END")
    }

    // MARK: - Photo Capture

    /// Capture a photo using the camera
    /// Throws error if camera is not initialized or capture fails
    func capturePhoto() async throws {
        guard isInitialized else {
            throw CameraError.notInitialized
        }

        guard !isCapturingPhoto else {
            throw CameraError.captureInProgress
        }

        return try await withCheckedThrowingContinuation { continuation in
            isCapturingPhoto = true
            lastError = nil

            // Setup photo capture completion
            photoCaptureCompletion = { image, error in
                DispatchQueue.main.async {
                    self.isCapturingPhoto = false

                    if let error = error {
                        self.lastError = error
                        continuation.resume(throwing: error)
                    } else if let image = image {
                        self.capturedImage = image
                        self.lastError = nil
                        continuation.resume()
                    } else {
                        self.lastError = CameraError.captureFailed
                        continuation.resume(throwing: CameraError.captureFailed)
                    }
                }
            }

            // Capture photo
            let settings = AVCapturePhotoSettings()
            settings.isHighResolutionPhotoEnabled = true

            photoOutput?.capturePhoto(with: settings, delegate: PhotoCaptureDelegate(completion: photoCaptureCompletion!))
        }
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
        guard let session = captureSession else { return nil }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        previewLayer = layer
        return layer
    }

    /// Update preview layer bounds
    /// - Parameter bounds: New bounds for the preview layer
    func updatePreviewLayer(bounds: CGRect) {
        previewLayer?.frame = bounds
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
        if let error = error {
            completion(nil, error)
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completion(nil, CameraError.captureFailed)
            return
        }

        completion(image, nil)
    }
}