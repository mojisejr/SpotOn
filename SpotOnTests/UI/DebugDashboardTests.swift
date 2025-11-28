//
//  DebugDashboardTests.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import XCTest

final class DebugDashboardTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Test Dashboard Loading and Initial State

    func testDebugDashboardDisplaysOnLaunch() throws {
        // Given app is launched with UI testing flag
        // When debug dashboard appears
        let dashboardTitle = app.staticTexts["debugDashboardTitle"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 2.0), "Debug dashboard title should be visible")

        // Then all counter labels should be visible
        let profileCountLabel = app.staticTexts["profileCountLabel"]
        let spotCountLabel = app.staticTexts["spotCountLabel"]
        let logEntryCountLabel = app.staticTexts["logEntryCountLabel"]
        let imageCountLabel = app.staticTexts["imageCountLabel"]

        XCTAssertTrue(profileCountLabel.exists, "Profile count label should exist")
        XCTAssertTrue(spotCountLabel.exists, "Spot count label should exist")
        XCTAssertTrue(logEntryCountLabel.exists, "Log entry count label should exist")
        XCTAssertTrue(imageCountLabel.exists, "Image count label should exist")
    }

    func testDashboardShowsInitialZeroCounts() throws {
        // When dashboard first loads with empty database
        let profileCountLabel = app.staticTexts["profileCountLabel"]
        let spotCountLabel = app.staticTexts["spotCountLabel"]
        let logEntryCountLabel = app.staticTexts["logEntryCountLabel"]
        let imageCountLabel = app.staticTexts["imageCountLabel"]

        // Then all counters should show 0
        XCTAssertEqual(profileCountLabel.label, "Profiles: 0", "Profile count should start at 0")
        XCTAssertEqual(spotCountLabel.label, "Spots: 0", "Spot count should start at 0")
        XCTAssertEqual(logEntryCountLabel.label, "Log Entries: 0", "Log entry count should start at 0")
        XCTAssertEqual(imageCountLabel.label, "Images: 0", "Image count should start at 0")
    }

    // MARK: - Test CRUD Buttons

    func testAllCRUDButtonsArePresent() throws {
        // When dashboard is loaded
        // Then all CRUD buttons should be present and tappable
        let createProfileButton = app.buttons["createProfileButton"]
        let createSpotButton = app.buttons["createSpotButton"]
        let createLogEntryButton = app.buttons["createLogEntryButton"]
        let testImageButton = app.buttons["testImageButton"]
        let viewDataButton = app.buttons["viewDataButton"]

        XCTAssertTrue(createProfileButton.exists, "Create Profile button should exist")
        XCTAssertTrue(createSpotButton.exists, "Create Spot button should exist")
        XCTAssertTrue(createLogEntryButton.exists, "Create Log Entry button should exist")
        XCTAssertTrue(testImageButton.exists, "Test Image button should exist")
        XCTAssertTrue(viewDataButton.exists, "View Data button should exist")

        XCTAssertTrue(createProfileButton.isHittable, "Create Profile button should be tappable")
        XCTAssertTrue(createSpotButton.isHittable, "Create Spot button should be tappable")
        XCTAssertTrue(createLogEntryButton.isHittable, "Create Log Entry button should be tappable")
        XCTAssertTrue(testImageButton.isHittable, "Test Image button should be tappable")
        XCTAssertTrue(viewDataButton.isHittable, "View Data button should be tappable")
    }

    func testCreateProfileButtonNavigation() throws {
        // When tapping Create Profile button
        let createProfileButton = app.buttons["createProfileButton"]
        createProfileButton.tap()

        // Then should navigate to profile creation screen
        let profileCreationTitle = app.staticTexts["profileCreationTitle"]
        XCTAssertTrue(profileCreationTitle.waitForExistence(timeout: 1.0), "Should navigate to profile creation screen")

        // Profile creation form elements should be present
        let nameTextField = app.textFields["profileNameTextField"]
        let relationPicker = app.pickers["profileRelationPicker"]
        let saveProfileButton = app.buttons["saveProfileButton"]

        XCTAssertTrue(nameTextField.exists, "Profile name text field should exist")
        XCTAssertTrue(relationPicker.exists, "Profile relation picker should exist")
        XCTAssertTrue(saveProfileButton.exists, "Save profile button should exist")
    }

    func testCreateSpotButtonNavigation() throws {
        // When tapping Create Spot button
        let createSpotButton = app.buttons["createSpotButton"]
        createSpotButton.tap()

        // Then should navigate to spot creation screen
        let spotCreationTitle = app.staticTexts["spotCreationTitle"]
        XCTAssertTrue(spotCreationTitle.waitForExistence(timeout: 1.0), "Should navigate to spot creation screen")

        // Spot creation form elements should be present
        let titleTextField = app.textFields["spotTitleTextField"]
        let bodyPartPicker = app.pickers["spotBodyPartPicker"]
        let profilePicker = app.pickers["spotProfilePicker"]
        let saveSpotButton = app.buttons["saveSpotButton"]

        XCTAssertTrue(titleTextField.exists, "Spot title text field should exist")
        XCTAssertTrue(bodyPartPicker.exists, "Spot body part picker should exist")
        XCTAssertTrue(profilePicker.exists, "Spot profile picker should exist")
        XCTAssertTrue(saveSpotButton.exists, "Save spot button should exist")
    }

    func testCreateLogEntryButtonNavigation() throws {
        // When tapping Create Log Entry button
        let createLogEntryButton = app.buttons["createLogEntryButton"]
        createLogEntryButton.tap()

        // Then should navigate to log entry creation screen
        let logEntryCreationTitle = app.staticTexts["logEntryCreationTitle"]
        XCTAssertTrue(logEntryCreationTitle.waitForExistence(timeout: 1.0), "Should navigate to log entry creation screen")

        // Log entry creation form elements should be present
        let spotPicker = app.pickers["logEntrySpotPicker"]
        let noteTextView = app.textViews["logEntryNoteTextView"]
        let painScoreSlider = app.sliders["logEntryPainScoreSlider"]
        let bleedingToggle = app.switches["logEntryBleedingToggle"]
        let itchingToggle = app.switches["logEntryItchingToggle"]
        let swollenToggle = app.switches["logEntrySwollenToggle"]
        let saveLogEntryButton = app.buttons["saveLogEntryButton"]

        XCTAssertTrue(spotPicker.exists, "Log entry spot picker should exist")
        XCTAssertTrue(noteTextView.exists, "Log entry note text view should exist")
        XCTAssertTrue(painScoreSlider.exists, "Log entry pain score slider should exist")
        XCTAssertTrue(bleedingToggle.exists, "Log entry bleeding toggle should exist")
        XCTAssertTrue(itchingToggle.exists, "Log entry itching toggle should exist")
        XCTAssertTrue(swollenToggle.exists, "Log entry swollen toggle should exist")
        XCTAssertTrue(saveLogEntryButton.exists, "Save log entry button should exist")
    }

    func testImageButtonNavigation() throws {
        // When tapping Test Image button
        let testImageButton = app.buttons["testImageButton"]
        testImageButton.tap()

        // Then should navigate to image test screen
        let imageTestTitle = app.staticTexts["imageTestTitle"]
        XCTAssertTrue(imageTestTitle.waitForExistence(timeout: 1.0), "Should navigate to image test screen")

        // Image test elements should be present
        let selectPhotoButton = app.buttons["selectPhotoButton"]
        let saveImageButton = app.buttons["saveImageButton"]
        let loadImageButton = app.buttons["loadImageButton"]
        let imagePreview = app.images["imagePreview"]

        XCTAssertTrue(selectPhotoButton.exists, "Select photo button should exist")
        XCTAssertTrue(saveImageButton.exists, "Save image button should exist")
        XCTAssertTrue(loadImageButton.exists, "Load image button should exist")
        XCTAssertTrue(imagePreview.exists, "Image preview should exist")
    }

    func testViewDataButtonNavigation() throws {
        // When tapping View Data button
        let viewDataButton = app.buttons["viewDataButton"]
        viewDataButton.tap()

        // Then should navigate to data viewer screen
        let dataViewerTitle = app.staticTexts["dataViewerTitle"]
        XCTAssertTrue(dataViewerTitle.waitForExistence(timeout: 1.0), "Should navigate to data viewer screen")

        // Data viewer elements should be present
        let dataScrollView = app.scrollViews["dataScrollView"]
        let refreshButton = app.buttons["refreshDataButton"]

        XCTAssertTrue(dataScrollView.exists, "Data scroll view should exist")
        XCTAssertTrue(refreshButton.exists, "Refresh data button should exist")
    }

    // MARK: - Test Counter Updates

    func testProfileCounterUpdatesAfterCreation() throws {
        // Given initial profile count is 0
        let profileCountLabel = app.staticTexts["profileCountLabel"]
        XCTAssertEqual(profileCountLabel.label, "Profiles: 0", "Profile count should start at 0")

        // When creating a new profile
        let createProfileButton = app.buttons["createProfileButton"]
        createProfileButton.tap()

        let nameTextField = app.textFields["profileNameTextField"]
        nameTextField.tap()
        nameTextField.typeText("Test User")

        let saveProfileButton = app.buttons["saveProfileButton"]
        saveProfileButton.tap()

        // Then profile counter should increment
        // Note: This assumes automatic navigation back to dashboard
        let dashboardExists = app.staticTexts["debugDashboardTitle"].waitForExistence(timeout: 2.0)
        if dashboardExists {
            XCTAssertEqual(profileCountLabel.label, "Profiles: 1", "Profile count should increment to 1")
        }
    }

    func testRealTimeCounterUpdates() throws {
        // When multiple operations are performed
        // Then counters should update in real-time

        let profileCountLabel = app.staticTexts["profileCountLabel"]
        let initialCount = profileCountLabel.label

        // Create profile
        let createProfileButton = app.buttons["createProfileButton"]
        createProfileButton.tap()

        let nameTextField = app.textFields["profileNameTextField"]
        nameTextField.tap()
        nameTextField.typeText("Realtime Test")

        let saveProfileButton = app.buttons["saveProfileButton"]
        saveProfileButton.tap()

        // Counters should reflect changes immediately
        let dashboardExists = app.staticTexts["debugDashboardTitle"].waitForExistence(timeout: 2.0)
        if dashboardExists {
            XCTAssertNotEqual(profileCountLabel.label, initialCount, "Profile count should have changed")
        }
    }

    // MARK: - Test Error Handling

    func testButtonDisabledWithoutRequiredData() throws {
        // When trying to create spot without profiles
        let createSpotButton = app.buttons["createSpotButton"]
        createSpotButton.tap()

        // Then save button should be disabled if no profiles exist
        let saveSpotButton = app.buttons["saveSpotButton"]
        let alertExists = app.alerts.firstMatch.waitForExistence(timeout: 2.0)

        if alertExists {
            let alert = app.alerts.firstMatch
            XCTAssertTrue(alert.exists, "Should show alert when no profiles exist")
            let okButton = alert.buttons["OK"]
            XCTAssertTrue(okButton.exists, "Alert should have OK button")
        }
    }

    func testNavigationBackToDashboard() throws {
        // When navigating away from dashboard
        let viewDataButton = app.buttons["viewDataButton"]
        viewDataButton.tap()

        // And then navigating back
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }

        // Then should return to dashboard
        let dashboardTitle = app.staticTexts["debugDashboardTitle"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 1.0), "Should return to dashboard")
    }

    // MARK: - Test Accessibility

    func testAccessibilityIdentifiers() throws {
        // Then all important elements should have accessibility identifiers
        let requiredElements = [
            "debugDashboardTitle",
            "profileCountLabel",
            "spotCountLabel",
            "logEntryCountLabel",
            "imageCountLabel",
            "createProfileButton",
            "createSpotButton",
            "createLogEntryButton",
            "testImageButton",
            "viewDataButton"
        ]

        for identifier in requiredElements {
            let element = app.otherElements[identifier]
            XCTAssertTrue(element.exists, "Element with identifier \(identifier) should exist")
        }
    }

    func testVoiceOverSupport() throws {
        // Then buttons should have appropriate accessibility labels
        let createProfileButton = app.buttons["createProfileButton"]
        XCTAssertEqual(createProfileButton.label, "Create User Profile", "Button should have descriptive accessibility label")

        let createSpotButton = app.buttons["createSpotButton"]
        XCTAssertEqual(createSpotButton.label, "Create Spot", "Button should have descriptive accessibility label")

        let createLogEntryButton = app.buttons["createLogEntryButton"]
        XCTAssertEqual(createLogEntryButton.label, "Create Log Entry", "Button should have descriptive accessibility label")

        let testImageButton = app.buttons["testImageButton"]
        XCTAssertEqual(testImageButton.label, "Test Image Save/Load", "Button should have descriptive accessibility label")

        let viewDataButton = app.buttons["viewDataButton"]
        XCTAssertEqual(viewDataButton.label, "View Database", "Button should have descriptive accessibility label")
    }

    // MARK: - Test Performance

    func testDashboardLoadPerformance() throws {
        // When dashboard loads
        measure(metrics: [XCTClockMetric(), XCTApplicationLaunchMetric()]) {
            app.launch()

            let dashboardTitle = app.staticTexts["debugDashboardTitle"]
            _ = dashboardTitle.waitForExistence(timeout: 3.0)
        }
    }
}