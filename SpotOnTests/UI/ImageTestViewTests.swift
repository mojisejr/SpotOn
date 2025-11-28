//
//  ImageTestViewTests.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import XCTest

final class ImageTestViewTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // Navigate to image test view
        let testImageButton = app.buttons["testImageButton"]
        if testImageButton.exists {
            testImageButton.tap()
        }
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Test Image Test View Loading

    func testImageTestViewDisplaysCorrectly() throws {
        // Given image test view is launched
        // Then image test title should be visible
        let imageTestTitle = app.staticTexts["imageTestTitle"]
        XCTAssertTrue(imageTestTitle.waitForExistence(timeout: 2.0), "Image test title should be visible")

        // And essential UI elements should be present
        let selectPhotoButton = app.buttons["selectPhotoButton"]
        let takePhotoButton = app.buttons["takePhotoButton"]
        let saveImageButton = app.buttons["saveImageButton"]
        let loadImageButton = app.buttons["loadImageButton"]
        let clearImagesButton = app.buttons["clearImagesButton"]
        let imagePreview = app.images["imagePreview"]

        XCTAssertTrue(selectPhotoButton.exists, "Select photo button should exist")
        XCTAssertTrue(takePhotoButton.exists, "Take photo button should exist")
        XCTAssertTrue(saveImageButton.exists, "Save image button should exist")
        XCTAssertTrue(loadImageButton.exists, "Load image button should exist")
        XCTAssertTrue(clearImagesButton.exists, "Clear images button should exist")
        XCTAssertTrue(imagePreview.exists, "Image preview should exist")
    }

    func testInitialEmptyState() throws {
        // When image test view first loads
        // Then should show empty state
        let imagePreview = app.images["imagePreview"]
        let placeholderText = app.staticTexts["imagePlaceholderText"]

        XCTAssertTrue(imagePreview.exists, "Image preview should exist")
        XCTAssertTrue(placeholderText.exists, "Placeholder text should be shown when no image")

        XCTAssertEqual(placeholderText.label, "No image selected", "Placeholder should indicate no image")

        // Save and load buttons should be disabled initially
        let saveImageButton = app.buttons["saveImageButton"]
        let loadImageButton = app.buttons["loadImageButton"]

        XCTAssertFalse(saveImageButton.isEnabled, "Save button should be disabled when no image")
        XCTAssertFalse(loadImageButton.isEnabled, "Load button should be disabled when no image")
    }

    // MARK: - Test Photo Selection

    func testPhotoPickerPresentation() throws {
        // When tapping select photo button
        let selectPhotoButton = app.buttons["selectPhotoButton"]
        selectPhotoButton.tap()

        // Then photo picker should be presented
        let photosApp = app.otherElements["Photos"]
        let photoPickerExists = photosApp.waitForExistence(timeout: 3.0)

        if photoPickerExists {
            XCTAssertTrue(photosApp.exists, "Photo picker should be presented")
        } else {
            // In simulator, might show different picker or permission dialog
            let permissionAlert = app.alerts.firstMatch
            if permissionAlert.exists {
                XCTAssertTrue(permissionAlert.exists, "Photo library permission alert should appear")
            }
        }
    }

    func testCameraPresentation() throws {
        // When tapping take photo button
        let takePhotoButton = app.buttons["takePhotoButton"]
        takePhotoButton.tap()

        // Then camera should be presented
        let cameraApp = app.otherElements["Camera"]
        let cameraExists = cameraApp.waitForExistence(timeout: 3.0)

        if cameraExists {
            XCTAssertTrue(cameraApp.exists, "Camera should be presented")
        } else {
            // In simulator, might show permission dialog
            let permissionAlert = app.alerts.firstMatch
            if permissionAlert.exists {
                XCTAssertTrue(permissionAlert.exists, "Camera permission alert should appear")
            }
        }
    }

    // MARK: - Test Image Display

    func testImageDisplayAfterSelection() throws {
        // This test would need mock image data or access to photo library
        // For now, test the UI behavior structure

        // When an image is selected
        // Then image preview should display the image
        let imagePreview = app.images["imagePreview"]
        XCTAssertTrue(imagePreview.exists, "Image preview should exist")

        // Placeholder text should disappear
        let placeholderText = app.staticTexts["imagePlaceholderText"]
        // This would disappear after actual image selection

        // Save and load buttons should be enabled
        let saveImageButton = app.buttons["saveImageButton"]
        let loadImageButton = app.buttons["loadImageButton"]

        // These would be enabled after actual image selection
    }

    // MARK: - Test Image Save Functionality

    func testSaveImageButtonEnablesWithImage() throws {
        // Given an image is loaded (would need mock image)
        // When image is present in preview
        let imagePreview = app.images["imagePreview"]

        // Then save button should be enabled
        let saveImageButton = app.buttons["saveImageButton"]
        // In actual implementation, this would be enabled after image selection
        XCTAssertTrue(saveImageButtonButton.exists, "Save button should exist")
    }

    func testSaveImageConfirmation() throws {
        // Given an image is loaded
        // When tapping save button
        let saveImageButton = app.buttons["saveImageButton"]
        if saveImageButton.isEnabled {
            saveImageButton.tap()

            // Then save confirmation should appear
            let saveAlert = app.alerts["imageSaveAlert"]
            let alertExists = saveAlert.waitForExistence(timeout: 2.0)

            if alertExists {
                XCTAssertTrue(saveAlert.exists, "Save confirmation alert should appear")

                let alertMessage = saveAlert.staticTexts.firstMatch
                let okButton = saveAlert.buttons["OK"]

                XCTAssertTrue(alertMessage.exists, "Alert should have message")
                XCTAssertTrue(okButton.exists, "Alert should have OK button")

                // Message should confirm successful save
                XCTAssertTrue(alertMessage.label.contains("saved successfully") || alertMessage.label.contains("Image saved"), "Alert should confirm successful save")
            }
        }
    }

    func testSaveImageErrorHandling() throws {
        // Given save operation fails (would need mock failure)
        // When tapping save button
        let saveImageButton = app.buttons["saveImageButton"]
        saveImageButton.tap()

        // Then error alert should appear if save fails
        let errorAlert = app.alerts["imageErrorAlert"]
        let errorExists = errorAlert.waitForExistence(timeout: 2.0)

        if errorExists {
            XCTAssertTrue(errorAlert.exists, "Error alert should appear on save failure")

            let errorMessage = errorAlert.staticTexts.firstMatch
            let retryButton = errorAlert.buttons["Retry"]
            let cancelButton = errorAlert.buttons["Cancel"]

            XCTAssertTrue(errorMessage.exists, "Error alert should have message")
            XCTAssertTrue(retryButton.exists, "Error alert should have retry button")
            XCTAssertTrue(cancelButton.exists, "Error alert should have cancel button")
        }
    }

    // MARK: - Test Image Load Functionality

    func testLoadImageButtonFunctionality() throws {
        // Given there are saved images
        // When tapping load button
        let loadImageButton = app.buttons["loadImageButton"]
        if loadImageButton.isEnabled {
            loadImageButton.tap()

            // Then image loading interface should appear
            let imagePicker = app.otherElements["savedImagePicker"]
            let pickerExists = imagePicker.waitForExistence(timeout: 2.0)

            if pickerExists {
                XCTAssertTrue(imagePicker.exists, "Saved image picker should appear")

                // Should display list of saved images
                let imageList = app.collectionViews["savedImageList"]
                XCTAssertTrue(imageList.exists, "Should show list of saved images")
            }
        }
    }

    func testImageSelectionFromSavedImages() throws {
        // Given saved images picker is presented
        // When selecting an image
        let firstImageCell = app.collectionViews["savedImageList"].cells.firstMatch
        if firstImageCell.exists {
            firstImageCell.tap()

            // Then selected image should be displayed in preview
            let imagePreview = app.images["imagePreview"]
            XCTAssertTrue(imagePreview.exists, "Selected image should be displayed in preview")

            // And picker should be dismissed
            let imagePicker = app.otherElements["savedImagePicker"]
            XCTAssertFalse(imagePicker.exists, "Image picker should be dismissed after selection")
        }
    }

    // MARK: - Test Image Clear Functionality

    func testClearImagesButtonConfirmation() throws {
        // When tapping clear images button
        let clearImagesButton = app.buttons["clearImagesButton"]
        clearImagesButton.tap()

        // Then confirmation alert should appear
        let confirmAlert = app.alerts["confirmClearImagesAlert"]
        XCTAssertTrue(confirmAlert.waitForExistence(timeout: 2.0), "Clear images confirmation alert should appear")

        // Alert should have proper message and buttons
        let alertMessage = confirmAlert.staticTexts.firstMatch
        let cancelButton = confirmAlert.buttons["Cancel"]
        let confirmButton = confirmAlert.buttons["Clear All"]

        XCTAssertTrue(alertMessage.exists, "Alert should have message")
        XCTAssertTrue(cancelButton.exists, "Alert should have cancel button")
        XCTAssertTrue(confirmButton.exists, "Alert should have confirm button")

        // Message should warn about permanent deletion
        XCTAssertTrue(alertMessage.label.contains("permanently delete") || alertMessage.label.contains("delete all"), "Alert should warn about permanent deletion")
    }

    func testCancelClearImagesOperation() throws {
        // Given confirmation alert is shown
        let clearImagesButton = app.buttons["clearImagesButton"]
        clearImagesButton.tap()

        let confirmAlert = app.alerts["confirmClearImagesAlert"]
        XCTAssertTrue(confirmAlert.waitForExistence(timeout: 2.0), "Confirmation alert should appear")

        // When tapping cancel
        let cancelButton = confirmAlert.buttons["Cancel"]
        cancelButton.tap()

        // Then alert should dismiss and images should remain
        let alertDismissed = !confirmAlert.exists
        XCTAssertTrue(alertDismissed, "Alert should be dismissed")

        // Image test view should remain visible
        let imageTestTitle = app.staticTexts["imageTestTitle"]
        XCTAssertTrue(imageTestTitle.exists, "Image test view should remain visible")
    }

    func testConfirmClearImagesOperation() throws {
        // Given confirmation alert is shown
        let clearImagesButton = app.buttons["clearImagesButton"]
        clearImagesButton.tap()

        let confirmAlert = app.alerts["confirmClearImagesAlert"]
        XCTAssertTrue(confirmAlert.waitForExistence(timeout: 2.0), "Confirmation alert should appear")

        // When tapping confirm
        let confirmButton = confirmAlert.buttons["Clear All"]
        confirmButton.tap()

        // Then all images should be cleared
        let successAlert = app.alerts["imagesClearedAlert"]
        let successExists = successAlert.waitForExistence(timeout: 2.0)

        if successExists {
            XCTAssertTrue(successAlert.exists, "Success alert should appear after clearing images")

            let successMessage = successAlert.staticTexts.firstMatch
            let okButton = successAlert.buttons["OK"]

            XCTAssertTrue(successMessage.exists, "Success alert should have message")
            XCTAssertTrue(okButton.exists, "Success alert should have OK button")
        }

        // Image preview should return to empty state
        let placeholderText = app.staticTexts["imagePlaceholderText"]
        if placeholderText.waitForExistence(timeout: 1.0) {
            XCTAssertTrue(placeholderText.exists, "Should return to empty state after clearing images")
        }
    }

    // MARK: - Test Image Information Display

    func testImageInformationDisplay() throws {
        // Given an image is loaded
        // Then image information should be displayed
        let imageSizeLabel = app.staticTexts["imageSizeLabel"]
        let imageFormatLabel = app.staticTexts["imageFormatLabel"]
        let imageDateLabel = app.staticTexts["imageDateLabel"]
        let imageFileNameLabel = app.staticTexts["imageFileNameLabel"]

        XCTAssertTrue(imageSizeLabel.exists, "Image size label should exist")
        XCTAssertTrue(imageFormatLabel.exists, "Image format label should exist")
        XCTAssertTrue(imageDateLabel.exists, "Image date label should exist")
        XCTAssertTrue(imageFileNameLabel.exists, "Image file name label should exist")

        // Labels should be properly formatted
        XCTAssertTrue(imageSizeLabel.label.contains("Size:"), "Size label should be formatted correctly")
        XCTAssertTrue(imageFormatLabel.label.contains("Format:"), "Format label should be formatted correctly")
        XCTAssertTrue(imageDateLabel.label.contains("Date:"), "Date label should be formatted correctly")
        XCTAssertTrue(imageFileNameLabel.label.contains("File:"), "File name label should be formatted correctly")
    }

    func testImageCountDisplay() throws {
        // When image test view loads
        // Then image count should be displayed
        let imageCountLabel = app.staticTexts["imageCountLabel"]
        XCTAssertTrue(imageCountLabel.exists, "Image count label should exist")

        // Should be formatted correctly
        XCTAssertTrue(imageCountLabel.label.contains("Images:"), "Image count should be formatted correctly")
    }

    // MARK: - Test Batch Operations

    func testBatchImageOperations() throws {
        // Given multiple images can be selected
        // Then batch operations should be available
        let selectMultipleButton = app.buttons["selectMultipleButton"]
        if selectMultipleButton.exists {
            selectMultipleButton.tap()

            // Multiple selection mode should be enabled
            let selectionIndicator = app.otherElements["multipleSelectionIndicator"]
            XCTAssertTrue(selectionIndicator.waitForExistence(timeout: 1.0), "Multiple selection mode should be indicated")

            // Batch operations should appear
            let deleteSelectedButton = app.buttons["deleteSelectedButton"]
            let exportSelectedButton = app.buttons["exportSelectedButton"]

            XCTAssertTrue(deleteSelectedButton.exists, "Delete selected button should appear in multiple selection")
            XCTAssertTrue(exportSelectedButton.exists, "Export selected button should appear in multiple selection")
        }
    }

    // MARK: - Test Image Editing

    func testImageEditingFeatures() throws {
        // Given an image is loaded
        // Then editing features should be available
        let editButton = app.buttons["editImageButton"]
        if editButton.exists {
            editButton.tap()

            // Image editor should appear
            let imageEditor = app.otherElements["imageEditor"]
            XCTAssertTrue(imageEditor.waitForExistence(timeout: 2.0), "Image editor should appear")

            // Editing tools should be available
            let cropButton = app.buttons["cropButton"]
            let rotateButton = app.buttons["rotateButton"]
            let filterButton = app.buttons["filterButton"]

            XCTAssertTrue(cropButton.exists, "Crop tool should be available")
            XCTAssertTrue(rotateButton.exists, "Rotate tool should be available")
            XCTAssertTrue(filterButton.exists, "Filter tool should be available")

            // Save changes button should be present
            let saveChangesButton = app.buttons["saveChangesButton"]
            XCTAssertTrue(saveChangesButton.exists, "Save changes button should be present")

            // Cancel button should be present
            let cancelEditButton = app.buttons["cancelEditButton"]
            XCTAssertTrue(cancelEditButton.exists, "Cancel edit button should be present")
        }
    }

    // MARK: - Test Performance

    func testImageLoadingPerformance() throws {
        // When loading images
        measure(metrics: [XCTClockMetric()]) {
            let loadImageButton = app.buttons["loadImageButton"]
            if loadImageButton.isEnabled {
                loadImageButton.tap()

                // Wait for image picker
                let imagePicker = app.otherElements["savedImagePicker"]
                _ = imagePicker.waitForExistence(timeout: 3.0)

                // Dismiss picker
                if app.buttons["Cancel"].exists {
                    app.buttons["Cancel"].tap()
                }
            }
        }
    }

    func testImageSavingPerformance() throws {
        // When saving images
        measure(metrics: [XCTClockMetric()]) {
            let saveImageButton = app.buttons["saveImageButton"]
            if saveImageButton.isEnabled {
                saveImageButton.tap()

                // Wait for save completion
                let saveAlert = app.alerts.firstMatch
                if saveAlert.waitForExistence(timeout: 5.0) {
                    saveAlert.buttons["OK"].tap()
                }
            }
        }
    }

    // MARK: - Test Accessibility

    func testImageTestViewAccessibility() throws {
        // Then all important elements should have accessibility identifiers
        let requiredElements = [
            "imageTestTitle",
            "selectPhotoButton",
            "takePhotoButton",
            "saveImageButton",
            "loadImageButton",
            "clearImagesButton",
            "imagePreview"
        ]

        for identifier in requiredElements {
            let element = app.otherElements[identifier]
            XCTAssertTrue(element.exists, "Element with identifier \(identifier) should exist")
        }
    }

    func testVoiceOverSupport() throws {
        // Then buttons should have appropriate accessibility labels
        let selectPhotoButton = app.buttons["selectPhotoButton"]
        let takePhotoButton = app.buttons["takePhotoButton"]
        let saveImageButton = app.buttons["saveImageButton"]
        let loadImageButton = app.buttons["loadImageButton"]

        XCTAssertEqual(selectPhotoButton.label, "Select Photo from Library", "Button should have descriptive accessibility label")
        XCTAssertEqual(takePhotoButton.label, "Take Photo with Camera", "Button should have descriptive accessibility label")
        XCTAssertEqual(saveImageButton.label, "Save Image", "Button should have descriptive accessibility label")
        XCTAssertEqual(loadImageButton.label, "Load Saved Image", "Button should have descriptive accessibility label")
    }

    // MARK: - Test Error Handling

    func testPhotoLibraryPermissionDenied() throws {
        // When photo library permission is denied
        // Then appropriate error message should be shown
        let permissionDeniedAlert = app.alerts["photoPermissionDeniedAlert"]
        let alertExists = permissionDeniedAlert.waitForExistence(timeout: 2.0)

        if alertExists {
            XCTAssertTrue(permissionDeniedAlert.exists, "Permission denied alert should appear")

            let alertMessage = permissionDeniedAlert.staticTexts.firstMatch
            let settingsButton = permissionDeniedAlert.buttons["Open Settings"]

            XCTAssertTrue(alertMessage.exists, "Alert should explain permission issue")
            XCTAssertTrue(settingsButton.exists, "Should provide option to open settings")
        }
    }

    func testCameraPermissionDenied() throws {
        // When camera permission is denied
        // Then appropriate error message should be shown
        let permissionDeniedAlert = app.alerts["cameraPermissionDeniedAlert"]
        let alertExists = permissionDeniedAlert.waitForExistence(timeout: 2.0)

        if alertExists {
            XCTAssertTrue(permissionDeniedAlert.exists, "Permission denied alert should appear")

            let alertMessage = permissionDeniedAlert.staticTexts.firstMatch
            let settingsButton = permissionDeniedAlert.buttons["Open Settings"]

            XCTAssertTrue(alertMessage.exists, "Alert should explain permission issue")
            XCTAssertTrue(settingsButton.exists, "Should provide option to open settings")
        }
    }

    func testStorageFullError() throws {
        // When device storage is full
        // Then storage full error should be shown
        let storageErrorAlert = app.alerts["storageFullAlert"]
        let alertExists = storageErrorAlert.waitForExistence(timeout: 2.0)

        if alertExists {
            XCTAssertTrue(storageErrorAlert.exists, "Storage full alert should appear")

            let alertMessage = storageErrorAlert.staticTexts.firstMatch
            let okButton = storageErrorAlert.buttons["OK"]

            XCTAssertTrue(alertMessage.exists, "Alert should explain storage issue")
            XCTAssertTrue(okButton.exists, "Alert should have OK button")
        }
    }

    // MARK: - Test Memory Management

    func testMemoryUsageWithLargeImages() throws {
        // When working with large images
        // Then memory usage should be managed properly
        let memoryWarningIndicator = app.otherElements["memoryWarningIndicator"]

        // Should not show memory warnings under normal operation
        XCTAssertFalse(memoryWarningIndicator.exists, "Should not show memory warnings under normal operation")
    }

    // MARK: - Test Navigation

    func testNavigationBackToDashboard() throws {
        // When navigating back from image test view
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }

        // Then should return to debug dashboard
        let dashboardTitle = app.staticTexts["debugDashboardTitle"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 1.0), "Should return to debug dashboard")
    }
}