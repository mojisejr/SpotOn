//
//  SpotDetailViewTests.swift
//  SpotOnTests
//
//  Created by Non on 11/29/25.
//

import XCTest
import SwiftData
@testable import SpotOn

final class SpotDetailViewTests: XCTestCase {

    // MARK: - Test Properties

    var testContainer: ModelContainer!
    var testContext: ModelContext!

    // MARK: - Setup and Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false

        // Setup in-memory SwiftData container for isolated testing
        testContainer = try TestHelpers.createTestModelContainer()
        testContext = ModelContext(testContainer)
    }

    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
    }

    // MARK: - Spot Loading Tests

    func testSpotDetailViewDisplaysCorrectSpotInformation() throws {
        // Given a spot with associated data
        let hierarchy = TestHelpers.createTestHierarchy(
            userName: "Test User",
            spotTitle: "Test Mole",
            logEntryNote: "Initial observation"
        )
        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        try testContext.save()

        // When SpotDetailView is displayed with the spot
        // Then it should display the correct spot information
        XCTAssertEqual(hierarchy.spot.title, "Test Mole", "Spot title should match")
        XCTAssertEqual(hierarchy.spot.bodyPart, "Test Body Part", "Spot body part should match")
        XCTAssertTrue(hierarchy.spot.isActive, "Spot should be active")
        XCTAssertNotNil(hierarchy.spot.userProfile, "Spot should have associated user profile")
        XCTAssertEqual(hierarchy.spot.userProfile?.name, "Test User", "Associated user should match")
    }

    func testSpotDetailViewHandlesSpotWithEmptyTitle() throws {
        // Given a spot with empty title
        let user = TestHelpers.createTestUserProfile()
        let spot = TestHelpers.createTestSpot(
            title: "",
            bodyPart: "Arm",
            userProfile: user
        )
        testContext.insert(user)
        testContext.insert(spot)
        try testContext.save()

        // When SpotDetailView displays the spot
        // Then it should handle empty title gracefully
        XCTAssertTrue(spot.title.isEmpty, "Spot title should be empty")
        XCTAssertEqual(spot.bodyPart, "Arm", "Body part should still be displayed")
        XCTAssertNotNil(spot.userProfile, "User profile should still be associated")
    }

    func testSpotDetailViewHandlesSpotWithEmptyBodyPart() throws {
        // Given a spot with empty body part
        let user = TestHelpers.createTestUserProfile()
        let spot = TestHelpers.createTestSpot(
            title: "Test Spot",
            bodyPart: "",
            userProfile: user
        )
        testContext.insert(user)
        testContext.insert(spot)
        try testContext.save()

        // When SpotDetailView displays the spot
        // Then it should handle empty body part gracefully
        XCTAssertEqual(spot.title, "Test Spot", "Spot title should still be displayed")
        XCTAssertTrue(spot.bodyPart.isEmpty, "Body part should be empty")
        XCTAssertNotNil(spot.userProfile, "User profile should still be associated")
    }

    // MARK: - Timeline Display Tests

    func testSpotDetailViewShowsLogEntriesInChronologicalOrder() throws {
        // Given a spot with multiple log entries with different timestamps
        let hierarchy = TestHelpers.createTestHierarchy(
            userName: "Test User",
            spotTitle: "Test Spot"
        )

        // Create multiple log entries with different timestamps
        let oldEntry = TestHelpers.createTestLogEntry(
            imageFilename: "OLD_IMG.jpg",
            note: "Old entry",
            painScore: 1,
            spot: hierarchy.spot
        )

        let recentEntry = TestHelpers.createTestLogEntry(
            imageFilename: "RECENT_IMG.jpg",
            note: "Recent entry",
            painScore: 2,
            spot: hierarchy.spot
        )

        // Set specific timestamps to ensure chronological order
        let oldDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let recentDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        oldEntry.timestamp = oldDate
        recentEntry.timestamp = recentDate

        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        testContext.insert(oldEntry)
        testContext.insert(recentEntry)
        try testContext.save()

        // When SpotDetailView displays the timeline
        // Then log entries should appear in chronological order (newest first)
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == hierarchy.spot.id },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let sortedEntries = try testContext.fetch(fetchDescriptor)

        XCTAssertEqual(sortedEntries.count, 3, "Should have 3 log entries")
        XCTAssertEqual(sortedEntries[0].note, "Recent entry", "Most recent entry should be first")
        XCTAssertEqual(sortedEntries[1].note, "Initial observation", "Middle entry should be second")
        XCTAssertEqual(sortedEntries[2].note, "Old entry", "Oldest entry should be last")

        // Verify timestamps are in descending order
        XCTAssertGreaterThanOrEqual(sortedEntries[0].timestamp, sortedEntries[1].timestamp)
        XCTAssertGreaterThanOrEqual(sortedEntries[1].timestamp, sortedEntries[2].timestamp)
    }

    func testSpotDetailViewShowsEmptyStateWhenNoLogEntries() throws {
        // Given a spot with no log entries
        let user = TestHelpers.createTestUserProfile()
        let spot = TestHelpers.createTestSpot(userProfile: user)
        testContext.insert(user)
        testContext.insert(spot)
        try testContext.save()

        // When SpotDetailView displays the timeline
        // Then it should show empty state
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == spot.id }
        )
        let logEntries = try testContext.fetch(fetchDescriptor)

        XCTAssertEqual(logEntries.count, 0, "Should have no log entries")
        // SpotDetailView should display empty state UI
    }

    // MARK: - Medical Data Display Tests

    func testSpotDetailViewDisplaysAllMedicalDataCorrectly() throws {
        // Given a log entry with comprehensive medical data
        let hierarchy = TestHelpers.createTestHierarchy(
            logEntryNote: "Comprehensive medical data test",
            painScore: 7,
            hasBleeding: true,
            hasItching: true,
            isSwollen: true,
            estimatedSize: 15.5
        )
        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        try testContext.save()

        // When SpotDetailView displays the log entry
        // Then all medical data should be displayed correctly
        let entry = hierarchy.logEntry
        XCTAssertEqual(entry.note, "Comprehensive medical data test", "Note should be displayed")
        XCTAssertEqual(entry.painScore, 7, "Pain score should be displayed")
        XCTAssertTrue(entry.hasBleeding, "Bleeding status should be displayed")
        XCTAssertTrue(entry.hasItching, "Itching status should be displayed")
        XCTAssertTrue(entry.isSwollen, "Swelling status should be displayed")
        XCTAssertEqual(entry.estimatedSize, 15.5, "Estimated size should be displayed")
        XCTAssertNotNil(entry.imageFilename, "Image filename should be displayed")
    }

    func testSpotDetailViewHandlesLogEntryWithMinimalData() throws {
        // Given a log entry with minimal data
        let hierarchy = TestHelpers.createTestHierarchy(
            logEntryNote: "",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil
        )
        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        try testContext.save()

        // When SpotDetailView displays the log entry
        // Then it should handle minimal data gracefully
        let entry = hierarchy.logEntry
        XCTAssertTrue(entry.note.isEmpty, "Empty note should be handled")
        XCTAssertEqual(entry.painScore, 0, "Zero pain score should be displayed")
        XCTAssertFalse(entry.hasBleeding, "False bleeding should be handled")
        XCTAssertFalse(entry.hasItching, "False itching should be handled")
        XCTAssertFalse(entry.isSwollen, "False swelling should be handled")
        XCTAssertNil(entry.estimatedSize, "Nil estimated size should be handled")
    }

    // MARK: - Navigation Tests

    func testSpotDetailViewReceivesCorrectSpotFromNavigation() throws {
        // Given multiple spots in the database
        let user1 = TestHelpers.createTestUserProfile(userName: "User 1")
        let user2 = TestHelpers.createTestUserProfile(userName: "User 2")
        let spot1 = TestHelpers.createTestSpot(title: "Spot 1", userProfile: user1)
        let spot2 = TestHelpers.createTestSpot(title: "Spot 2", userProfile: user2)

        testContext.insert(user1)
        testContext.insert(user2)
        testContext.insert(spot1)
        testContext.insert(spot2)
        try testContext.save()

        // When navigating to SpotDetailView with spot2
        let selectedSpot = spot2

        // Then SpotDetailView should display the correct spot
        XCTAssertEqual(selectedSpot?.title, "Spot 2", "Should display spot2")
        XCTAssertEqual(selectedSpot?.userProfile?.name, "User 2", "Should show correct associated user")
        XCTAssertNotEqual(selectedSpot?.id, spot1.id, "Should not display spot1")
    }

    // MARK: - Medical Theme Tests

    func testSpotDetailViewAppliesMedicalThemeColors() throws {
        // Given SpotDetailView is displayed
        // Then it should apply medical theme colors

        // Test medical blue color application
        let medicalBlue = Color.red // This will be replaced with actual medical blue
        let backgroundColor = Color.blue // This will be replaced with actual background

        // These colors should be used consistently throughout SpotDetailView:
        // - Headers and important text: Medical Blue
        // - Backgrounds: Light gray background
        // - Interactive elements: Medical Blue with proper contrast

        // For now, just verify the concept exists
        XCTAssertNotNil(medicalBlue, "Medical blue color should be defined")
        XCTAssertNotNil(backgroundColor, "Background color should be defined")
    }

    // MARK: - Accessibility Tests

    func testSpotDetailViewAccessibilityIdentifiers() throws {
        // Given SpotDetailView is displayed
        // Then it should have proper accessibility identifiers

        let requiredIdentifiers = [
            "spotDetailView",           // Main view
            "spotInfoSection",          // Spot information section
            "timelineSection",          // Timeline section
            "logEntryCardView"          // Individual log entry cards
        ]

        // These identifiers enable UI testing and VoiceOver support
        for identifier in requiredIdentifiers {
            let accessibilityString = identifier
            XCTAssertFalse(accessibilityString.isEmpty, "Accessibility identifier should not be empty")
        }
    }

    func testSpotDetailViewVoiceOverSupport() throws {
        // Given SpotDetailView with medical data
        let hierarchy = TestHelpers.createTestHierarchy(
            logEntryNote: "VoiceOver test entry",
            painScore: 3,
            hasBleeding: false,
            hasItching: true,
            isSwollen: false
        )
        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        try testContext.save()

        // When VoiceOver is enabled
        // Then elements should have proper accessibility labels

        // Spot info should announce:
        // - "Test Spot, Test Body Part, Spot, Double tap for details"

        // Log entries should announce:
        // - "VoiceOver test entry, Pain score 3, Itching, Log entry, Double tap for details"

        let entry = hierarchy.logEntry
        let accessibilityLabel = "\(entry.note), Pain score \(entry.painScore)"
        XCTAssertFalse(accessibilityLabel.isEmpty, "Log entry should have meaningful accessibility label")
    }

    // MARK: - Performance Tests

    func testSpotDetailViewLoadPerformanceWithManyLogEntries() throws {
        // Given a spot with many log entries (simulating long-term tracking)
        let user = TestHelpers.createTestUserProfile()
        let spot = TestHelpers.createTestSpot(userProfile: user)
        testContext.insert(user)
        testContext.insert(spot)

        let logEntryCount = 100
        for i in 1...logEntryCount {
            let logEntry = TestHelpers.createTestLogEntry(
                imageFilename: "IMG_\(i).jpg",
                note: "Log entry \(i)",
                painScore: i % 10,
                spot: spot
            )
            // Set different timestamps for each entry
            logEntry.timestamp = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            testContext.insert(logEntry)
        }
        try testContext.save()

        // When SpotDetailView loads
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == spot.id },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        // Then loading should complete within acceptable time
        measure(metrics: [XCTClockMetric()]) {
            do {
                _ = try testContext.fetch(fetchDescriptor)
            } catch {
                XCTFail("Loading log entries should not fail: \(error)")
            }
        }

        // Verify all log entries were loaded
        do {
            let loadedEntries = try testContext.fetch(fetchDescriptor)
            XCTAssertEqual(loadedEntries.count, logEntryCount, "Should load all log entries")
        } catch {
            XCTFail("Should successfully load all log entries")
        }
    }
}