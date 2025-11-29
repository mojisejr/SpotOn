//
//  CameraTestFixtures.swift
//  SpotOnTests
//
//  Created by Claude on 11/29/25.
//

import Foundation
import UIKit
import AVFoundation

/// Test fixtures for camera testing
struct CameraTestFixtures {

    // MARK: - Mock Image Data

    /// Creates a mock test image for camera testing
    static func createTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Create a simple test image with medical theme colors
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor.white.setFill()
            let centerRect = CGRect(
                x: size.width * 0.25,
                y: size.height * 0.25,
                width: size.width * 0.5,
                height: size.height * 0.5
            )
            context.fill(centerRect)
        }
    }

    /// Creates a mock JPEG data for testing
    static func createTestJPEGData() -> Data {
        let image = createTestImage()
        return image.jpegData(compressionQuality: 0.9) ?? Data()
    }

    /// Creates a mock PNG data for testing
    static func createTestPNGData() -> Data {
        let image = createTestImage()
        return image.pngData() ?? Data()
    }

    // MARK: - Mock Camera Permission States

    struct MockPermissionStates {
        static let authorized = "authorized"
        static let denied = "denied"
        static let notDetermined = "notDetermined"
        static let restricted = "restricted"
        static let unknown = "unknown"
    }

    // MARK: - Mock Camera Errors

    enum MockCameraError: Error, LocalizedError {
        case cameraUnavailable
        case permissionDenied
        case configurationFailed
        case captureFailed
        case deviceNotFound

        var errorDescription: String? {
            switch self {
            case .cameraUnavailable:
                return "Camera is not available on this device"
            case .permissionDenied:
                return "Camera permission was denied"
            case .configurationFailed:
                return "Failed to configure camera session"
            case .captureFailed:
                return "Failed to capture photo"
            case .deviceNotFound:
                return "Camera device not found"
            }
        }
    }

    // MARK: - Mock Log Entry Data

    struct MockLogEntryData {
        static let validNote = "Test medical observation"
        static let validPainScore = 3
        static let validHasBleeding = false
        static let validHasItching = true
        static let validIsSwollen = false
        static let validEstimatedSize: Double? = 2.5
    }

    // MARK: - Mock File Names

    struct MockFileNames {
        static let validJPEG = "test_image.jpg"
        static let validPNG = "test_image.png"
        static let invalidExtension = "test_image.txt"
        static let emptyName = ""
        static let pathTraversal = "../../../test.jpg"
        static let absolutePath = "/etc/test.jpg"
    }

    // MARK: - Timing Utilities

    struct Timing {
        static let shortDelay: TimeInterval = 0.1
        static let mediumDelay: TimeInterval = 0.5
        static let longDelay: TimeInterval = 2.0
        static let cameraInitializationTimeout: TimeInterval = 5.0
    }

    // MARK: - Mock Camera Configuration

    struct MockCameraConfiguration {
        static let defaultSessionPreset = AVCaptureSession.Preset.photo
        static let defaultDevicePosition = AVCaptureDevice.Position.back
        static let defaultFlashMode = AVCaptureDevice.FlashMode.off
        static let supportedSessionPresets: [AVCaptureSession.Preset] = [
            .photo, .highResolutionPhoto, .medium, .low
        ]
        static let supportedDevicePositions: [AVCaptureDevice.Position] = [
            .back, .front
        ]
    }
}