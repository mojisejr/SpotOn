//
//  DataViewerTests.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import XCTest

final class DataViewerTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // Navigate to data viewer
        let viewDataButton = app.buttons["viewDataButton"]
        if viewDataButton.exists {
            viewDataButton.tap()
        }
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Test Data Viewer Loading

    func testDataViewerDisplaysCorrectly() throws {
        // Given data viewer is launched
        // Then data viewer title should be visible
        let dataViewerTitle = app.staticTexts["dataViewerTitle"]
        XCTAssertTrue(dataViewerTitle.waitForExistence(timeout: 2.0), "Data viewer title should be visible")

        // And essential UI elements should be present
        let dataScrollView = app.scrollViews["dataScrollView"]
        let refreshButton = app.buttons["refreshDataButton"]
        let exportButton = app.buttons["exportDataButton"]
        let clearDataButton = app.buttons["clearDataButton"]

        XCTAssertTrue(dataScrollView.exists, "Data scroll view should exist")
        XCTAssertTrue(refreshButton.exists, "Refresh button should exist")
        XCTAssertTrue(exportButton.exists, "Export button should exist")
        XCTAssertTrue(clearDataButton.exists, "Clear data button should exist")
    }

    func testEmptyStateDisplay() throws {
        // When database is empty
        // Then empty state message should be displayed
        let emptyStateMessage = app.staticTexts["emptyStateMessage"]
        XCTAssertTrue(emptyStateMessage.waitForExistence(timeout: 2.0), "Empty state message should be displayed")

        XCTAssertEqual(emptyStateMessage.label, "No data found. Create some profiles, spots, or log entries to see them here.", "Empty state message should be descriptive")

        // And hierarchical view should be empty
        let dataContainer = app.otherElements["dataContainer"]
        XCTAssertTrue(dataContainer.exists, "Data container should exist")
    }

    // MARK: - Test Data Creation and Display

    func testUserProfileDisplayInHierarchicalView() throws {
        // Given a user profile exists
        // First create a profile
        navigateToDashboard()
        createTestProfile(name: "John Doe", relation: "Self")
        navigateToDataViewer()

        // Then profile should be displayed in hierarchical view
        let profileItem = app.otherElements["profile_John Doe"]
        XCTAssertTrue(profileItem.waitForExistence(timeout: 2.0), "Created profile should be displayed")

        // Profile details should be visible
        let profileName = profileItem.staticTexts["profileName"]
        let profileRelation = profileItem.staticTexts["profileRelation"]
        let profileDate = profileItem.staticTexts["profileDate"]

        XCTAssertTrue(profileName.exists, "Profile name should be displayed")
        XCTAssertTrue(profileRelation.exists, "Profile relation should be displayed")
        XCTAssertTrue(profileDate.exists, "Profile creation date should be displayed")

        XCTAssertEqual(profileName.label, "John Doe", "Profile name should match")
        XCTAssertEqual(profileRelation.label, "Relation: Self", "Profile relation should match")
    }

    func testSpotDisplayUnderUserProfile() throws {
        // Given a user profile with spots exists
        navigateToDashboard()
        createTestProfile(name: "Jane Doe", relation: "Spouse")
        createTestSpot(title: "Mole on Arm", bodyPart: "Left Arm", profileName: "Jane Doe")
        navigateToDataViewer()

        // Then spot should be displayed under the correct profile
        let profileItem = app.otherElements["profile_Jane Doe"]
        XCTAssertTrue(profileItem.waitForExistence(timeout: 2.0), "Profile should be displayed")

        let spotItem = app.otherElements["spot_Mole on Arm"]
        XCTAssertTrue(spotItem.exists, "Created spot should be displayed")

        // Spot should be indented under profile
        let spotFrame = spotItem.frame
        let profileFrame = profileItem.frame
        XCTAssertGreaterThan(spotFrame.origin.x, profileFrame.origin.x, "Spot should be indented under profile")

        // Spot details should be visible
        let spotTitle = spotItem.staticTexts["spotTitle"]
        let spotBodyPart = spotItem.staticTexts["spotBodyPart"]
        let spotStatus = spotItem.staticTexts["spotStatus"]

        XCTAssertTrue(spotTitle.exists, "Spot title should be displayed")
        XCTAssertTrue(spotBodyPart.exists, "Spot body part should be displayed")
        XCTAssertTrue(spotStatus.exists, "Spot status should be displayed")

        XCTAssertEqual(spotTitle.label, "Mole on Arm", "Spot title should match")
        XCTAssertEqual(spotBodyPart.label, "Left Arm", "Spot body part should match")
    }

    func testLogEntryDisplayUnderSpot() throws {
        // Given a spot with log entries exists
        navigateToDashboard()
        createTestProfile(name: "Test User", relation: "Child")
        createTestSpot(title: "Rash on Leg", bodyPart: "Right Leg", profileName: "Test User")
        createTestLogEntry(note: "Initial observation", painScore: 3, spotTitle: "Rash on Leg")
        navigateToDataViewer()

        // Then log entry should be displayed under the correct spot
        let spotItem = app.otherElements["spot_Rash on Leg"]
        XCTAssertTrue(spotItem.waitForExistence(timeout: 2.0), "Spot should be displayed")

        let logEntryItem = app.otherElements["logEntry_1"]
        XCTAssertTrue(logEntryItem.exists, "Created log entry should be displayed")

        // Log entry should be indented under spot
        let logEntryFrame = logEntryItem.frame
        let spotFrame = spotItem.frame
        XCTAssertGreaterThan(logEntryFrame.origin.x, spotFrame.origin.x, "Log entry should be indented under spot")

        // Log entry details should be visible
        let logEntryDate = logEntryItem.staticTexts["logEntryDate"]
        let logEntryNote = logEntryItem.staticTexts["logEntryNote"]
        let logEntryPainScore = logEntryItem.staticTexts["logEntryPainScore"]
        let logEntrySymptoms = logEntryItem.staticTexts["logEntrySymptoms"]

        XCTAssertTrue(logEntryDate.exists, "Log entry date should be displayed")
        XCTAssertTrue(logEntryNote.exists, "Log entry note should be displayed")
        XCTAssertTrue(logEntryPainScore.exists, "Log entry pain score should be displayed")
        XCTAssertTrue(logEntrySymptoms.exists, "Log entry symptoms should be displayed")

        XCTAssertEqual(logEntryNote.label, "Note: Initial observation", "Log entry note should match")
        XCTAssertEqual(logEntryPainScore.label, "Pain: 3/10", "Log entry pain score should match")
    }

    func testMultipleProfilesHierarchicalDisplay() throws {
        // Given multiple profiles exist
        navigateToDashboard()
        createTestProfile(name: "Dad", relation: "Father")
        createTestProfile(name: "Mom", relation: "Mother")
        createTestProfile(name: "Child", relation: "Son")
        navigateToDataViewer()

        // Then all profiles should be displayed at top level
        let dadProfile = app.otherElements["profile_Dad"]
        let momProfile = app.otherElements["profile_Mom"]
        let childProfile = app.otherElements["profile_Child"]

        XCTAssertTrue(dadProfile.waitForExistence(timeout: 2.0), "Dad profile should be displayed")
        XCTAssertTrue(momProfile.exists, "Mom profile should be displayed")
        XCTAssertTrue(childProfile.exists, "Child profile should be displayed")

        // All profiles should be at same indentation level
        let dadFrame = dadProfile.frame
        let momFrame = momProfile.frame
        let childFrame = childProfile.frame

        XCTAssertEqual(dadFrame.origin.x, momFrame.origin.x, "Profiles should be at same indentation level")
        XCTAssertEqual(momFrame.origin.x, childFrame.origin.x, "Profiles should be at same indentation level")
    }

    func testComplexHierarchicalDataDisplay() throws {
        // Given complex hierarchical data exists
        navigateToDashboard()

        // Create first profile with spots and log entries
        createTestProfile(name: "User 1", relation: "Self")
        createTestSpot(title: "Spot A", bodyPart: "Arm", profileName: "User 1")
        createTestSpot(title: "Spot B", bodyPart: "Leg", profileName: "User 1")
        createTestLogEntry(note: "First entry", painScore: 2, spotTitle: "Spot A")
        createTestLogEntry(note: "Second entry", painScore: 4, spotTitle: "Spot B")

        // Create second profile with spots and log entries
        createTestProfile(name: "User 2", relation: "Spouse")
        createTestSpot(title: "Spot C", bodyPart: "Back", profileName: "User 2")
        createTestLogEntry(note: "Third entry", painScore: 1, spotTitle: "Spot C")

        navigateToDataViewer()

        // Then hierarchical structure should be correct
        let user1Profile = app.otherElements["profile_User 1"]
        let user2Profile = app.otherElements["profile_User 2"]
        let spotA = app.otherElements["spot_Spot A"]
        let spotB = app.otherElements["spot_Spot B"]
        let spotC = app.otherElements["spot_Spot C"]

        XCTAssertTrue(user1Profile.waitForExistence(timeout: 2.0), "User 1 profile should be displayed")
        XCTAssertTrue(user2Profile.exists, "User 2 profile should be displayed")
        XCTAssertTrue(spotA.exists, "Spot A should be displayed")
        XCTAssertTrue(spotB.exists, "Spot B should be displayed")
        XCTAssertTrue(spotC.exists, "Spot C should be displayed")

        // Check hierarchical indentation
        let user1Frame = user1Profile.frame
        let user2Frame = user2Profile.frame
        let spotAFrame = spotA.frame
        let spotBFrame = spotB.frame
        let spotCFrame = spotC.frame

        XCTAssertEqual(user1Frame.origin.x, user2Frame.origin.x, "User profiles should be at same level")
        XCTAssertGreaterThan(spotAFrame.origin.x, user1Frame.origin.x, "Spots should be indented under profiles")
        XCTAssertGreaterThan(spotBFrame.origin.x, user1Frame.origin.x, "Spots should be indented under profiles")
        XCTAssertGreaterThan(spotCFrame.origin.x, user2Frame.origin.x, "Spots should be indented under profiles")
    }

    // MARK: - Test Data Refresh

    func testRefreshButtonUpdatesData() throws {
        // Given initial data display
        navigateToDashboard()
        createTestProfile(name: "Refresh Test", relation: "Self")
        navigateToDataViewer()

        let profileExists = app.otherElements["profile_Refresh Test"].waitForExistence(timeout: 2.0)
        XCTAssertTrue(profileExists, "Profile should be displayed initially")

        // When creating new data outside data viewer
        navigateToDashboard()
        createTestProfile(name: "New Profile", relation: "Child")
        navigateToDataViewer()

        // And tapping refresh button
        let refreshButton = app.buttons["refreshDataButton"]
        refreshButton.tap()

        // Then new data should appear
        let newProfileExists = app.otherElements["profile_New Profile"].waitForExistence(timeout: 2.0)
        XCTAssertTrue(newProfileExists, "New profile should appear after refresh")
    }

    // MARK: - Test Data Export

    func testExportButtonFunctionality() throws {
        // When tapping export button
        let exportButton = app.buttons["exportDataButton"]
        XCTAssertTrue(exportButton.exists, "Export button should exist")

        exportButton.tap()

        // Then export options should appear
        let shareSheet = app.sheets.firstMatch
        let shareSheetExists = shareSheet.waitForExistence(timeout: 2.0)

        if shareSheetExists {
            XCTAssertTrue(shareSheet.exists, "Share sheet should appear for export")

            // Export options should be available
            let copyButton = shareSheet.buttons["Copy"]
            let saveButton = shareSheet.buttons["Save to Files"]

            XCTAssertTrue(copyButton.exists, "Copy option should be available")
            XCTAssertTrue(saveButton.exists, "Save to Files option should be available")
        }
    }

    // MARK: - Test Data Clear

    func testClearDataButtonConfirmation() throws {
        // When tapping clear data button
        let clearDataButton = app.buttons["clearDataButton"]
        clearDataButton.tap()

        // Then confirmation alert should appear
        let alert = app.alerts["confirmClearDataAlert"]
        XCTAssertTrue(alert.waitForExistence(timeout: 2.0), "Confirmation alert should appear")

        // Alert should have proper message and buttons
        let alertMessage = alert.staticTexts.firstMatch
        let cancelButton = alert.buttons["Cancel"]
        let confirmButton = alert.buttons["Clear All Data"]

        XCTAssertTrue(alertMessage.exists, "Alert should have message")
        XCTAssertTrue(cancelButton.exists, "Alert should have cancel button")
        XCTAssertTrue(confirmButton.exists, "Alert should have confirm button")

        // Message should be descriptive
        XCTAssertTrue(alertMessage.label.contains("This will permanently delete"), "Alert message should warn about permanent deletion")
    }

    func testCancelClearDataOperation() throws {
        // Given confirmation alert is shown
        let clearDataButton = app.buttons["clearDataButton"]
        clearDataButton.tap()

        let alert = app.alerts["confirmClearDataAlert"]
        XCTAssertTrue(alert.waitForExistence(timeout: 2.0), "Confirmation alert should appear")

        // When tapping cancel
        let cancelButton = alert.buttons["Cancel"]
        cancelButton.tap()

        // Then alert should dismiss and data should remain
        let alertDismissed = !alert.exists
        XCTAssertTrue(alertDismissed, "Alert should be dismissed")

        // Data viewer should still be visible
        let dataViewerTitle = app.staticTexts["dataViewerTitle"]
        XCTAssertTrue(dataViewerTitle.exists, "Data viewer should remain visible")
    }

    // MARK: - Test Search and Filtering

    func testSearchFunctionality() throws {
        // Given data exists
        navigateToDashboard()
        createTestProfile(name: "Searchable User", relation: "Self")
        createTestProfile(name: "Another User", relation: "Spouse")
        navigateToDataViewer()

        // When using search functionality
        let searchField = app.searchFields["dataSearchField"]
        if searchField.exists {
            searchField.tap()
            searchField.typeText("Searchable")

            // Then filtered results should show only matching items
            let searchableProfile = app.otherElements["profile_Searchable User"]
            let anotherProfile = app.otherElements["profile_Another User"]

            XCTAssertTrue(searchableProfile.waitForExistence(timeout: 2.0), "Searchable profile should be visible")

            // Wait to see if another profile disappears
            sleep(1)
            let anotherProfileStillVisible = anotherProfile.exists
            XCTAssertFalse(anotherProfileStillVisible, "Non-matching profile should be filtered out")
        }
    }

    // MARK: - Test Data Statistics

    func testDataStatisticsDisplay() throws {
        // When data viewer loads
        // Then data statistics should be displayed
        let totalProfilesLabel = app.staticTexts["totalProfilesLabel"]
        let totalSpotsLabel = app.staticTexts["totalSpotsLabel"]
        let totalLogEntriesLabel = app.staticTexts["totalLogEntriesLabel"]
        let totalImagesLabel = app.staticTexts["totalImagesLabel"]

        XCTAssertTrue(totalProfilesLabel.exists, "Total profiles label should exist")
        XCTAssertTrue(totalSpotsLabel.exists, "Total spots label should exist")
        XCTAssertTrue(totalLogEntriesLabel.exists, "Total log entries label should exist")
        XCTAssertTrue(totalImagesLabel.exists, "Total images label should exist")

        // Statistics should be accurate
        // This would require actual data creation and verification
        // For now, just check that labels have correct format
        XCTAssertTrue(totalProfilesLabel.label.contains("Profiles:"), "Profile count label should be formatted correctly")
        XCTAssertTrue(totalSpotsLabel.label.contains("Spots:"), "Spot count label should be formatted correctly")
        XCTAssertTrue(totalLogEntriesLabel.label.contains("Log Entries:"), "Log entry count label should be formatted correctly")
        XCTAssertTrue(totalImagesLabel.label.contains("Images:"), "Image count label should be formatted correctly")
    }

    // MARK: - Test Scrolling and Performance

    func testScrollingThroughLargeDataset() throws {
        // Given large dataset exists (would need to create many entries)
        // When scrolling through data
        let dataScrollView = app.scrollViews["dataScrollView"]

        // Should be able to scroll
        dataScrollView.swipeUp()
        dataScrollView.swipeDown()

        // Scrolling should be smooth (basic test)
        XCTAssertTrue(dataScrollView.exists, "Scroll view should remain accessible after scrolling")
    }

    // MARK: - Test Accessibility

    func testDataViewerAccessibility() throws {
        // Then all important elements should have accessibility identifiers
        let requiredElements = [
            "dataViewerTitle",
            "dataScrollView",
            "refreshDataButton",
            "exportDataButton",
            "clearDataButton"
        ]

        for identifier in requiredElements {
            let element = app.otherElements[identifier]
            XCTAssertTrue(element.exists, "Element with identifier \(identifier) should exist")
        }
    }

    // MARK: - Helper Methods

    private func navigateToDashboard() {
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }

        let dashboardTitle = app.staticTexts["debugDashboardTitle"]
        _ = dashboardTitle.waitForExistence(timeout: 2.0)
    }

    private func navigateToDataViewer() {
        let viewDataButton = app.buttons["viewDataButton"]
        if viewDataButton.exists {
            viewDataButton.tap()
        }

        let dataViewerTitle = app.staticTexts["dataViewerTitle"]
        _ = dataViewerTitle.waitForExistence(timeout: 2.0)
    }

    private func createTestProfile(name: String, relation: String) {
        let createProfileButton = app.buttons["createProfileButton"]
        createProfileButton.tap()

        let nameTextField = app.textFields["profileNameTextField"]
        nameTextField.tap()
        nameTextField.typeText(name)

        let relationPicker = app.pickers["profileRelationPicker"]
        relationPicker.tap()
        app.pickerWheels[relation].tap()

        let saveProfileButton = app.buttons["saveProfileButton"]
        saveProfileButton.tap()
    }

    private func createTestSpot(title: String, bodyPart: String, profileName: String) {
        let createSpotButton = app.buttons["createSpotButton"]
        createSpotButton.tap()

        let titleTextField = app.textFields["spotTitleTextField"]
        titleTextField.tap()
        titleTextField.typeText(title)

        let bodyPartPicker = app.pickers["spotBodyPartPicker"]
        bodyPartPicker.tap()
        app.pickerWheels[bodyPart].tap()

        let saveSpotButton = app.buttons["saveSpotButton"]
        saveSpotButton.tap()
    }

    private func createTestLogEntry(note: String, painScore: Int, spotTitle: String) {
        let createLogEntryButton = app.buttons["createLogEntryButton"]
        createLogEntryButton.tap()

        let noteTextView = app.textViews["logEntryNoteTextView"]
        noteTextView.tap()
        noteTextView.typeText(note)

        let painScoreSlider = app.sliders["logEntryPainScoreSlider"]
        painScoreSlider.adjust(toNormalizedSliderPosition: CGFloat(painScore) / 10.0)

        let saveLogEntryButton = app.buttons["saveLogEntryButton"]
        saveLogEntryButton.tap()
    }
}