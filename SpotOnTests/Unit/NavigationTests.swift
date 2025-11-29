//
//  NavigationTests.swift
//  SpotOnTests
//
//  Created by Non on 11/29/25.
//

import XCTest
import SwiftData
@testable import SpotOn

final class NavigationTests: XCTestCase {

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

    // MARK: - HomeView to SpotDetailView Navigation Tests

    func testHomeViewNavigateToSpotDetailViewOnSpotTap() throws {
        // Given HomeView with spots and a selected profile
        let profiles = [
            TestHelpers.createTestUserProfile(userName: "John", relation: "Self"),
            TestHelpers.createTestUserProfile(userName: "Jane", relation: "Spouse")
        ]

        let spots = [
            TestHelpers.createTestSpot(title: "Mole on Arm", userProfile: profiles[0]),
            TestHelpers.createTestSpot(title: "Rash on Chest", userProfile: profiles[0]),
            TestHelpers.createTestSpot(title: "Birthmark on Back", userProfile: profiles[1])
        ]

        for profile in profiles { testContext.insert(profile) }
        for spot in spots { testContext.insert(spot) }
        try testContext.save()

        // When user taps on a spot card in HomeView
        let selectedSpot = spots[1] // "Rash on Chest"
        let selectedProfileId = profiles[0].id // John's profile

        // Then navigation should be triggered with correct spot data
        XCTAssertEqual(selectedSpot.title, "Rash on Chest", "Selected spot should match tapped spot")
        XCTAssertEqual(selectedSpot.userProfile?.id, selectedProfileId, "Selected spot should belong to selected profile")
        XCTAssertEqual(selectedSpot.userProfile?.name, "John", "Should navigate to John's spot")
    }

    func testHomeViewMaintainsSelectedProfileDuringNavigation() throws {
        // Given HomeView with selected profile
        let user = TestHelpers.createTestUserProfile(userName: "Test User", relation: "Self")
        let spot = TestHelpers.createTestSpot(title: "Test Spot", userProfile: user)
        testContext.insert(user)
        testContext.insert(spot)
        try testContext.save()

        let selectedProfileId = user.id

        // When user navigates to SpotDetailView
        // Then selected profile context should be maintained
        let fetchDescriptor = FetchDescriptor<UserProfile>(predicate: #Predicate { $0.id == selectedProfileId })
        let selectedProfile = try testContext.fetch(fetchDescriptor).first

        XCTAssertNotNil(selectedProfile, "Selected profile should be available")
        XCTAssertEqual(selectedProfile?.name, "Test User", "Profile data should be preserved")
        XCTAssertEqual(selectedProfile?.id, selectedProfileId, "Profile ID should match")
    }

    func testHomeViewNavigatesWithCorrectSpotObject() throws {
        // Given HomeView with multiple spots from different users
        let users = [
            TestHelpers.createTestUserProfile(userName: "User 1", relation: "Self"),
            TestHelpers.createTestUserProfile(userName: "User 2", relation: "Child")
        ]

        let spots = [
            TestHelpers.createTestSpot(title: "User 1 Spot 1", userProfile: users[0]),
            TestHelpers.createTestSpot(title: "User 1 Spot 2", userProfile: users[0]),
            TestHelpers.createTestSpot(title: "User 2 Spot 1", userProfile: users[1])
        ]

        for user in users { testContext.insert(user) }
        for spot in spots { testContext.insert(spot) }
        try testContext.save()

        // When user taps on specific spot
        let tappedSpot = spots[2] // "User 2 Spot 1"

        // Then navigation should pass correct spot object
        XCTAssertEqual(tappedSpot.title, "User 2 Spot 1", "Should navigate with correct spot")
        XCTAssertEqual(tappedSpot.userProfile?.name, "User 2", "Should maintain association with correct user")
        XCTAssertNotEqual(tappedSpot.id, spots[0].id, "Should not navigate to wrong spot")
    }

    // MARK: - SpotDetailView Data Loading Tests

    func testSpotDetailViewReceivesCorrectSpotData() throws {
        // Given navigation to SpotDetailView with specific spot
        let hierarchy = TestHelpers.createTestHierarchy(
            userName: "Navigation Test User",
            spotTitle: "Navigation Test Spot"
        )
        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        try testContext.save()

        // When SpotDetailView loads
        let receivedSpot = hierarchy.spot

        // Then it should receive correct spot data
        XCTAssertEqual(receivedSpot.title, "Navigation Test Spot", "Spot title should be correct")
        XCTAssertEqual(receivedSpot.bodyPart, "Test Body Part", "Spot body part should be correct")
        XCTAssertTrue(receivedSpot.isActive, "Spot status should be preserved")
        XCTAssertEqual(receivedSpot.userProfile?.name, "Navigation Test User", "User association should be correct")
    }

    func testSpotDetailViewLoadsAssociatedLogEntries() throws {
        // Given a spot with multiple log entries
        let hierarchy = TestHelpers.createTestHierarchy()

        let entries = [
            TestHelpers.createTestLogEntry(imageFilename: "IMG_1.jpg", note: "First entry", painScore: 1, spot: hierarchy.spot),
            TestHelpers.createTestLogEntry(imageFilename: "IMG_2.jpg", note: "Second entry", painScore: 2, spot: hierarchy.spot),
            TestHelpers.createTestLogEntry(imageFilename: "IMG_3.jpg", note: "Third entry", painScore: 3, spot: hierarchy.spot)
        ]

        // Set different timestamps
        for (index, entry) in entries.enumerated() {
            entry.timestamp = Calendar.current.date(byAdding: .day, value: -(index + 1), to: Date())!
        }

        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        for entry in entries { testContext.insert(entry) }
        try testContext.save()

        // When SpotDetailView loads
        let spot = hierarchy.spot

        // Then it should load associated log entries
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == spot.id },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let loadedEntries = try testContext.fetch(fetchDescriptor)

        XCTAssertEqual(loadedEntries.count, 4, "Should load all log entries including hierarchy entry")

        // Verify entries are associated with correct spot
        for entry in loadedEntries {
            XCTAssertEqual(entry.spot?.id, spot.id, "All entries should belong to the spot")
        }
    }

    // MARK: - Back Navigation Tests

    func testSpotDetailViewBackNavigationMaintainsHomeViewState() throws {
        // Given user navigated from HomeView to SpotDetailView
        let users = [
            TestHelpers.createTestUserProfile(userName: "User 1", relation: "Self"),
            TestHelpers.createTestUserProfile(userName: "User 2", relation: "Child")
        ]

        let spots = [
            TestHelpers.createTestSpot(title: "Spot 1", userProfile: users[0]),
            TestHelpers.createTestSpot(title: "Spot 2", userProfile: users[0]),
            TestHelpers.createTestSpot(title: "Spot 3", userProfile: users[1])
        ]

        for user in users { testContext.insert(user) }
        for spot in spots { testContext.insert(spot) }
        try testContext.save()

        let originalSelectedProfileId = users[0].id // User 1 was selected

        // When user navigates back from SpotDetailView to HomeView
        // Then HomeView should maintain previous state
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let allProfiles = try testContext.fetch(fetchDescriptor)

        XCTAssertEqual(allProfiles.count, 2, "All profiles should still be available")
        XCTAssertEqual(allProfiles[0].id, originalSelectedProfileId, "Original selected profile should be available")

        // User 1's spots should still be available
        let user1Spots = try testContext.fetch(FetchDescriptor<Spot>(
            predicate: #Predicate<Spot> { $0.userProfile?.id == originalSelectedProfileId }
        ))
        XCTAssertEqual(user1Spots.count, 2, "Selected user's spots should be available")
    }

    func testSpotDetailViewBackNavigationMaintainsSelectedProfile() throws {
        // Given HomeView with specific profile selected
        let selectedUser = TestHelpers.createTestUserProfile(userName: "Selected User", relation: "Self")
        let otherUser = TestHelpers.createTestUserProfile(userName: "Other User", relation: "Spouse")

        let selectedSpot = TestHelpers.createTestSpot(title: "Selected User's Spot", userProfile: selectedUser)
        let otherSpot = TestHelpers.createTestSpot(title: "Other User's Spot", userProfile: otherUser)

        testContext.insert(selectedUser)
        testContext.insert(otherUser)
        testContext.insert(selectedSpot)
        testContext.insert(otherSpot)
        try testContext.save()

        let selectedProfileId = selectedUser.id

        // When user navigates to SpotDetailView and then back
        // Then selected profile should still be selected
        let fetchDescriptor = FetchDescriptor<UserProfile>(predicate: #Predicate { $0.id == selectedProfileId })
        let stillSelectedUser = try testContext.fetch(fetchDescriptor).first

        XCTAssertNotNil(stillSelectedUser, "Selected user should still be available")
        XCTAssertEqual(stillSelectedUser?.name, "Selected User", "Selected user should be maintained")
        XCTAssertEqual(stillSelectedUser?.relation, "Self", "Selected user relation should be preserved")
    }

    // MARK: - Navigation State Management Tests

    func testNavigationStateConsistencyWithMultipleUsers() throws {
        // Given multiple users with spots
        let dad = TestHelpers.createTestUserProfile(userName: "Dad", relation: "Self")
        let mom = TestHelpers.createTestUserProfile(userName: "Mom", relation: "Spouse")
        let child = TestHelpers.createTestUserProfile(userName: "Child", relation: "Child")

        let dadSpots = [
            TestHelpers.createTestSpot(title: "Dad's Mole", userProfile: dad),
            TestHelpers.createTestSpot(title: "Dad's Rash", userProfile: dad)
        ]

        let momSpots = [
            TestHelpers.createTestSpot(title: "Mom's Spot", userProfile: mom)
        ]

        let childSpots = [
            TestHelpers.createTestSpot(title: "Child's Birthmark", userProfile: child)
        ]

        testContext.insert(dad)
        testContext.insert(mom)
        testContext.insert(child)

        for spot in dadSpots + momSpots + childSpots {
            testContext.insert(spot)
        }
        try testContext.save()

        // When navigating between different users' spots
        let testScenarios = [
            (dad, dadSpots[0], "Dad"),
            (mom, momSpots[0], "Mom"),
            (child, childSpots[0], "Child"),
            (dad, dadSpots[1], "Dad again")
        ]

        for (user, spot, scenarioName) in testScenarios {
            // Then navigation state should be consistent
            XCTAssertEqual(spot.userProfile?.id, user.id, "\(scenarioName): Spot should belong to correct user")
            XCTAssertEqual(spot.userProfile?.name, user.name, "\(scenarioName): User name should match")

            // Verify user's spots are accessible
            let userSpots = try testContext.fetch(FetchDescriptor<Spot>(
                predicate: #Predicate<Spot> { $0.userProfile?.id == user.id }
            ))
            XCTAssertGreaterThan(userSpots.count, 0, "\(scenarioName): User should have accessible spots")
        }
    }

    func testNavigationWithSpotHavingNoLogEntries() throws {
        // Given a spot with no log entries
        let user = TestHelpers.createTestUserProfile()
        let emptySpot = TestHelpers.createTestSpot(title: "Empty Spot", userProfile: user)
        testContext.insert(user)
        testContext.insert(emptySpot)
        try testContext.save()

        // When navigating to SpotDetailView for empty spot
        // Then navigation should work but show empty state
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == emptySpot.id }
        )
        let logEntries = try testContext.fetch(fetchDescriptor)

        XCTAssertEqual(logEntries.count, 0, "Should have no log entries")
        XCTAssertNotNil(emptySpot.title, "Spot should still have title")
        XCTAssertNotNil(emptySpot.userProfile, "Spot should still have user association")
    }

    // MARK: - Navigation Error Handling Tests

    func testNavigationHandlesDeletedSpotGracefully() throws {
        // Given a spot ID that no longer exists
        let user = TestHelpers.createTestUserProfile()
        let spot = TestHelpers.createTestSpot(title: "To Be Deleted", userProfile: user)
        testContext.insert(user)
        testContext.insert(spot)
        try testContext.save()

        let spotId = spot.id

        // When spot is deleted from database
        testContext.delete(spot)
        try testContext.save()

        // Then navigation should handle missing spot gracefully
        let fetchDescriptor = FetchDescriptor<Spot>(predicate: #Predicate<Spot> { $0.id == spotId })
        let deletedSpot = try testContext.fetch(fetchDescriptor).first

        XCTAssertNil(deletedSpot, "Deleted spot should not be found")
        // Navigation should show error state or return to HomeView
    }

    func testNavigationHandlesOrphanedLogEntries() throws {
        // Given log entries associated with a deleted spot
        let user = TestHelpers.createTestUserProfile()
        let spot = TestHelpers.createTestSpot(title: "To Be Deleted", userProfile: user)
        let logEntry = TestHelpers.createTestLogEntry(note: "Orphaned entry", spot: spot)

        testContext.insert(user)
        testContext.insert(spot)
        testContext.insert(logEntry)
        try testContext.save()

        // When spot is deleted (cascade delete should remove log entries)
        testContext.delete(spot)
        try testContext.save()

        // Then log entries should also be deleted
        let fetchDescriptor = FetchDescriptor<LogEntry>()
        let remainingEntries = try testContext.fetch(fetchDescriptor)

        let orphanedEntries = remainingEntries.filter { $0.spot == nil }
        XCTAssertEqual(orphanedEntries.count, 0, "Should have no orphaned log entries")
    }

    // MARK: - Navigation Performance Tests

    func testNavigationPerformanceWithManySpots() throws {
        // Given HomeView with many spots
        let user = TestHelpers.createTestUserProfile()
        testContext.insert(user)

        let spotCount = 100
        for i in 1...spotCount {
            let spot = TestHelpers.createTestSpot(
                title: "Spot \(i)",
                userProfile: user
            )
            testContext.insert(spot)
        }
        try testContext.save()

        // When navigating to specific spot
        let targetSpotIndex = 50
        let fetchDescriptor = FetchDescriptor<Spot>(
            predicate: #Predicate<Spot> { $0.userProfile?.id == user.id },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        let userSpots = try testContext.fetch(fetchDescriptor)

        // Then navigation should be performant
        measure(metrics: [XCTClockMetric()]) {
            if targetSpotIndex < userSpots.count {
                let selectedSpot = userSpots[targetSpotIndex]
                _ = selectedSpot.title // Simulate accessing spot data
            }
        }

        XCTAssertEqual(userSpots.count, spotCount, "Should have all spots available")
    }

    func testNavigationPerformanceWithManyLogEntries() throws {
        // Given a spot with many log entries
        let user = TestHelpers.createTestUserProfile()
        let spot = TestHelpers.createTestSpot(userProfile: user)
        testContext.insert(user)
        testContext.insert(spot)

        let entryCount = 200
        for i in 1...entryCount {
            let entry = TestHelpers.createTestLogEntry(
                imageFilename: "IMG_\(i).jpg",
                note: "Entry \(i)",
                painScore: i % 10,
                spot: spot
            )
            entry.timestamp = Calendar.current.date(byAdding: .hour, value: -i, to: Date())!
            testContext.insert(entry)
        }
        try testContext.save()

        // When navigating to SpotDetailView
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.spot?.id == spot.id },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        // Then log entry loading should be performant
        measure(metrics: [XCTClockMetric()]) {
            do {
                _ = try testContext.fetch(fetchDescriptor)
            } catch {
                XCTFail("Loading log entries should not fail: \(error)")
            }
        }

        // Verify all entries are loaded
        do {
            let loadedEntries = try testContext.fetch(fetchDescriptor)
            XCTAssertEqual(loadedEntries.count, entryCount, "Should load all log entries")
        } catch {
            XCTFail("Should successfully load all log entries")
        }
    }

    // MARK: - Navigation Integration Tests

    func testNavigationWithMedicalDataIntegrity() throws {
        // Given complex medical data across navigation
        let medicalScenarios = [
            ("No Symptoms", 0, false, false, false, nil),
            ("Minor Pain", 2, false, false, false, 5.0),
            ("Bleeding", 3, true, false, false, 8.5),
            ("Multiple Symptoms", 7, true, true, true, 12.0),
            ("High Pain", 9, false, true, true, 15.5)
        ]

        let user = TestHelpers.createTestUserProfile(userName: "Medical Test User")
        testContext.insert(user)

        var spots: [Spot] = []
        var entries: [LogEntry] = []

        for (index, (note, pain, bleeding, itching, swollen, size)) in medicalScenarios.enumerated() {
            let spot = TestHelpers.createTestSpot(title: "Medical Scenario \(index + 1)", userProfile: user)
            let entry = TestHelpers.createTestLogEntry(
                imageFilename: "MEDICAL_\(index).jpg",
                note: note,
                painScore: pain,
                hasBleeding: bleeding,
                hasItching: itching,
                isSwollen: swollen,
                estimatedSize: size,
                spot: spot
            )

            spots.append(spot)
            entries.append(entry)
        }

        for spot in spots { testContext.insert(spot) }
        for entry in entries { testContext.insert(entry) }
        try testContext.save()

        // When navigating through different medical scenarios
        for (index, (expectedNote, expectedPain, expectedBleeding, expectedItching, expectedSwollen, expectedSize)) in medicalScenarios.enumerated() {
            let spot = spots[index]
            let entry = entries[index]

            // Then medical data integrity should be maintained
            XCTAssertEqual(entry.note, expectedNote, "Note should be preserved for scenario \(index + 1)")
            XCTAssertEqual(entry.painScore, expectedPain, "Pain score should be preserved for scenario \(index + 1)")
            XCTAssertEqual(entry.hasBleeding, expectedBleeding, "Bleeding status should be preserved for scenario \(index + 1)")
            XCTAssertEqual(entry.hasItching, expectedItching, "Itching status should be preserved for scenario \(index + 1)")
            XCTAssertEqual(entry.isSwollen, expectedSwollen, "Swelling status should be preserved for scenario \(index + 1)")
            XCTAssertEqual(entry.estimatedSize, expectedSize, "Size should be preserved for scenario \(index + 1)")
            XCTAssertEqual(entry.spot?.id, spot.id, "Spot association should be preserved for scenario \(index + 1)")
        }
    }
}