import XCTest
import UIKit
@testable import SpotOn

final class ImageManagerTests: XCTestCase {

    var imageManager: ImageManager!
    var testImage: UIImage!
    var testFilename: String!

    override func setUpWithError() throws {
        try super.setUpWithError()
        imageManager = ImageManager()

        // Create a test image (1x1 red pixel)
        testImage = UIImage(color: .red, size: CGSize(width: 1, height: 1))
        testFilename = "test_image_\(UUID().uuidString).png"
    }

    override func tearDownWithError() throws {
        // Clean up any test files
        try? imageManager.deleteImage(filename: testFilename)

        imageManager = nil
        testImage = nil
        testFilename = nil

        try super.tearDownWithError()
    }

    // MARK: - Save Image Tests

    func testSaveImage_ValidImageAndFilename_ShouldCreateFile() throws {
        // When
        try imageManager.saveImage(image: testImage, filename: testFilename)

        // Then
        let fileExists = imageManager.fileExists(filename: testFilename)
        XCTAssertTrue(fileExists, "Image file should exist after saving")
    }

    func testSaveImage_ValidImageWithJPEGExtension_ShouldCreateFile() throws {
        // Given
        let jpegFilename = "test_image_\(UUID().uuidString).jpg"

        // When
        try imageManager.saveImage(image: testImage, filename: jpegFilename)

        // Then
        let fileExists = imageManager.fileExists(filename: jpegFilename)
        XCTAssertTrue(fileExists, "JPEG image file should exist after saving")

        // Cleanup
        try? imageManager.deleteImage(filename: jpegFilename)
    }

    func testSaveImage_NilImage_ShouldThrowError() {
        // Given
        let nilImage: UIImage? = nil

        // When & Then
        XCTAssertThrowsError(try imageManager.saveImage(image: nilImage!, filename: testFilename)) { error in
            XCTAssertEqual(error as? ImageManagerError, .invalidImage)
        }
    }

    func testSaveImage_EmptyFilename_ShouldThrowError() {
        // Given
        let emptyFilename = ""

        // When & Then
        XCTAssertThrowsError(try imageManager.saveImage(image: testImage, filename: emptyFilename)) { error in
            XCTAssertEqual(error as? ImageManagerError, .invalidFilename)
        }
    }

    func testSaveImage_WhitespaceOnlyFilename_ShouldThrowError() {
        // Given
        let whitespaceFilename = "   "

        // When & Then
        XCTAssertThrowsError(try imageManager.saveImage(image: testImage, filename: whitespaceFilename)) { error in
            XCTAssertEqual(error as? ImageManagerError, .invalidFilename)
        }
    }

    func testSaveImage_FilenameWithPathTraversal_ShouldThrowError() {
        // Given
        let maliciousFilename = "../../../malicious.png"

        // When & Then
        XCTAssertThrowsError(try imageManager.saveImage(image: testImage, filename: maliciousFilename)) { error in
            XCTAssertEqual(error as? ImageManagerError, .invalidFilename)
        }
    }

    func testSaveImage_UnsupportedFormat_ShouldThrowError() {
        // Given
        let unsupportedFilename = "test_image.bmp"

        // When & Then
        XCTAssertThrowsError(try imageManager.saveImage(image: testImage, filename: unsupportedFilename)) { error in
            XCTAssertEqual(error as? ImageManagerError, .unsupportedFormat)
        }
    }

    // MARK: - Load Image Tests

    func testLoadImage_ExistingFile_ShouldReturnImage() throws {
        // Given
        try imageManager.saveImage(image: testImage, filename: testFilename)

        // When
        let loadedImage = try imageManager.loadImage(filename: testFilename)

        // Then
        XCTAssertNotNil(loadedImage, "Loaded image should not be nil")
        XCTAssertEqual(loadedImage?.size.width, testImage.size.width, accuracy: 0.1)
        XCTAssertEqual(loadedImage?.size.height, testImage.size.height, accuracy: 0.1)
    }

    func testLoadImage_NonExistentFile_ShouldThrowError() {
        // Given
        let nonExistentFilename = "non_existent_image.png"

        // When & Then
        XCTAssertThrowsError(try imageManager.loadImage(filename: nonExistentFilename)) { error in
            XCTAssertEqual(error as? ImageManagerError, .fileNotFound)
        }
    }

    func testLoadImage_EmptyFilename_ShouldThrowError() {
        // Given
        let emptyFilename = ""

        // When & Then
        XCTAssertThrowsError(try imageManager.loadImage(filename: emptyFilename)) { error in
            XCTAssertEqual(error as? ImageManagerError, .invalidFilename)
        }
    }

    func testLoadImage_CorruptedFile_ShouldThrowError() throws {
        // Given
        try imageManager.saveImage(image: testImage, filename: testFilename)

        // Corrupt the file by writing invalid data
        let documentsPath = imageManager.getDocumentsDirectory()
        let fileURL = documentsPath.appendingPathComponent(testFilename)
        try "corrupted data".write(to: fileURL, atomically: true, encoding: .utf8)

        // When & Then
        XCTAssertThrowsError(try imageManager.loadImage(filename: testFilename)) { error in
            XCTAssertTrue(error is ImageManagerError)
        }
    }

    // MARK: - Delete Image Tests

    func testDeleteImage_ExistingFile_ShouldRemoveFile() throws {
        // Given
        try imageManager.saveImage(image: testImage, filename: testFilename)
        XCTAssertTrue(imageManager.fileExists(filename: testFilename), "File should exist before deletion")

        // When
        try imageManager.deleteImage(filename: testFilename)

        // Then
        XCTAssertFalse(imageManager.fileExists(filename: testFilename), "File should not exist after deletion")
    }

    func testDeleteImage_NonExistentFile_ShouldThrowError() {
        // Given
        let nonExistentFilename = "non_existent_image.png"

        // When & Then
        XCTAssertThrowsError(try imageManager.deleteImage(filename: nonExistentFilename)) { error in
            XCTAssertEqual(error as? ImageManagerError, .fileNotFound)
        }
    }

    func testDeleteImage_EmptyFilename_ShouldThrowError() {
        // Given
        let emptyFilename = ""

        // When & Then
        XCTAssertThrowsError(try imageManager.deleteImage(filename: emptyFilename)) { error in
            XCTAssertEqual(error as? ImageManagerError, .invalidFilename)
        }
    }

    // MARK: - File Path Management Tests

    func testGetDocumentsDirectory_ShouldReturnValidPath() {
        // When
        let documentsPath = imageManager.getDocumentsDirectory()

        // Then
        XCTAssertNotNil(documentsPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: documentsPath.path), "Documents directory should exist")
    }

    func testFileExists_ExistingFile_ShouldReturnTrue() throws {
        // Given
        try imageManager.saveImage(image: testImage, filename: testFilename)

        // When
        let exists = imageManager.fileExists(filename: testFilename)

        // Then
        XCTAssertTrue(exists)
    }

    func testFileExists_NonExistentFile_ShouldReturnFalse() {
        // Given
        let nonExistentFilename = "non_existent_image.png"

        // When
        let exists = imageManager.fileExists(filename: nonExistentFilename)

        // Then
        XCTAssertFalse(exists)
    }

    func testFileExists_EmptyFilename_ShouldReturnFalse() {
        // Given
        let emptyFilename = ""

        // When
        let exists = imageManager.fileExists(filename: emptyFilename)

        // Then
        XCTAssertFalse(exists)
    }

    // MARK: - Image Format Tests

    func testSaveAndLoadPNGImage_ShouldMaintainQuality() throws {
        // Given
        let pngFilename = "test_image_\(UUID().uuidString).png"

        // When
        try imageManager.saveImage(image: testImage, filename: pngFilename)
        let loadedImage = try imageManager.loadImage(filename: pngFilename)

        // Then
        XCTAssertNotNil(loadedImage)
        XCTAssertEqual(loadedImage?.size.width, testImage.size.width, accuracy: 0.1)
        XCTAssertEqual(loadedImage?.size.height, testImage.size.height, accuracy: 0.1)

        // Cleanup
        try? imageManager.deleteImage(filename: pngFilename)
    }

    func testSaveAndLoadJPEGImage_ShouldMaintainQuality() throws {
        // Given
        let jpegFilename = "test_image_\(UUID().uuidString).jpg"

        // When
        try imageManager.saveImage(image: testImage, filename: jpegFilename)
        let loadedImage = try imageManager.loadImage(filename: jpegFilename)

        // Then
        XCTAssertNotNil(loadedImage)
        XCTAssertEqual(loadedImage?.size.width, testImage.size.width, accuracy: 0.1)
        XCTAssertEqual(loadedImage?.size.height, testImage.size.height, accuracy: 0.1)

        // Cleanup
        try? imageManager.deleteImage(filename: jpegFilename)
    }

    // MARK: - Large Image Tests

    func testSaveAndLoadLargeImage_ShouldHandleCorrectly() throws {
        // Given
        let largeImage = UIImage(color: .blue, size: CGSize(width: 1000, height: 1000))
        let largeImageFilename = "large_image_\(UUID().uuidString).png"

        // When
        try imageManager.saveImage(image: largeImage, filename: largeImageFilename)
        let loadedImage = try imageManager.loadImage(filename: largeImageFilename)

        // Then
        XCTAssertNotNil(loadedImage)
        XCTAssertEqual(loadedImage?.size.width, largeImage.size.width, accuracy: 1.0)
        XCTAssertEqual(loadedImage?.size.height, largeImage.size.height, accuracy: 1.0)

        // Cleanup
        try? imageManager.deleteImage(filename: largeImageFilename)
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentSaveAndLoad_ShouldHandleCorrectly() throws {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent save and load operations")
        let concurrentOperations = 10
        var completedOperations = 0
        var errors: [Error] = []

        // When
        for i in 0..<concurrentOperations {
            let filename = "concurrent_test_\(i)_\(UUID().uuidString).png"

            DispatchQueue.global(qos: .background).async {
                do {
                    // Save
                    try self.imageManager.saveImage(image: self.testImage, filename: filename)

                    // Load
                    let loadedImage = try self.imageManager.loadImage(filename: filename)
                    XCTAssertNotNil(loadedImage)

                    // Delete
                    try self.imageManager.deleteImage(filename: filename)

                    DispatchQueue.main.async {
                        completedOperations += 1
                        if completedOperations == concurrentOperations {
                            expectation.fulfill()
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        errors.append(error)
                        completedOperations += 1
                        if completedOperations == concurrentOperations {
                            expectation.fulfill()
                        }
                    }
                }
            }
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
        XCTAssertTrue(errors.isEmpty, "No errors should occur during concurrent operations: \(errors)")
    }

    // MARK: - Edge Cases Tests

    func testSpecialCharactersInFilename_ShouldHandleCorrectly() throws {
        // Given
        let specialFilename = "test_image__special_123!@#$%^&()[]{}+.png"

        // When
        try imageManager.saveImage(image: testImage, filename: specialFilename)
        let loadedImage = try imageManager.loadImage(filename: specialFilename)

        // Then
        XCTAssertNotNil(loadedImage)

        // Cleanup
        try? imageManager.deleteImage(filename: specialFilename)
    }

    func testVeryLongFilename_ShouldHandleCorrectly() throws {
        // Given
        let longFilename = String(repeating: "a", count: 200) + ".png"

        // When
        try imageManager.saveImage(image: testImage, filename: longFilename)
        let loadedImage = try imageManager.loadImage(filename: longFilename)

        // Then
        XCTAssertNotNil(loadedImage)

        // Cleanup
        try? imageManager.deleteImage(filename: longFilename)
    }
}

// MARK: - Test Helper Extension

extension UIImage {
    convenience init?(color: UIColor, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

// Note: ImageManagerError is defined in ImageManager.swift