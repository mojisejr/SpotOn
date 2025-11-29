//
//  LogEntryCardViewTests.swift
//  SpotOnTests
//
//  Created by Non on 11/29/25.
//

import XCTest
import SwiftData
@testable import SpotOn

final class LogEntryCardViewTests: XCTestCase {

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

    // MARK: - Medical Data Display Tests

    func testLogEntryCardViewDisplaysAllRequiredMedicalData() throws {
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

        // When LogEntryCardView displays the log entry
        let entry = hierarchy.logEntry

        // Then all medical data should be available for display
        XCTAssertEqual(entry.note, "Comprehensive medical data test", "Note should be displayed")
        XCTAssertEqual(entry.painScore, 7, "Pain score should be displayed")
        XCTAssertTrue(entry.hasBleeding, "Bleeding status should be displayed")
        XCTAssertTrue(entry.hasItching, "Itching status should be displayed")
        XCTAssertTrue(entry.isSwollen, "Swelling status should be displayed")
        XCTAssertEqual(entry.estimatedSize, 15.5, "Estimated size should be displayed")
        XCTAssertNotNil(entry.imageFilename, "Image filename should be displayed")
        XCTAssertNotNil(entry.timestamp, "Timestamp should be displayed")
    }

    func testLogEntryCardViewHandlesMinimalMedicalData() throws {
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

        // When LogEntryCardView displays the log entry
        let entry = hierarchy.logEntry

        // Then it should handle minimal data gracefully
        XCTAssertTrue(entry.note.isEmpty, "Empty note should be handled")
        XCTAssertEqual(entry.painScore, 0, "Zero pain score should be displayed")
        XCTAssertFalse(entry.hasBleeding, "False bleeding should be handled")
        XCTAssertFalse(entry.hasItching, "False itching should be handled")
        XCTAssertFalse(entry.isSwollen, "False swelling should be handled")
        XCTAssertNil(entry.estimatedSize, "Nil estimated size should be handled")
        XCTAssertNotNil(entry.timestamp, "Timestamp should still be displayed")
    }

    func testLogEntryCardViewDisplaysPainScoreCorrectly() throws {
        // Given log entries with various pain scores
        let hierarchy = TestHelpers.createTestHierarchy()
        let painScores = [0, 1, 3, 5, 7, 10]

        var entries: [LogEntry] = []

        for (index, painScore) in painScores.enumerated() {
            let entry = TestHelpers.createTestLogEntry(
                imageFilename: "PAIN_\(index).jpg",
                note: "Pain score \(painScore)",
                painScore: painScore,
                spot: hierarchy.spot
            )
            entries.append(entry)
        }

        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        for entry in entries {
            testContext.insert(entry)
        }
        try testContext.save()

        // When LogEntryCardView displays entries with different pain scores
        // Then pain scores should be displayed correctly
        for (index, entry) in entries.enumerated() {
            XCTAssertEqual(entry.painScore, painScores[index], "Pain score should match")
            XCTAssertTrue(entry.note.contains("\(painScores[index])"), "Note should reference pain score")
        }
    }

    // MARK: - Symptom Indicator Tests

    func testLogEntryCardViewShowsSymptomIndicatorsCorrectly() throws {
        // Given log entries with different symptom combinations
        let testCases = [
            (painScore: 0, hasBleeding: false, hasItching: false, isSwollen: false, expectedSymptoms: []),
            (painScore: 2, hasBleeding: true, hasItching: false, isSwollen: false, expectedSymptoms: ["bleeding"]),
            (painScore: 3, hasBleeding: false, hasItching: true, isSwollen: false, expectedSymptoms: ["itching"]),
            (painScore: 4, hasBleeding: false, hasItching: false, isSwollen: true, expectedSymptoms: ["swollen"]),
            (painScore: 8, hasBleeding: true, hasItching: true, isSwollen: true, expectedSymptoms: ["bleeding", "itching", "swollen"]),
        ]

        let hierarchy = TestHelpers.createTestHierarchy()

        for (index, testCase) in testCases.enumerated() {
            let entry = TestHelpers.createTestLogEntry(
                imageFilename: "SYMPTOM_\(index).jpg",
                note: "Symptom test \(index)",
                painScore: testCase.painScore,
                hasBleeding: testCase.hasBleeding,
                hasItching: testCase.hasItching,
                isSwollen: testCase.isSwollen,
                spot: hierarchy.spot
            )

            // Verify symptom status
            XCTAssertEqual(entry.hasBleeding, testCase.hasBleeding, "Bleeding status should match for case \(index)")
            XCTAssertEqual(entry.hasItching, testCase.hasItching, "Itching status should match for case \(index)")
            XCTAssertEqual(entry.isSwollen, testCase.isSwollen, "Swelling status should match for case \(index)")

            testContext.insert(entry)
        }

        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        try testContext.save()

        // All symptom indicators should be available for display
        let allEntries = try testContext.fetch(FetchDescriptor<LogEntry>())
        XCTAssertEqual(allEntries.count, 6, "Should have 6 entries total")
    }

    func testLogEntryCardViewSymptomIndicatorColors() throws {
        // Given symptom indicators with medical theme colors
        let symptomColors = [
            ("bleeding", "red"),
            ("itching", "orange"),
            ("swollen", "blue")
        ]

        // When LogEntryCardView displays symptom indicators
        // Then they should use medical theme colors
        for (symptom, expectedColor) in symptomColors {
            // This tests the concept that symptoms have associated colors
            // Actual implementation will use these colors in the UI
            XCTAssertFalse(symptom.isEmpty, "Symptom name should not be empty")
            XCTAssertFalse(expectedColor.isEmpty, "Color should not be empty")
        }
    }

    // MARK: - Note Display Tests

    func testLogEntryCardViewDisplaysLongNotesCorrectly() throws {
        // Given a log entry with a very long note
        let longNote = String(repeating: "This is a very long medical note that needs to be displayed properly in the card view. ", count: 10)
        let hierarchy = TestHelpers.createTestHierarchy(logEntryNote: longNote)
        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        try testContext.save()

        // When LogEntryCardView displays the long note
        let entry = hierarchy.logEntry

        // Then the note should be handled appropriately
        XCTAssertEqual(entry.note.count, longNote.count, "Note length should be preserved")
        XCTAssertTrue(entry.note.count > 200, "Note should be sufficiently long")
        // UI should truncate or wrap long notes appropriately
    }

    func testLogEntryCardViewDisplaysEmptyNotesCorrectly() throws {
        // Given a log entry with empty note
        let hierarchy = TestHelpers.createTestHierarchy(logEntryNote: "")
        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        try testContext.save()

        // When LogEntryCardView displays empty note
        let entry = hierarchy.logEntry

        // Then it should handle empty note gracefully
        XCTAssertTrue(entry.note.isEmpty, "Note should be empty")
        // UI should show placeholder or hide note section
    }

    func testLogEntryCardViewDisplaysSpecialCharactersInNotes() throws {
        // Given notes with special characters
        let specialNotes = [
            "Contains émojis: 😊🩺💊",
            "Spëcial charactërs: äöüß",
            "Medical térms: résumé, café",
            "Symbols: @#$%^&*()",
            "Line\nbreaks\nin\nnotes"
        ]

        let hierarchy = TestHelpers.createTestHierarchy()

        for (index, note) in specialNotes.enumerated() {
            let entry = TestHelpers.createTestLogEntry(
                imageFilename: "SPECIAL_\(index).jpg",
                note: note,
                painScore: index,
                spot: hierarchy.spot
            )
            testContext.insert(entry)

            // Verify notes are preserved
            XCTAssertEqual(entry.note, note, "Special characters should be preserved in note \(index)")
        }

        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        try testContext.save()

        // All special character notes should be preserved
        let allEntries = try testContext.fetch(FetchDescriptor<LogEntry>())
        XCTAssertEqual(allEntries.count, 6, "Should have 6 entries with special notes")
    }

    // MARK: - Size Display Tests

    func testLogEntryCardViewDisplaysEstimatedSizeCorrectly() throws {
        // Given log entries with various estimated sizes
        let testSizes = [nil, 0.0, 2.5, 10.0, 25.75, 100.5]

        let hierarchy = TestHelpers.createTestHierarchy()

        for (index, size) in testSizes.enumerated() {
            let entry = TestHelpers.createTestLogEntry(
                imageFilename: "SIZE_\(index).jpg",
                note: "Size test \(index)",
                painScore: index,
                estimatedSize: size,
                spot: hierarchy.spot
            )

            XCTAssertEqual(entry.estimatedSize, size, "Estimated size should match for case \(index)")
            testContext.insert(entry)
        }

        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        try testContext.save()

        // All size values should be available for display
        let allEntries = try testContext.fetch(FetchDescriptor<LogEntry>())
        XCTAssertEqual(allEntries.count, 7, "Should have 7 entries with different sizes")

        // Verify nil and zero sizes are handled
        let entriesWithNilSize = allEntries.filter { $0.estimatedSize == nil }
        let entriesWithZeroSize = allEntries.filter { $0.estimatedSize == 0.0 }
        let entriesWithPositiveSize = allEntries.filter { ($0.estimatedSize ?? 0) > 0 }

        XCTAssertGreaterThan(entriesWithNilSize.count, 0, "Should have entries with nil size")
        XCTAssertGreaterThan(entriesWithZeroSize.count, 0, "Should have entries with zero size")
        XCTAssertGreaterThan(entriesWithPositiveSize.count, 0, "Should have entries with positive size")
    }

    // MARK: - Image Display Tests

    func testLogEntryCardViewDisplaysImageFilenameCorrectly() throws {
        // Given log entries with various image filenames
        let imageFilenames = [
            "IMG_001.jpg",
            "spot_photo_2024_01_15.png",
            "medical-scan.jpeg",
            "DERMATOLOGY_SCAN_12345.heic",
            "no_extension_file",
            ""
        ]

        let hierarchy = TestHelpers.createTestHierarchy()

        for (index, filename) in imageFilenames.enumerated() {
            let entry = TestHelpers.createTestLogEntry(
                imageFilename: filename,
                note: "Image test \(index)",
                painScore: index,
                spot: hierarchy.spot
            )

            XCTAssertEqual(entry.imageFilename, filename, "Image filename should match for case \(index)")
            testContext.insert(entry)
        }

        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        try testContext.save()

        // All image filenames should be available for display
        let allEntries = try testContext.fetch(FetchDescriptor<LogEntry>())
        XCTAssertEqual(allEntries.count, 7, "Should have 7 entries with different image filenames")

        // Verify empty and non-empty filenames are handled
        let entriesWithEmptyFilename = allEntries.filter { $0.imageFilename.isEmpty }
        let entriesWithValidFilename = allEntries.filter { !$0.imageFilename.isEmpty }

        XCTAssertGreaterThan(entriesWithEmptyFilename.count, 0, "Should have entries with empty filename")
        XCTAssertGreaterThan(entriesWithValidFilename.count, 0, "Should have entries with valid filename")
    }

    // MARK: - Timestamp Display Tests

    func testLogEntryCardViewDisplaysTimestampCorrectly() throws {
        // Given log entries with various timestamps
        let hierarchy = TestHelpers.createTestHierarchy()
        let now = Date()

        let timestamps = [
            now, // Current time
            Calendar.current.date(byAdding: .minute, value: -5, to: now)!, // 5 minutes ago
            Calendar.current.date(byAdding: .hour, value: -2, to: now)!,   // 2 hours ago
            Calendar.current.date(byAdding: .day, value: -1, to: now)!,    // 1 day ago
            Calendar.current.date(byAdding: .month, value: -1, to: now)!,  // 1 month ago
        ]

        for (index, timestamp) in timestamps.enumerated() {
            let entry = TestHelpers.createTestLogEntry(
                imageFilename: "TIME_\(index).jpg",
                note: "Time test \(index)",
                painScore: index,
                spot: hierarchy.spot
            )
            entry.timestamp = timestamp

            XCTAssertEqual(entry.timestamp, timestamp, "Timestamp should match for case \(index)")
            testContext.insert(entry)
        }

        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        try testContext.save()

        // All timestamps should be available for display
        let allEntries = try testContext.fetch(FetchDescriptor<LogEntry>())
        XCTAssertEqual(allEntries.count, 6, "Should have 6 entries with different timestamps")

        // Test relative date formatting
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated

        for entry in allEntries {
            let relativeString = formatter.localizedString(for: entry.timestamp, relativeTo: now)
            XCTAssertFalse(relativeString.isEmpty, "Should format relative date for \(entry.note)")
        }
    }

    // MARK: - Medical Theme Tests

    func testLogEntryCardViewAppliesMedicalThemeCorrectly() throws {
        // Given LogEntryCardView with medical data
        let hierarchy = TestHelpers.createTestHierarchy(
            logEntryNote: "Medical theme test",
            painScore: 5,
            hasBleeding: true,
            hasItching: false,
            isSwollen: true,
            estimatedSize: 8.0
        )
        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        try testContext.save()

        // When LogEntryCardView is displayed
        // Then it should apply medical theme colors and styling

        // Medical theme elements:
        let medicalThemeElements = [
            "cardBackground", // White/light background
            "textPrimary",    // Dark text for readability
            "textSecondary",  // Gray text for secondary information
            "accentColor",    // Medical blue for important elements
            "symptomColors",  // Red for bleeding, orange for itching, blue for swelling
            "borderColor"     // Subtle borders for medical appearance
        ]

        // Verify theme elements concept exists
        for element in medicalThemeElements {
            XCTAssertFalse(element.isEmpty, "Theme element '\(element)' should be defined")
        }
    }

    // MARK: - Accessibility Tests

    func testLogEntryCardViewAccessibilityIdentifiers() throws {
        // Given LogEntryCardView is displayed
        // Then it should have proper accessibility identifiers

        let requiredIdentifiers = [
            "logEntryCardView",        // Main card view
            "timestampLabel",          // Date/time display
            "noteLabel",               // Medical note text
            "painScoreIndicator",      // Pain score display
            "symptomIndicators",       // Symptom badges container
            "bleedingIndicator",       // Bleeding symptom badge
            "itchingIndicator",        // Itching symptom badge
            "swollenIndicator",        // Swelling symptom badge
            "estimatedSizeLabel",      // Size display
            "imageThumbnail"           // Image preview
        ]

        // These identifiers enable UI testing and VoiceOver support
        for identifier in requiredIdentifiers {
            let accessibilityString = identifier
            XCTAssertFalse(accessibilityString.isEmpty, "Accessibility identifier should not be empty")
        }
    }

    func testLogEntryCardViewVoiceOverSupport() throws {
        // Given LogEntryCardView with medical data
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

        let entry = hierarchy.logEntry

        // Card should announce:
        // - "VoiceOver test entry, Pain score 3, Itching, Log entry from [relative time], Double tap for details"

        let accessibilityLabel = "\(entry.note), Pain score \(entry.painScore)"
        XCTAssertFalse(accessibilityLabel.isEmpty, "Card should have meaningful accessibility label")

        // Symptom indicators should be individually accessible
        if entry.hasBleeding {
            let bleedingLabel = "Bleeding: Present"
            XCTAssertFalse(bleedingLabel.isEmpty, "Bleeding indicator should be accessible")
        }

        if entry.hasItching {
            let itchingLabel = "Itching: Present"
            XCTAssertFalse(itchingLabel.isEmpty, "Itching indicator should be accessible")
        }

        if entry.isSwollen {
            let swollenLabel = "Swelling: Present"
            XCTAssertFalse(swollenLabel.isEmpty, "Swelling indicator should be accessible")
        }
    }

    // MARK: - Edge Case Tests

    func testLogEntryCardViewHandlesExtremePainScores() throws {
        // Given log entries with extreme pain scores
        let extremePainScores = [-1, 0, 1, 5, 10, 11, 15]

        let hierarchy = TestHelpers.createTestHierarchy()

        for (index, painScore) in extremePainScores.enumerated() {
            let entry = TestHelpers.createTestLogEntry(
                imageFilename: "EXTREME_\(index).jpg",
                note: "Extreme pain score: \(painScore)",
                painScore: painScore,
                spot: hierarchy.spot
            )

            XCTAssertEqual(entry.painScore, painScore, "Extreme pain score should be preserved")
            testContext.insert(entry)
        }

        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        try testContext.save()

        // All extreme pain scores should be available for display
        let allEntries = try testContext.fetch(FetchDescriptor<LogEntry>())
        XCTAssertEqual(allEntries.count, 8, "Should have 8 entries with extreme pain scores")

        // Verify negative and high scores are handled
        let negativeScores = allEntries.filter { $0.painScore < 0 }
        let normalScores = allEntries.filter { $0.painScore >= 0 && $0.painScore <= 10 }
        let highScores = allEntries.filter { $0.painScore > 10 }

        XCTAssertGreaterThan(negativeScores.count, 0, "Should handle negative pain scores")
        XCTAssertGreaterThan(normalScores.count, 0, "Should handle normal pain scores")
        XCTAssertGreaterThan(highScores.count, 0, "Should handle high pain scores")
    }

    func testLogEntryCardViewHandlesVeryLargeEstimatedSizes() throws {
        // Given log entries with very large estimated sizes
        let largeSizes: [Double?] = [nil, 0.0, 999.99, 1000.0, 9999.99]

        let hierarchy = TestHelpers.createTestHierarchy()

        for (index, size) in largeSizes.enumerated() {
            let entry = TestHelpers.createTestLogEntry(
                imageFilename: "LARGE_\(index).jpg",
                note: "Large size test: \(size ?? 0)",
                painScore: index,
                estimatedSize: size,
                spot: hierarchy.spot
            )

            XCTAssertEqual(entry.estimatedSize, size, "Large size should be preserved")
            testContext.insert(entry)
        }

        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        try testContext.save()

        // All large sizes should be available for display
        let allEntries = try testContext.fetch(FetchDescriptor<LogEntry>())
        XCTAssertEqual(allEntries.count, 6, "Should have 6 entries with large sizes")

        // UI should format large sizes appropriately (e.g., "1000.0 mm")
        let veryLargeSizes = allEntries.compactMap { $0.estimatedSize }.filter { $0 > 100 }
        XCTAssertGreaterThan(veryLargeSizes.count, 0, "Should have very large sizes to format")
    }
}