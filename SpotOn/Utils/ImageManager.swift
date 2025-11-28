import UIKit
import Foundation
import SwiftUI
import Combine

/// ImageManager handles local storage and retrieval of images for the SpotOn app
/// Provides thread-safe operations for saving, loading, and deleting images in the Documents directory
class ImageManager: ObservableObject {

    // MARK: - Properties

    // MARK: - Published Properties
    @Published var selectedImage: UIImage?
    @Published var savedImages: [ImageInfo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Thread-safe queue for file operations
    private let fileQueue = DispatchQueue(label: "com.spoton.imageManager", attributes: .concurrent)

    struct ImageInfo {
        let id: UUID
        let filename: String
        let url: URL
        let size: Int64
        let creationDate: Date
        let format: String

        var uiImage: UIImage? {
            return UIImage(contentsOfFile: url.path)
        }
    }

    // MARK: - Initialization
    init() {
        loadSavedImages()
    }

    /// Supported image formats
    private enum ImageFormat: String, CaseIterable {
        case png = "png"
        case jpg = "jpg"
        case jpeg = "jpeg"
    }

    // MARK: - Public Methods

    /// Save an image to the Documents directory with the specified filename
    /// - Parameters:
    ///   - image: The UIImage to save
    ///   - filename: The filename (must include .png or .jpg/.jpeg extension)
    /// - Throws: ImageManagerError for various failure conditions
    func saveImage(image: UIImage?, filename: String) throws {
        // Validate inputs
        guard let image = image else {
            throw ImageManagerError.invalidImage
        }

        try validateFilename(filename)

        let fileURL = try getFileURL(for: filename)

        try fileQueue.sync(flags: .barrier) {
            // Convert image to data based on file extension
            let format = try getImageFormat(from: filename)
            let imageData: Data

            switch format {
            case .png:
                guard let data = image.pngData() else {
                    throw ImageManagerError.saveError
                }
                imageData = data
            case .jpg, .jpeg:
                guard let data = image.jpegData(compressionQuality: 0.9) else {
                    throw ImageManagerError.saveError
                }
                imageData = data
            }

            // Write data to file
            do {
                try imageData.write(to: fileURL)
            } catch {
                throw ImageManagerError.saveError
            }
        }
    }

    /// Load an image from the Documents directory
    /// - Parameter filename: The filename of the image to load
    /// - Returns: The loaded UIImage
    /// - Throws: ImageManagerError for various failure conditions
    func loadImage(filename: String) throws -> UIImage {
        try validateFilename(filename)

        let fileURL = try getFileURL(for: filename)

        return try fileQueue.sync {
            // Check if file exists
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw ImageManagerError.fileNotFound
            }

            // Load image from file
            guard let image = UIImage(contentsOfFile: fileURL.path) else {
                throw ImageManagerError.loadError
            }

            return image
        }
    }

    /// Delete an image from the Documents directory
    /// - Parameter filename: The filename of the image to delete
    /// - Throws: ImageManagerError for various failure conditions
    func deleteImage(filename: String) throws {
        try validateFilename(filename)

        let fileURL = try getFileURL(for: filename)

        try fileQueue.sync(flags: .barrier) {
            // Check if file exists
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw ImageManagerError.fileNotFound
            }

            // Delete file
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                throw ImageManagerError.deleteError
            }
        }
    }

    /// Check if an image file exists in the Documents directory
    /// - Parameter filename: The filename to check
    /// - Returns: true if the file exists, false otherwise
    func fileExists(filename: String) -> Bool {
        // Basic validation - return false for empty filenames
        guard !filename.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        do {
            let fileURL = try getFileURL(for: filename)
            return fileQueue.sync {
                return FileManager.default.fileExists(atPath: fileURL.path)
            }
        } catch {
            return false
        }
    }

    /// Get the Documents directory URL
    /// - Returns: URL pointing to the app's Documents directory
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsDirectory = paths.first else {
            fatalError("Could not get Documents directory")
        }
        return documentsDirectory
    }

    /// Get all saved images with their metadata
    /// - Returns: Array of ImageInfo objects
    func getAllSavedImages() -> [ImageInfo] {
        return savedImages
    }

    /// Delete all saved images
    /// - Throws: ImageManagerError if deletion fails
    func deleteAllImages() throws {
        let documentsDirectory = getDocumentsDirectory()
        let fileManager = FileManager.default

        do {
            let files = try fileManager.contentsOfDirectory(atPath: documentsDirectory.path)
            for file in files {
                let fileURL = documentsDirectory.appendingPathComponent(file)
                if fileURL.pathExtension.lowercased() == "png" ||
                   fileURL.pathExtension.lowercased() == "jpg" ||
                   fileURL.pathExtension.lowercased() == "jpeg" {
                    try fileManager.removeItem(at: fileURL)
                }
            }

            DispatchQueue.main.async {
                self.savedImages.removeAll()
            }
        } catch {
            throw ImageManagerError.deleteError
        }
    }

    /// Get image info for a specific filename
    /// - Parameter filename: The filename to look up
    /// - Returns: ImageInfo if found, nil otherwise
    func getImageInfo(for filename: String) -> ImageInfo? {
        return savedImages.first { $0.filename == filename }
    }

    // MARK: - Private Methods

    /// Load all saved images from documents directory
    private func loadSavedImages() {
        let documentsDirectory = getDocumentsDirectory()
        let fileManager = FileManager.default

        do {
            let files = try fileManager.contentsOfDirectory(atPath: documentsDirectory.path)
            var images: [ImageInfo] = []

            for file in files {
                let fileURL = documentsDirectory.appendingPathComponent(file)
                if fileURL.pathExtension.lowercased() == "png" ||
                   fileURL.pathExtension.lowercased() == "jpg" ||
                   fileURL.pathExtension.lowercased() == "jpeg" {

                    let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                    let fileSize = attributes[.size] as? Int64 ?? 0
                    let creationDate = attributes[.creationDate] as? Date ?? Date()
                    let format = fileURL.pathExtension.uppercased()

                    let imageInfo = ImageInfo(
                        id: UUID(),
                        filename: file,
                        url: fileURL,
                        size: fileSize,
                        creationDate: creationDate,
                        format: format
                    )
                    images.append(imageInfo)
                }
            }

            DispatchQueue.main.async {
                self.savedImages = images.sorted { $0.creationDate > $1.creationDate }
            }
        } catch {
            print("Failed to load saved images: \(error)")
        }
    }

    // MARK: - Private Methods

    /// Validate that the filename is safe and valid
    /// - Parameter filename: The filename to validate
    /// - Throws: ImageManagerError.invalidFilename if validation fails
    private func validateFilename(_ filename: String) throws {
        // Check for empty filename
        let trimmedFilename = filename.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFilename.isEmpty else {
            throw ImageManagerError.invalidFilename
        }

        // Check for path traversal attacks
        guard !filename.contains("../") && !filename.contains("..\\") else {
            throw ImageManagerError.invalidFilename
        }

        // Check for absolute paths
        guard !filename.hasPrefix("/") else {
            throw ImageManagerError.invalidFilename
        }

        // Check for supported format
        let format = try getImageFormat(from: filename)
        guard ImageFormat.allCases.contains(where: { $0.rawValue.lowercased() == format.rawValue.lowercased() }) else {
            throw ImageManagerError.unsupportedFormat
        }
    }

    /// Extract image format from filename
    /// - Parameter filename: The filename to extract format from
    /// - Returns: ImageFormat enum value
    /// - Throws: ImageManagerError.unsupportedFormat if format is not supported
    private func getImageFormat(from filename: String) throws -> ImageFormat {
        guard let fileExtension = filename.components(separatedBy: ".").last?.lowercased() else {
            throw ImageManagerError.unsupportedFormat
        }

        switch fileExtension {
        case "png":
            return .png
        case "jpg", "jpeg":
            return .jpg
        default:
            throw ImageManagerError.unsupportedFormat
        }
    }

    /// Get the full file URL for a given filename
    /// - Parameter filename: The filename
    /// - Returns: URL in the Documents directory
    /// - Throws: ImageManagerError if URL cannot be created
    private func getFileURL(for filename: String) throws -> URL {
        let documentsDirectory = getDocumentsDirectory()
        let fileURL = documentsDirectory.appendingPathComponent(filename)

        // Additional security check - ensure the URL is within the documents directory
        guard fileURL.path.contains(documentsDirectory.path) else {
            throw ImageManagerError.invalidFilename
        }

        return fileURL
    }
}

// MARK: - ImageManager Error Types

enum ImageManagerError: Error, Equatable {
    case invalidImage
    case invalidFilename
    case fileNotFound
    case unsupportedFormat
    case saveError
    case loadError
    case deleteError

    var localizedDescription: String {
        switch self {
        case .invalidImage:
            return "The provided image is invalid or nil"
        case .invalidFilename:
            return "The filename is invalid, empty, or contains forbidden characters"
        case .fileNotFound:
            return "The requested image file was not found"
        case .unsupportedFormat:
            return "The image format is not supported. Please use PNG or JPEG"
        case .saveError:
            return "Failed to save the image file"
        case .loadError:
            return "Failed to load the image file. The file may be corrupted"
        case .deleteError:
            return "Failed to delete the image file"
        }
    }
}