//
//  TimelineViewTests.swift
//  SpotOnTests
//
//  Created by Non on 11/29/25.
//

import XCTest
import SwiftData
@testable import SpotOn

final class TimelineViewTests: XCTestCase {

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

    // MARK: - Chronological Order Tests

    func testTimelineViewDisplaysLogEntriesInCorrectOrder() throws {
        // Given a spot with multiple log entries
        let hierarchy = TestHelpers.createTestHierarchy(
            userName: "Test User",
            spotTitle: "Test Spot"
        )

        // Create log entries with specific timestamps
        let baseDate = Date()
        let timestamps = [
            Calendar.current.date(byAdding: .day, value: -10, to: baseDate)!,  // Oldest
            Calendar.current.date(byAdding: .day, value: -5, to: baseDate)!,   // Middle
            Calendar.current.date(byAdding: .day, value: -2, to: baseDate)!,   // Recent
            Calendar.current.date(byAdding: .hour, value: -3, to: baseDate)!,   // Newest
        ]

        let entries = timestamps.enumerated().map { index, timestamp in
            TestHelpers.createTestLogEntry(
                imageFilename: "IMG_\(index).jpg",
                note: "Entry \(index + 1)",
                painScore: index,
                spot: hierarchy.spot
            )
        }

        // Set timestamps
        for (index, entry) in entries.enumerated() {
            entry.timestamp = timestamps[index]
        }

        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        for entry in entries {
            testContext.insert(entry)
        }
        try testContext.save()

        // When TimelineView displays entries
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == hierarchy.spot.id },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let sortedEntries = try testContext.fetch(fetchDescriptor)

        // Then entries should be in chronological order (newest first)
        XCTAssertEqual(sortedEntries.count, 5, "Should have 5 total entries")

        // Verify order: newest should be first
        for i in 0..<(sortedEntries.count - 1) {
            XCTAssertGreaterThanOrEqual(
                sortedEntries[i].timestamp,
                sortedEntries[i + 1].timestamp,
                "Entry \(i) should be newer or same time as entry \(i + 1)"
            )
        }

        // Verify specific order based on our timestamps
        XCTAssertEqual(sortedEntries[0].note, "Entry 4", "Newest entry should be first")
        XCTAssertEqual(sortedEntries[1].note, "Entry 3", "Second newest should be second")
        XCTAssertEqual(sortedEntries[2].note, "Entry 2", "Middle entry should be third")
        XCTAssertEqual(sortedEntries[3].note, "Entry 1", "Fourth entry should be fourth")
        XCTAssertEqual(sortedEntries[4].note, "Initial observation", "Original entry should be last")
    }

    func testTimelineViewHandlesEntriesWithSameTimestamp() throws {
        // Given multiple log entries with the same timestamp
        let hierarchy = TestHelpers.createTestHierarchy()
        let sameTimestamp = Date()

        let entry1 = TestHelpers.createTestLogEntry(
            imageFilename: "SAME_1.jpg",
            note: "First same-time entry",
            painScore: 1,
            spot: hierarchy.spot
        )

        let entry2 = TestHelpers.createTestLogEntry(
            imageFilename: "SAME_2.jpg",
            note: "Second same-time entry",
            painScore: 2,
            spot: hierarchy.spot
        )

        entry1.timestamp = sameTimestamp
        entry2.timestamp = sameTimestamp

        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        testContext.insert(entry1)
        testContext.insert(entry2)
        try testContext.save()

        // When TimelineView displays entries
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == hierarchy.spot.id },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let sortedEntries = try testContext.fetch(fetchDescriptor)

        // Then entries with same timestamp should be handled gracefully
        XCTAssertEqual(sortedEntries.count, 3, "Should have 3 entries")

        // Entries with same timestamp should appear together
        let sameTimeEntries = sortedEntries.filter {
            Calendar.current.isDate($0.timestamp, equalTo: sameTimestamp, toGranularity: .second)
        }
        XCTAssertEqual(sameTimeEntries.count, 2, "Should have 2 entries with same timestamp")
    }

    // MARK: - Empty State Tests

    func testTimelineViewShowsEmptyStateWhenNoLogEntries() throws {
        // Given a spot with no log entries
        let user = TestHelpers.createTestUserProfile()
        let spot = TestHelpers.createTestSpot(userProfile: user)
        testContext.insert(user)
        testContext.insert(spot)
        try testContext.save()

        // When TimelineView displays entries
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == spot.id }
        )
        let entries = try testContext.fetch(fetchDescriptor)

        // Then empty state should be displayed
        XCTAssertEqual(entries.count, 0, "Should have no log entries")
        // TimelineView should display empty state UI
    }

    func testTimelineViewShowsEmptyStateForNonExistentSpot() throws {
        // Given a non-existent spot ID
        let nonExistentSpotId = UUID()

        // When TimelineView tries to fetch entries
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == nonExistentSpotId }
        )
        let entries = try testContext.fetch(fetchDescriptor)

        // Then no entries should be found
        XCTAssertEqual(entries.count, 0, "Should have no entries for non-existent spot")
    }

    // MARK: - Filtering Tests

    func testTimelineViewFiltersLogEntriesBySpotCorrectly() throws {
        // Given multiple spots with their own log entries
        let user1 = TestHelpers.createTestUserProfile(userName: "User 1")
        let user2 = TestHelpers.createTestUserProfile(userName: "User 2")
        let spot1 = TestHelpers.createTestSpot(title: "Spot 1", userProfile: user1)
        let spot2 = TestHelpers.createTestSpot(title: "Spot 2", userProfile: user2)

        let entry1 = TestHelpers.createTestLogEntry(
            imageFilename: "SPOT1_IMG.jpg",
            note: "Entry for spot 1",
            painScore: 1,
            spot: spot1
        )

        let entry2 = TestHelpers.createTestLogEntry(
            imageFilename: "SPOT2_IMG.jpg",
            note: "Entry for spot 2",
            painScore: 2,
            spot: spot2
        )

        testContext.insert(user1)
        testContext.insert(user2)
        testContext.insert(spot1)
        testContext.insert(spot2)
        testContext.insert(entry1)
        testContext.insert(entry2)
        try testContext.save()

        // When TimelineView filters for spot1 entries
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == spot1.id },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let spot1Entries = try testContext.fetch(fetchDescriptor)

        // Then only spot1 entries should be returned
        XCTAssertEqual(spot1Entries.count, 1, "Should have 1 entry for spot1")
        XCTAssertEqual(spot1Entries.first?.note, "Entry for spot 1", "Should show correct entry")
        XCTAssertNotEqual(spot1Entries.first?.note, "Entry for spot 2", "Should not show spot2 entry")

        // When TimelineView filters for spot2 entries
        let spot2FetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == spot2.id },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let spot2Entries = try testContext.fetch(spot2FetchDescriptor)

        // Then only spot2 entries should be returned
        XCTAssertEqual(spot2Entries.count, 1, "Should have 1 entry for spot2")
        XCTAssertEqual(spot2Entries.first?.note, "Entry for spot 2", "Should show correct entry")
    }

    func testTimelineViewHandlesInactiveSpots() throws {
        // Given an inactive spot with log entries
        let user = TestHelpers.createTestUserProfile()
        let inactiveSpot = TestHelpers.createTestSpot(
            title: "Inactive Spot",
            isActive: false,
            userProfile: user
        )

        let entry = TestHelpers.createTestLogEntry(
            imageFilename: "INACTIVE_IMG.jpg",
            note: "Entry for inactive spot",
            painScore: 0,
            spot: inactiveSpot
        )

        testContext.insert(user)
        testContext.insert(inactiveSpot)
        testContext.insert(entry)
        try testContext.save()

        // When TimelineView displays entries for inactive spot
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == inactiveSpot.id },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let entries = try testContext.fetch(fetchDescriptor)

        // Then entries should still be displayed
        XCTAssertEqual(entries.count, 1, "Should show entries for inactive spots")
        XCTAssertEqual(entries.first?.note, "Entry for inactive spot", "Should show correct entry")
        XCTAssertFalse(inactiveSpot.isActive, "Spot should be inactive but still show entries")
    }

    // MARK: - Date Display Tests

    func testTimelineViewDisplaysRelativeDatesCorrectly() throws {
        // Given log entries with various timestamps
        let hierarchy = TestHelpers.createTestHierarchy()
        let now = Date()

        let entries = [
            (Calendar.current.date(byAdding: .minute, value: -5, to: now)!, "5 minutes ago"),
            (Calendar.current.date(byAdding: .hour, value: -2, to: now)!, "2 hours ago"),
            (Calendar.current.date(byAdding: .day, value: -1, to: now)!, "1 day ago"),
            (Calendar.current.date(byAdding: .weekOfYear, value: -1, to: now)!, "1 week ago"),
            (Calendar.current.date(byAdding: .month, value: -1, to: now)!, "1 month ago"),
        ]

        for (index, (timestamp, _)) in entries.enumerated() {
            let entry = TestHelpers.createTestLogEntry(
                imageFilename: "RELATIVE_\(index).jpg",
                note: "Relative date test \(index)",
                painScore: index,
                spot: hierarchy.spot
            )
            entry.timestamp = timestamp
            testContext.insert(entry)
        }

        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        try testContext.save()

        // When TimelineView displays entries
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == hierarchy.spot.id },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let sortedEntries = try testContext.fetch(fetchDescriptor)

        // Then relative dates should be displayed correctly
        XCTAssertEqual(sortedEntries.count, 6, "Should have 6 total entries")

        // Test that we can format relative dates (actual UI implementation will format these)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        for entry in sortedEntries {
            let relativeString = formatter.localizedString(for: entry.timestamp, relativeTo: now)
            XCTAssertFalse(relativeString.isEmpty, "Should generate relative date string for \(entry.note)")
        }
    }

    // MARK: - Performance Tests

    func testTimelineViewPerformanceWithManyEntries() throws {
        // Given a spot with many log entries
        let user = TestHelpers.createTestUserProfile()
        let spot = TestHelpers.createTestSpot(userProfile: user)
        testContext.insert(user)
        testContext.insert(spot)

        let entryCount = 500
        let baseDate = Date()

        for i in 1...entryCount {
            let entry = TestHelpers.createTestLogEntry(
                imageFilename: "PERF_\(i).jpg",
                note: "Performance test entry \(i)",
                painScore: i % 10,
                spot: spot
            )
            entry.timestamp = Calendar.current.date(byAdding: .minute, value: -i, to: baseDate)!
            testContext.insert(entry)
        }
        try testContext.save()

        // When TimelineView loads and sorts entries
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == spot.id },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        // Then performance should be acceptable
        measure(metrics: [XCTClockMetric()]) {
            do {
                _ = try testContext.fetch(fetchDescriptor)
            } catch {
                XCTFail("Loading many timeline entries should not fail: \(error)")
            }
        }

        // Verify all entries were loaded
        do {
            let loadedEntries = try testContext.fetch(fetchDescriptor)
            XCTAssertEqual(loadedEntries.count, entryCount, "Should load all entries")
        } catch {
            XCTFail("Should successfully load all entries")
        }
    }

    // MARK: - Data Integrity Tests

    func testTimelineViewMaintainsDataIntegrity() throws {
        // Given complex hierarchy with multiple users, spots, and entries
        let users = (1...3).map { i in
            TestHelpers.createTestUserProfile(userName: "User \(i)")
        }

        let spots = users.enumerated().map { (index, user) in
            TestHelpers.createTestSpot(
                title: "Spot \(index + 1)",
                userProfile: user
            )
        }

        var allEntries: [LogEntry] = []

        for (spotIndex, spot) in spots.enumerated() {
            for entryIndex in 1...5 {
                let entry = TestHelpers.createTestLogEntry(
                    imageFilename: "INTEGRITY_\(spotIndex)_\(entryIndex).jpg",
                    note: "Entry \(entryIndex) for spot \(spotIndex + 1)",
                    painScore: entryIndex,
                    spot: spot
                )
                entry.timestamp = Calendar.current.date(byAdding: .day, value: -(entryIndex + spotIndex * 10), to: Date())!
                allEntries.append(entry)
            }
        }

        // Insert all data
        for user in users { testContext.insert(user) }
        for spot in spots { testContext.insert(spot) }
        for entry in allEntries { testContext.insert(entry) }
        try testContext.save()

        // When TimelineView displays entries for a specific spot
        let targetSpot = spots[1] // Second spot
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == targetSpot.id },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let filteredEntries = try testContext.fetch(fetchDescriptor)

        // Then data integrity should be maintained
        XCTAssertEqual(filteredEntries.count, 5, "Should have 5 entries for target spot")

        for entry in filteredEntries {
            XCTAssertEqual(entry.spot?.id, targetSpot.id, "All entries should belong to target spot")
            XCTAssertTrue(entry.note.contains("spot 2"), "All notes should reference spot 2")
        }

        // Verify chronological order
        for i in 0..<(filteredEntries.count - 1) {
            XCTAssertGreaterThanOrEqual(
                filteredEntries[i].timestamp,
                filteredEntries[i + 1].timestamp,
                "Entries should be in chronological order"
            )
        }
    }

    // MARK: - Edge Case Tests

    func testTimelineViewHandlesFutureDatedEntries() throws {
        // Given a log entry with a future timestamp
        let hierarchy = TestHelpers.createTestHierarchy()
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        let futureEntry = TestHelpers.createTestLogEntry(
            imageFilename: "FUTURE_IMG.jpg",
            note: "Future dated entry",
            painScore: 0,
            spot: hierarchy.spot
        )
        futureEntry.timestamp = futureDate

        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        testContext.insert(futureEntry)
        try testContext.save()

        // When TimelineView displays entries
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == hierarchy.spot.id },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let sortedEntries = try testContext.fetch(fetchDescriptor)

        // Then future-dated entry should appear first
        XCTAssertEqual(sortedEntries.count, 2, "Should have 2 entries")
        XCTAssertEqual(sortedEntries[0].note, "Future dated entry", "Future entry should be first")
        XCTAssertEqual(sortedEntries[1].note, "Initial observation", "Normal entry should be second")
    }

    func testTimelineViewHandlesVeryOldEntries() throws {
        // Given a very old log entry
        let hierarchy = TestHelpers.createTestHierarchy()
        let veryOldDate = Calendar.current.date(byAdding: .year, value: -5, to: Date())!

        let oldEntry = TestHelpers.createTestLogEntry(
            imageFilename: "OLD_IMG.jpg",
            note: "Very old entry",
            painScore: 1,
            spot: hierarchy.spot
        )
        oldEntry.timestamp = veryOldDate

        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        testContext.insert(oldEntry)
        try testContext.save()

        // When TimelineView displays entries
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == hierarchy.spot.id },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let sortedEntries = try testContext.fetch(fetchDescriptor)

        // Then very old entry should be handled correctly
        XCTAssertEqual(sortedEntries.count, 2, "Should have 2 entries")
        XCTAssertEqual(sortedEntries[1].note, "Very old entry", "Old entry should be last")
        XCTAssertTrue(sortedEntries[1].timestamp < Date(), "Old entry should have past timestamp")
    }
}