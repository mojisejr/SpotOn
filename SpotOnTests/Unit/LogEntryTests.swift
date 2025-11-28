//
//  LogEntryTests.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import XCTest
import SwiftData
@testable import SpotOn

final class LogEntryTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testUserProfile: UserProfile!
    var testSpot: Spot!

    override func setUpWithError() throws {
        // Create in-memory test container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: UserProfile.self, Spot.self, LogEntry.self, configurations: config)
        modelContext = ModelContext(modelContainer)

        // Create test user profile
        testUserProfile = UserProfile(
            id: UUID(),
            name: "Test User",
            relation: "Self",
            avatarColor: "#FF6B6B",
            createdAt: Date()
        )
        modelContext.insert(testUserProfile)

        // Create test spot
        testSpot = Spot(
            id: UUID(),
            title: "Test Mole",
            bodyPart: "Left Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )
        modelContext.insert(testSpot)
        try modelContext.save()
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
        testUserProfile = nil
        testSpot = nil
    }

    // MARK: - Initialization Tests

    func testLogEntryInitialization() throws {
        // Given
        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "IMG_001.jpg",
            note: "Mole looks normal today",
            painScore: 2,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: 5.5,
            spot: testSpot
        )

        // Then
        XCTAssertNotNil(logEntry.id)
        XCTAssertNotNil(logEntry.timestamp)
        XCTAssertEqual(logEntry.imageFilename, "IMG_001.jpg")
        XCTAssertEqual(logEntry.note, "Mole looks normal today")
        XCTAssertEqual(logEntry.painScore, 2)
        XCTAssertFalse(logEntry.hasBleeding)
        XCTAssertFalse(logEntry.hasItching)
        XCTAssertFalse(logEntry.isSwollen)
        XCTAssertEqual(logEntry.estimatedSize, 5.5)
        XCTAssertEqual(logEntry.spot, testSpot)
    }

    // MARK: - Basic Property Tests

    func testLogEntryImageFilenameProperty() throws {
        // Given
        let validFilenames = ["IMG_001.jpg", "photo_2023.png", "scan_1234.jpeg", "mole_shot.heic"]

        for filename in validFilenames {
            let logEntry = LogEntry(
                id: UUID(),
                timestamp: Date(),
                imageFilename: filename,
                note: "Test note",
                painScore: 0,
                hasBleeding: false,
                hasItching: false,
                isSwollen: false,
                estimatedSize: nil,
                spot: testSpot
            )

            // Then
            XCTAssertEqual(logEntry.imageFilename, filename)
            XCTAssertFalse(logEntry.imageFilename.isEmpty)
        }
    }

    func testLogEntryNoteProperty() throws {
        // Given
        let validNotes = [
            "Looks good today",
            "Slight redness observed",
            "No changes from previous entry",
            "Doctor visit scheduled",
            "Applied medicated cream"
        ]

        for note in validNotes {
            let logEntry = LogEntry(
                id: UUID(),
                timestamp: Date(),
                imageFilename: "test.jpg",
                note: note,
                painScore: 0,
                hasBleeding: false,
                hasItching: false,
                isSwollen: false,
                estimatedSize: nil,
                spot: testSpot
            )

            // Then
            XCTAssertEqual(logEntry.note, note)
            XCTAssertFalse(logEntry.note.isEmpty)
        }
    }

    // MARK: - Medical Data Tests

    func testLogEntryPainScoreProperty() throws {
        // Given - Test valid pain scores (0-10 scale)
        for score in 0...10 {
            let logEntry = LogEntry(
                id: UUID(),
                timestamp: Date(),
                imageFilename: "test.jpg",
                note: "Pain score test",
                painScore: score,
                hasBleeding: false,
                hasItching: false,
                isSwollen: false,
                estimatedSize: nil,
                spot: testSpot
            )

            // Then
            XCTAssertEqual(logEntry.painScore, score)
            XCTAssertGreaterThanOrEqual(logEntry.painScore, 0)
            XCTAssertLessThanOrEqual(logEntry.painScore, 10)
        }
    }

    func testLogEntrySymptomProperties() throws {
        // Given - Test all combinations of boolean symptom flags
        let symptomCombinations = [
            (false, false, false), // No symptoms
            (true, false, false),  // Bleeding only
            (false, true, false),  // Itching only
            (false, false, true),  // Swollen only
            (true, true, false),   // Bleeding + Itching
            (true, false, true),   // Bleeding + Swollen
            (false, true, true),   // Itching + Swollen
            (true, true, true)     // All symptoms
        ]

        for (hasBleeding, hasItching, isSwollen) in symptomCombinations {
            let logEntry = LogEntry(
                id: UUID(),
                timestamp: Date(),
                imageFilename: "test.jpg",
                note: "Symptom combination test",
                painScore: 0,
                hasBleeding: hasBleeding,
                hasItching: hasItching,
                isSwollen: isSwollen,
                estimatedSize: nil,
                spot: testSpot
            )

            // Then
            XCTAssertEqual(logEntry.hasBleeding, hasBleeding)
            XCTAssertEqual(logEntry.hasItching, hasItching)
            XCTAssertEqual(logEntry.isSwollen, isSwollen)
        }
    }

    func testLogEntryEstimatedSizeProperty() throws {
        // Given - Test various estimated sizes
        let validSizes = [1.0, 2.5, 5.0, 7.75, 10.0, 15.25]

        for size in validSizes {
            let logEntry = LogEntry(
                id: UUID(),
                timestamp: Date(),
                imageFilename: "test.jpg",
                note: "Size test",
                painScore: 0,
                hasBleeding: false,
                hasItching: false,
                isSwollen: false,
                estimatedSize: size,
                spot: testSpot
            )

            // Then
            XCTAssertEqual(logEntry.estimatedSize, size)
            XCTAssertGreaterThan(size!, 0)
        }
    }

    func testLogEntryNilEstimatedSize() throws {
        // Given
        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "test.jpg",
            note: "Nil size test",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: testSpot
        )

        // Then
        XCTAssertNil(logEntry.estimatedSize)
    }

    // MARK: - Edge Case Tests

    func testLogEntryWithEmptyImageFilename() throws {
        // Given
        let emptyFilename = ""
        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: emptyFilename,
            note: "Empty filename test",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: testSpot
        )

        // Then
        XCTAssertEqual(logEntry.imageFilename, emptyFilename)
        XCTAssertTrue(logEntry.imageFilename.isEmpty)
    }

    func testLogEntryWithEmptyNote() throws {
        // Given
        let emptyNote = ""
        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "test.jpg",
            note: emptyNote,
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: testSpot
        )

        // Then
        XCTAssertEqual(logEntry.note, emptyNote)
        XCTAssertTrue(logEntry.note.isEmpty)
    }

    func testLogEntryWithLongNote() throws {
        // Given
        let longNote = String(repeating: "This is a very long medical note describing the condition in detail. ", count: 10)
        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "test.jpg",
            note: longNote,
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: testSpot
        )

        // Then
        XCTAssertEqual(logEntry.note, longNote)
        XCTAssertGreaterThan(logEntry.note.count, 300)
    }

    func testLogEntryWithNegativePainScore() throws {
        // Given
        let negativeScore = -1
        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "test.jpg",
            note: "Negative pain score test",
            painScore: negativeScore,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: testSpot
        )

        // Then - Depending on validation, this might need to be adjusted
        XCTAssertEqual(logEntry.painScore, negativeScore)
        XCTAssertLessThan(logEntry.painScore, 0)
    }

    func testLogEntryWithHighPainScore() throws {
        // Given
        let highScore = 15
        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "test.jpg",
            note: "High pain score test",
            painScore: highScore,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: testSpot
        )

        // Then - Depending on validation, this might need to be adjusted
        XCTAssertEqual(logEntry.painScore, highScore)
        XCTAssertGreaterThan(logEntry.painScore, 10)
    }

    func testLogEntryWithZeroEstimatedSize() throws {
        // Given
        let zeroSize = 0.0
        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "test.jpg",
            note: "Zero size test",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: zeroSize,
            spot: testSpot
        )

        // Then
        XCTAssertEqual(logEntry.estimatedSize, zeroSize)
    }

    // MARK: - Date Tests

    func testLogEntryTimestampDate() throws {
        // Given
        let beforeCreation = Date()
        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "test.jpg",
            note: "Timestamp test",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: testSpot
        )
        let afterCreation = Date()

        // Then
        XCTAssertGreaterThanOrEqual(logEntry.timestamp, beforeCreation)
        XCTAssertLessThanOrEqual(logEntry.timestamp, afterCreation)
    }

    func testLogEntryWithSpecificTimestamp() throws {
        // Given
        let specificTimestamp = Date(timeIntervalSince1970: 1640995200) // Jan 1, 2022
        let logEntry = LogEntry(
            id: UUID(),
            timestamp: specificTimestamp,
            imageFilename: "test.jpg",
            note: "Specific timestamp test",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: testSpot
        )

        // Then
        XCTAssertEqual(logEntry.timestamp, specificTimestamp)
    }

    // MARK: - Spot Relationship Tests

    func testLogEntrySpotRelationship() throws {
        // Given
        let anotherSpot = Spot(
            id: UUID(),
            title: "Another Spot",
            bodyPart: "Right Leg",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )
        modelContext.insert(anotherSpot)
        try modelContext.save()

        let logEntry1 = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "test1.jpg",
            note: "Entry for first spot",
            painScore: 1,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: testSpot
        )

        let logEntry2 = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "test2.jpg",
            note: "Entry for second spot",
            painScore: 2,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: anotherSpot
        )

        // Then
        XCTAssertEqual(logEntry1.spot, testSpot)
        XCTAssertEqual(logEntry2.spot, anotherSpot)
        XCTAssertNotEqual(logEntry1.spot, logEntry2.spot)
    }

    // MARK: - SwiftData Integration Tests

    func testLogEntryInsertion() throws {
        // Given
        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "IMG_INSERT_TEST.jpg",
            note: "Insert test log entry",
            painScore: 3,
            hasBleeding: true,
            hasItching: false,
            isSwollen: true,
            estimatedSize: 7.5,
            spot: testSpot
        )

        // When
        modelContext.insert(logEntry)
        try modelContext.save()

        // Then
        let fetchDescriptor = FetchDescriptor<LogEntry>()
        let fetchedLogEntries = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(fetchedLogEntries.count, 1)
        XCTAssertEqual(fetchedLogEntries.first?.imageFilename, "IMG_INSERT_TEST.jpg")
        XCTAssertEqual(fetchedLogEntries.first?.note, "Insert test log entry")
        XCTAssertEqual(fetchedLogEntries.first?.painScore, 3)
        XCTAssertTrue(fetchedLogEntries.first?.hasBleeding ?? false)
        XCTAssertFalse(fetchedLogEntries.first?.hasItching ?? true)
        XCTAssertTrue(fetchedLogEntries.first?.isSwollen ?? false)
        XCTAssertEqual(fetchedLogEntries.first?.estimatedSize, 7.5)
        XCTAssertEqual(fetchedLogEntries.first?.spot?.title, testSpot.title)
    }

    func testLogEntryDeletion() throws {
        // Given
        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "IMG_DELETE_TEST.jpg",
            note: "Delete test log entry",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: testSpot
        )

        modelContext.insert(logEntry)
        try modelContext.save()

        // Verify insertion
        var fetchDescriptor = FetchDescriptor<LogEntry>()
        var fetchedLogEntries = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedLogEntries.count, 1)

        // When
        modelContext.delete(logEntry)
        try modelContext.save()

        // Then
        fetchedLogEntries = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedLogEntries.count, 0)
    }

    func testLogEntryQueryBySpot() throws {
        // Given
        let anotherSpot = Spot(
            id: UUID(),
            title: "Query Test Spot",
            bodyPart: "Back",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )
        modelContext.insert(anotherSpot)
        try modelContext.save()

        let spot1Entries = [
            LogEntry(id: UUID(), timestamp: Date(), imageFilename: "spot1_1.jpg", note: "Entry 1", painScore: 1, hasBleeding: false, hasItching: false, isSwollen: false, estimatedSize: nil, spot: testSpot),
            LogEntry(id: UUID(), timestamp: Date(), imageFilename: "spot1_2.jpg", note: "Entry 2", painScore: 2, hasBleeding: false, hasItching: false, isSwollen: false, estimatedSize: nil, spot: testSpot)
        ]

        let spot2Entries = [
            LogEntry(id: UUID(), timestamp: Date(), imageFilename: "spot2_1.jpg", note: "Entry 3", painScore: 3, hasBleeding: false, hasItching: false, isSwollen: false, estimatedSize: nil, spot: anotherSpot)
        ]

        for entry in spot1Entries + spot2Entries {
            modelContext.insert(entry)
        }
        try modelContext.save()

        // When
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.title == testSpot.title }
        )
        let fetchedEntries = try modelContext.fetch(fetchDescriptor)

        // Then
        XCTAssertEqual(fetchedEntries.count, 2)
        XCTAssertTrue(fetchedEntries.allSatisfy { $0.spot?.title == testSpot.title })
    }

    func testLogEntryQueryByPainScore() throws {
        // Given
        let lowPainEntries = [
            LogEntry(id: UUID(), timestamp: Date(), imageFilename: "low1.jpg", note: "Low pain 1", painScore: 1, hasBleeding: false, hasItching: false, isSwollen: false, estimatedSize: nil, spot: testSpot),
            LogEntry(id: UUID(), timestamp: Date(), imageFilename: "low2.jpg", note: "Low pain 2", painScore: 2, hasBleeding: false, hasItching: false, isSwollen: false, estimatedSize: nil, spot: testSpot)
        ]

        let highPainEntries = [
            LogEntry(id: UUID(), timestamp: Date(), imageFilename: "high1.jpg", note: "High pain 1", painScore: 8, hasBleeding: false, hasItching: false, isSwollen: false, estimatedSize: nil, spot: testSpot)
        ]

        for entry in lowPainEntries + highPainEntries {
            modelContext.insert(entry)
        }
        try modelContext.save()

        // When
        let lowPainDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.painScore <= 3 }
        )
        let lowPainEntries = try modelContext.fetch(lowPainDescriptor)

        let highPainDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.painScore >= 7 }
        )
        let highPainEntries = try modelContext.fetch(highPainDescriptor)

        // Then
        XCTAssertEqual(lowPainEntries.count, 2)
        XCTAssertEqual(highPainEntries.count, 1)
        XCTAssertTrue(lowPainEntries.allSatisfy { $0.painScore <= 3 })
        XCTAssertTrue(highPainEntries.allSatisfy { $0.painScore >= 7 })
    }

    func testLogEntryQueryBySymptoms() throws {
        // Given
        let bleedingEntries = [
            LogEntry(id: UUID(), timestamp: Date(), imageFilename: "bleed1.jpg", note: "Bleeding 1", painScore: 0, hasBleeding: true, hasItching: false, isSwollen: false, estimatedSize: nil, spot: testSpot),
            LogEntry(id: UUID(), timestamp: Date(), imageFilename: "bleed2.jpg", note: "Bleeding 2", painScore: 0, hasBleeding: true, hasItching: true, isSwollen: false, estimatedSize: nil, spot: testSpot)
        ]

        let noBleedingEntries = [
            LogEntry(id: UUID(), timestamp: Date(), imageFilename: "no_bleed.jpg", note: "No bleeding", painScore: 0, hasBleeding: false, hasItching: false, isSwollen: false, estimatedSize: nil, spot: testSpot)
        ]

        for entry in bleedingEntries + noBleedingEntries {
            modelContext.insert(entry)
        }
        try modelContext.save()

        // When
        let bleedingDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.hasBleeding == true }
        )
        let fetchedBleedingEntries = try modelContext.fetch(bleedingDescriptor)

        // Then
        XCTAssertEqual(fetchedBleedingEntries.count, 2)
        XCTAssertTrue(fetchedBleedingEntries.allSatisfy { $0.hasBleeding })
    }

    // MARK: - Performance Tests

    func testLogEntryCreationPerformance() throws {
        measure {
            for i in 0..<1000 {
                let _ = LogEntry(
                    id: UUID(),
                    timestamp: Date(),
                    imageFilename: "perf_test_\(i).jpg",
                    note: "Performance test log entry \(i)",
                    painScore: i % 11,
                    hasBleeding: i % 3 == 0,
                    hasItching: i % 4 == 0,
                    isSwollen: i % 5 == 0,
                    estimatedSize: Double(i) % 10.0,
                    spot: testSpot
                )
            }
        }
    }

    func testComplexLogEntryCreationPerformance() throws {
        // Test with all fields populated including medical data
        measure {
            for i in 0..<100 {
                let logEntry = LogEntry(
                    id: UUID(),
                    timestamp: Date(),
                    imageFilename: "complex_test_\(i).jpg",
                    note: "Complex medical log entry number \(i) with detailed observations about the current condition and any changes noticed since the previous entry. This includes color changes, size variations, and any new symptoms.",
                    painScore: Int.random(in: 0...10),
                    hasBleeding: Bool.random(),
                    hasItching: Bool.random(),
                    isSwollen: Bool.random(),
                    estimatedSize: Double.random(in: 0.1...20.0),
                    spot: testSpot
                )

                modelContext.insert(logEntry)
            }

            do {
                try modelContext.save()

                // Clean up for next iteration
                let fetchDescriptor = FetchDescriptor<LogEntry>()
                let entries = try modelContext.fetch(fetchDescriptor)
                for entry in entries {
                    modelContext.delete(entry)
                }
                try modelContext.save()
            } catch {
                XCTFail("Complex performance test failed: \(error)")
            }
        }
    }
}