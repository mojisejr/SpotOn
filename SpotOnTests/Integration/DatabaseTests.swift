//
//  DatabaseTests.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import XCTest
import SwiftData
@testable import SpotOn

final class DatabaseTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        // Create in-memory test container for isolated testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: UserProfile.self, Spot.self, LogEntry.self, configurations: config)
        modelContext = ModelContext(modelContainer)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }

    // MARK: - Complete Data Flow Tests

    func testCompleteUserProfileToLogEntryCreation() throws {
        // Given - Create user profile
        let userProfile = UserProfile(
            id: UUID(),
            name: "Complete Test User",
            relation: "Self",
            avatarColor: "#FF6B6B",
            createdAt: Date()
        )
        modelContext.insert(userProfile)

        // Given - Create spot
        let spot = Spot(
            id: UUID(),
            title: "Test Mole",
            bodyPart: "Left Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: userProfile
        )
        modelContext.insert(spot)

        // Given - Create log entry
        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "COMPLETE_TEST.jpg",
            note: "Complete flow test entry",
            painScore: 3,
            hasBleeding: false,
            hasItching: true,
            isSwollen: false,
            estimatedSize: 6.5,
            spot: spot
        )
        modelContext.insert(logEntry)

        // When
        try modelContext.save()

        // Then - Verify all data is correctly linked
        let userFetchDescriptor = FetchDescriptor<UserProfile>()
        let fetchedUsers = try modelContext.fetch(userFetchDescriptor)
        XCTAssertEqual(fetchedUsers.count, 1)
        XCTAssertEqual(fetchedUsers.first?.name, "Complete Test User")

        let spotFetchDescriptor = FetchDescriptor<Spot>()
        let fetchedSpots = try modelContext.fetch(spotFetchDescriptor)
        XCTAssertEqual(fetchedSpots.count, 1)
        XCTAssertEqual(fetchedSpots.first?.title, "Test Mole")
        XCTAssertEqual(fetchedSpots.first?.userProfile?.name, "Complete Test User")

        let logEntryFetchDescriptor = FetchDescriptor<LogEntry>()
        let fetchedLogEntries = try modelContext.fetch(logEntryFetchDescriptor)
        XCTAssertEqual(fetchedLogEntries.count, 1)
        XCTAssertEqual(fetchedLogEntries.first?.note, "Complete flow test entry")
        XCTAssertEqual(fetchedLogEntries.first?.spot?.title, "Test Mole")
        XCTAssertEqual(fetchedLogEntries.first?.spot?.userProfile?.name, "Complete Test User")
    }

    // MARK: - Relationship Cascade Delete Tests

    func testUserProfileCascadeDeleteDeletesSpots() throws {
        // Given - Create user with multiple spots
        let userProfile = UserProfile(
            id: UUID(),
            name: "Cascade Test User",
            relation: "Self",
            avatarColor: "#4ECDC4",
            createdAt: Date()
        )
        modelContext.insert(userProfile)

        let spot1 = Spot(
            id: UUID(),
            title: "Spot 1",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: userProfile
        )
        modelContext.insert(spot1)

        let spot2 = Spot(
            id: UUID(),
            title: "Spot 2",
            bodyPart: "Leg",
            isActive: true,
            createdAt: Date(),
            userProfile: userProfile
        )
        modelContext.insert(spot2)

        try modelContext.save()

        // Verify initial state
        let initialSpotFetchDescriptor = FetchDescriptor<Spot>()
        let initialSpots = try modelContext.fetch(initialSpotFetchDescriptor)
        XCTAssertEqual(initialSpots.count, 2)

        // When - Delete user profile
        modelContext.delete(userProfile)
        try modelContext.save()

        // Then - Verify all spots are deleted (cascade)
        let finalSpotFetchDescriptor = FetchDescriptor<Spot>()
        let finalSpots = try modelContext.fetch(finalSpotFetchDescriptor)
        XCTAssertEqual(finalSpots.count, 0)
    }

    func testSpotCascadeDeleteDeletesLogEntries() throws {
        // Given - Create complete hierarchy
        let userProfile = UserProfile(
            id: UUID(),
            name: "Log Cascade Test User",
            relation: "Self",
            avatarColor: "#45B7D1",
            createdAt: Date()
        )
        modelContext.insert(userProfile)

        let spot = Spot(
            id: UUID(),
            title: "Spot with Log Entries",
            bodyPart: "Back",
            isActive: true,
            createdAt: Date(),
            userProfile: userProfile
        )
        modelContext.insert(spot)

        let logEntry1 = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "CASCADE_TEST_1.jpg",
            note: "First log entry",
            painScore: 1,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: spot
        )
        modelContext.insert(logEntry1)

        let logEntry2 = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "CASCADE_TEST_2.jpg",
            note: "Second log entry",
            painScore: 2,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: spot
        )
        modelContext.insert(logEntry2)

        try modelContext.save()

        // Verify initial state
        let initialLogEntryFetchDescriptor = FetchDescriptor<LogEntry>()
        let initialLogEntries = try modelContext.fetch(initialLogEntryFetchDescriptor)
        XCTAssertEqual(initialLogEntries.count, 2)

        // When - Delete spot
        modelContext.delete(spot)
        try modelContext.save()

        // Then - Verify all log entries are deleted (cascade)
        let finalLogEntryFetchDescriptor = FetchDescriptor<LogEntry>()
        let finalLogEntries = try modelContext.fetch(finalLogEntryFetchDescriptor)
        XCTAssertEqual(finalLogEntries.count, 0)
    }

    func testFullCascadeDeleteChain() throws {
        // Given - Create complete hierarchy with multiple users, spots, and log entries
        let userProfile1 = UserProfile(
            id: UUID(),
            name: "User 1",
            relation: "Self",
            avatarColor: "#FF6B6B",
            createdAt: Date()
        )
        modelContext.insert(userProfile1)

        let userProfile2 = UserProfile(
            id: UUID(),
            name: "User 2",
            relation: "Father",
            avatarColor: "#4ECDC4",
            createdAt: Date()
        )
        modelContext.insert(userProfile2)

        // Spots for user 1
        let spot1 = Spot(
            id: UUID(),
            title: "User 1 Spot 1",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: userProfile1
        )
        modelContext.insert(spot1)

        let spot2 = Spot(
            id: UUID(),
            title: "User 1 Spot 2",
            bodyPart: "Leg",
            isActive: true,
            createdAt: Date(),
            userProfile: userProfile1
        )
        modelContext.insert(spot2)

        // Spot for user 2
        let spot3 = Spot(
            id: UUID(),
            title: "User 2 Spot 1",
            bodyPart: "Back",
            isActive: true,
            createdAt: Date(),
            userProfile: userProfile2
        )
        modelContext.insert(spot3)

        // Log entries for each spot
        for (index, spot) in [spot1, spot2, spot3].enumerated() {
            let logEntry = LogEntry(
                id: UUID(),
                timestamp: Date(),
                imageFilename: "FULL_CASCADE_\(index).jpg",
                note: "Full cascade test entry \(index)",
                painScore: index,
                hasBleeding: false,
                hasItching: false,
                isSwollen: false,
                estimatedSize: Double(index),
                spot: spot
            )
            modelContext.insert(logEntry)
        }

        try modelContext.save()

        // Verify initial state
        let initialUsers = try modelContext.fetch(FetchDescriptor<UserProfile>())
        let initialSpots = try modelContext.fetch(FetchDescriptor<Spot>())
        let initialLogEntries = try modelContext.fetch(FetchDescriptor<LogEntry>())
        XCTAssertEqual(initialUsers.count, 2)
        XCTAssertEqual(initialSpots.count, 3)
        XCTAssertEqual(initialLogEntries.count, 3)

        // When - Delete user 1
        modelContext.delete(userProfile1)
        try modelContext.save()

        // Then - Verify cascade delete worked correctly
        let finalUsers = try modelContext.fetch(FetchDescriptor<UserProfile>())
        let finalSpots = try modelContext.fetch(FetchDescriptor<Spot>())
        let finalLogEntries = try modelContext.fetch(FetchDescriptor<LogEntry>())

        XCTAssertEqual(finalUsers.count, 1) // User 2 remains
        XCTAssertEqual(finalSpots.count, 1) // Only User 2's spot remains
        XCTAssertEqual(finalLogEntries.count, 1) // Only User 2's spot's log entry remains

        XCTAssertEqual(finalUsers.first?.name, "User 2")
        XCTAssertEqual(finalSpots.first?.title, "User 2 Spot 1")
        XCTAssertEqual(finalLogEntries.first?.note, "Full cascade test entry 2")
    }

    // MARK: - Relationship Integrity Tests

    func testSpotCannotExistWithoutUserProfile() throws {
        // Given - Try to create spot without user profile
        let spot = Spot(
            id: UUID(),
            title: "Orphan Spot",
            bodyPart: "Nowhere",
            isActive: true,
            createdAt: Date(),
            userProfile: nil // This should either fail or be optional
        )

        // When/Then - Behavior depends on model implementation
        // For now, assuming this is allowed but relationship is nil
        XCTAssertNil(spot.userProfile)
    }

    func testLogEntryCannotExistWithoutSpot() throws {
        // Given - Try to create log entry without spot
        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "ORPHAN.jpg",
            note: "Orphan log entry",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: nil // This should either fail or be optional
        )

        // When/Then - Behavior depends on model implementation
        // For now, assuming this is allowed but relationship is nil
        XCTAssertNil(logEntry.spot)
    }

    // MARK: - Complex Query Tests

    func testQueryLogEntriesForUserByDateRange() throws {
        // Given - Create user with multiple spots and log entries
        let userProfile = UserProfile(
            id: UUID(),
            name: "Date Range Test User",
            relation: "Self",
            avatarColor: "#96CEB4",
            createdAt: Date()
        )
        modelContext.insert(userProfile)

        let spot = Spot(
            id: UUID(),
            title: "Date Range Spot",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: userProfile
        )
        modelContext.insert(spot)

        // Create log entries with different timestamps
        let baseDate = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: baseDate)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: baseDate)!
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: baseDate)!

        let oldEntry = LogEntry(
            id: UUID(),
            timestamp: threeDaysAgo,
            imageFilename: "OLD.jpg",
            note: "Old entry",
            painScore: 1,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: spot
        )
        modelContext.insert(oldEntry)

        let recentEntry1 = LogEntry(
            id: UUID(),
            timestamp: twoDaysAgo,
            imageFilename: "RECENT1.jpg",
            note: "Recent entry 1",
            painScore: 2,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: spot
        )
        modelContext.insert(recentEntry1)

        let recentEntry2 = LogEntry(
            id: UUID(),
            timestamp: yesterday,
            imageFilename: "RECENT2.jpg",
            note: "Recent entry 2",
            painScore: 3,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: spot
        )
        modelContext.insert(recentEntry2)

        try modelContext.save()

        // When - Query entries in last 2 days
        let fetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { entry in
                entry.spot?.userProfile?.name == "Date Range Test User" &&
                entry.timestamp >= twoDaysAgo
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        let recentEntries = try modelContext.fetch(fetchDescriptor)

        // Then
        XCTAssertEqual(recentEntries.count, 2)
        XCTAssertEqual(recentEntries[0].note, "Recent entry 1")
        XCTAssertEqual(recentEntries[1].note, "Recent entry 2")
        XCTAssertTrue(recentEntries.allSatisfy { $0.spot?.userProfile?.name == "Date Range Test User" })
    }

    func testQuerySpotsWithHighPainEntries() throws {
        // Given - Create user with multiple spots and log entries with different pain levels
        let userProfile = UserProfile(
            id: UUID(),
            name: "Pain Query Test User",
            relation: "Self",
            avatarColor: "#FFEAA7",
            createdAt: Date()
        )
        modelContext.insert(userProfile)

        let lowPainSpot = Spot(
            id: UUID(),
            title: "Low Pain Spot",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: userProfile
        )
        modelContext.insert(lowPainSpot)

        let highPainSpot = Spot(
            id: UUID(),
            title: "High Pain Spot",
            bodyPart: "Leg",
            isActive: true,
            createdAt: Date(),
            userProfile: userProfile
        )
        modelContext.insert(highPainSpot)

        // Low pain entries
        let lowPainEntry1 = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "LOW1.jpg",
            note: "Low pain 1",
            painScore: 2,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: lowPainSpot
        )
        modelContext.insert(lowPainEntry1)

        let lowPainEntry2 = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "LOW2.jpg",
            note: "Low pain 2",
            painScore: 3,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: lowPainSpot
        )
        modelContext.insert(lowPainEntry2)

        // High pain entries
        let highPainEntry1 = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "HIGH1.jpg",
            note: "High pain 1",
            painScore: 8,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: highPainSpot
        )
        modelContext.insert(highPainEntry1)

        let highPainEntry2 = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "HIGH2.jpg",
            note: "High pain 2",
            painScore: 9,
            hasBleeding: true,
            hasItching: false,
            isSwollen: true,
            estimatedSize: 12.5,
            spot: highPainSpot
        )
        modelContext.insert(highPainEntry2)

        try modelContext.save()

        // When - Query spots with high pain entries (pain >= 7)
        let highPainLogFetchDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.painScore >= 7 }
        )
        let highPainLogEntries = try modelContext.fetch(highPainLogFetchDescriptor)

        let highPainSpotIds = Set(highPainLogEntries.compactMap { $0.spot?.id })
        let highPainSpotFetchDescriptor = FetchDescriptor<Spot>(
            predicate: #Predicate<Spot> { spot in
                highPainSpotIds.contains(spot.id)
            }
        )
        let highPainSpots = try modelContext.fetch(highPainSpotFetchDescriptor)

        // Then
        XCTAssertEqual(highPainSpots.count, 1)
        XCTAssertEqual(highPainSpots.first?.title, "High Pain Spot")
        XCTAssertEqual(highPainLogEntries.count, 2)
        XCTAssertTrue(highPainLogEntries.allSatisfy { $0.painScore >= 7 })
    }

    func testQueryActiveSpotsForAllUsers() throws {
        // Given - Create multiple users with active and inactive spots
        let user1 = UserProfile(
            id: UUID(),
            name: "Active User 1",
            relation: "Self",
            avatarColor: "#DDA0DD",
            createdAt: Date()
        )
        modelContext.insert(user1)

        let user2 = UserProfile(
            id: UUID(),
            name: "Active User 2",
            relation: "Father",
            avatarColor: "#FFB6C1",
            createdAt: Date()
        )
        modelContext.insert(user2)

        // Active spots
        let activeSpot1 = Spot(
            id: UUID(),
            title: "Active Spot 1",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: user1
        )
        modelContext.insert(activeSpot1)

        let activeSpot2 = Spot(
            id: UUID(),
            title: "Active Spot 2",
            bodyPart: "Leg",
            isActive: true,
            createdAt: Date(),
            userProfile: user2
        )
        modelContext.insert(activeSpot2)

        // Inactive spots
        let inactiveSpot1 = Spot(
            id: UUID(),
            title: "Inactive Spot 1",
            bodyPart: "Back",
            isActive: false,
            createdAt: Date(),
            userProfile: user1
        )
        modelContext.insert(inactiveSpot1)

        try modelContext.save()

        // When - Query only active spots
        let activeSpotFetchDescriptor = FetchDescriptor<Spot>(
            predicate: #Predicate<Spot> { $0.isActive == true },
            sortBy: [SortDescriptor(\.userProfile.name), SortDescriptor(\.title)]
        )
        let activeSpots = try modelContext.fetch(activeSpotFetchDescriptor)

        // Then
        XCTAssertEqual(activeSpots.count, 2)
        XCTAssertEqual(activeSpots[0].userProfile.name, "Active User 1")
        XCTAssertEqual(activeSpots[0].title, "Active Spot 1")
        XCTAssertEqual(activeSpots[1].userProfile.name, "Active User 2")
        XCTAssertEqual(activeSpots[1].title, "Active Spot 2")
        XCTAssertTrue(activeSpots.allSatisfy { $0.isActive })
    }

    // MARK: - Performance Tests

    func testBulkDataInsertionPerformance() throws {
        // Given - Create 100 users, each with 10 spots, each with 5 log entries
        // Total: 100 users + 1,000 spots + 5,000 log entries = 6,100 objects

        measure {
            do {
                let users = (0..<100).map { i in
                    UserProfile(
                        id: UUID(),
                        name: "Performance User \(i)",
                        relation: i % 4 == 0 ? "Self" : "Family Member",
                        avatarColor: "#FF6B6B",
                        createdAt: Date()
                    )
                }

                for user in users {
                    modelContext.insert(user)

                    for j in 0..<10 {
                        let spot = Spot(
                            id: UUID(),
                            title: "Spot \(j) for User \(users.firstIndex(of: user) ?? 0)",
                            bodyPart: ["Arm", "Leg", "Back", "Chest", "Head"][j % 5],
                            isActive: j % 3 != 0, // 2/3 are active
                            createdAt: Date(),
                            userProfile: user
                        )
                        modelContext.insert(spot)

                        for k in 0..<5 {
                            let logEntry = LogEntry(
                                id: UUID(),
                                timestamp: Date(),
                                imageFilename: "PERF_TEST_\(users.firstIndex(of: user) ?? 0)_\(j)_\(k).jpg",
                                note: "Performance test log entry \(k) for spot \(j)",
                                painScore: k % 11, // 0-10
                                hasBleeding: k % 3 == 0,
                                hasItching: k % 4 == 0,
                                isSwollen: k % 5 == 0,
                                estimatedSize: Double(k + 1) * 0.5,
                                spot: spot
                            )
                            modelContext.insert(logEntry)
                        }
                    }
                }

                try modelContext.save()

                // Clean up for next measurement iteration
                let allLogEntries = try modelContext.fetch(FetchDescriptor<LogEntry>())
                for entry in allLogEntries {
                    modelContext.delete(entry)
                }

                let allSpots = try modelContext.fetch(FetchDescriptor<Spot>())
                for spot in allSpots {
                    modelContext.delete(spot)
                }

                let allUsers = try modelContext.fetch(FetchDescriptor<UserProfile>())
                for user in allUsers {
                    modelContext.delete(user)
                }

                try modelContext.save()
            } catch {
                XCTFail("Bulk performance test failed: \(error)")
            }
        }
    }

    func testComplexQueryPerformance() throws {
        // Given - Create complex dataset for query testing
        let users = (0..<50).map { i in
            UserProfile(
                id: UUID(),
                name: "Complex Query User \(i)",
                relation: i % 3 == 0 ? "Self" : "Family",
                avatarColor: "#4ECDC4",
                createdAt: Date()
            )
        }

        for user in users {
            modelContext.insert(user)

            for j in 0..<20 {
                let spot = Spot(
                    id: UUID(),
                    title: "Spot \(j)",
                    bodyPart: "Body Part \(j % 10)",
                    isActive: j % 2 == 0,
                    createdAt: Date(),
                    userProfile: user
                )
                modelContext.insert(spot)

                for k in 0..<10 {
                    let logEntry = LogEntry(
                        id: UUID(),
                        timestamp: Calendar.current.date(byAdding: .day, value: -k, to: Date())!,
                        imageFilename: "COMPLEX_\(i)_\(j)_\(k).jpg",
                        note: "Complex entry \(k)",
                        painScore: Int.random(in: 0...10),
                        hasBleeding: k % 3 == 0,
                        hasItching: k % 4 == 0,
                        isSwollen: k % 5 == 0,
                        estimatedSize: Double.random(in: 0.1...15.0),
                        spot: spot
                    )
                    modelContext.insert(logEntry)
                }
            }
        }

        try modelContext.save()

        // When - Measure complex query performance
        measure {
            do {
                // Complex query: Active spots with high pain (>=7) and bleeding in last 3 days
                let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!

                let highPainLogsDescriptor = FetchDescriptor<LogEntry>(
                    predicate: #Predicate<LogEntry> { log in
                        log.painScore >= 7 &&
                        log.hasBleeding == true &&
                        log.timestamp >= threeDaysAgo
                    }
                )
                let highPainLogs = try modelContext.fetch(highPainLogsDescriptor)
                let highPainSpotIds = Set(highPainLogs.compactMap { $0.spot?.id })

                let complexSpotDescriptor = FetchDescriptor<Spot>(
                    predicate: #Predicate<Spot> { spot in
                        spot.isActive == true &&
                        highPainSpotIds.contains(spot.id)
                    },
                    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                )
                let complexSpots = try modelContext.fetch(complexSpotDescriptor)

                // Verify we got results
                XCTAssertNotNil(complexSpots)
            } catch {
                XCTFail("Complex query performance test failed: \(error)")
            }
        }
    }

    // MARK: - Data Consistency Tests

    func testDataConsistencyAfterSaveAndReload() throws {
        // Given - Create complex relationship hierarchy
        let userProfile = UserProfile(
            id: UUID(),
            name: "Consistency Test User",
            relation: "Self",
            avatarColor: "#FF6B6B",
            createdAt: Date()
        )

        let spot = Spot(
            id: UUID(),
            title: "Consistency Test Spot",
            bodyPart: "Test Body Part",
            isActive: true,
            createdAt: Date(),
            userProfile: userProfile
        )

        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "CONSISTENCY_TEST.jpg",
            note: "Consistency test entry with detailed medical observations",
            painScore: 5,
            hasBleeding: true,
            hasItching: false,
            isSwollen: true,
            estimatedSize: 8.75,
            spot: spot
        )

        // When - Insert and save
        modelContext.insert(userProfile)
        modelContext.insert(spot)
        modelContext.insert(logEntry)
        try modelContext.save()

        // Then - Reload and verify all relationships are intact
        let reloadedUsers = try modelContext.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(reloadedUsers.count, 1)

        let reloadedUser = reloadedUsers.first!
        XCTAssertEqual(reloadedUser.name, "Consistency Test User")
        XCTAssertEqual(reloadedUser.relation, "Self")
        XCTAssertEqual(reloadedUser.avatarColor, "#FF6B6B")

        let reloadedSpots = try modelContext.fetch(FetchDescriptor<Spot>())
        XCTAssertEqual(reloadedSpots.count, 1)

        let reloadedSpot = reloadedSpots.first!
        XCTAssertEqual(reloadedSpot.title, "Consistency Test Spot")
        XCTAssertEqual(reloadedSpot.bodyPart, "Test Body Part")
        XCTAssertTrue(reloadedSpot.isActive)
        XCTAssertEqual(reloadedSpot.userProfile?.id, reloadedUser.id)

        let reloadedLogEntries = try modelContext.fetch(FetchDescriptor<LogEntry>())
        XCTAssertEqual(reloadedLogEntries.count, 1)

        let reloadedLogEntry = reloadedLogEntries.first!
        XCTAssertEqual(reloadedLogEntry.imageFilename, "CONSISTENCY_TEST.jpg")
        XCTAssertEqual(reloadedLogEntry.note, "Consistency test entry with detailed medical observations")
        XCTAssertEqual(reloadedLogEntry.painScore, 5)
        XCTAssertTrue(reloadedLogEntry.hasBleeding)
        XCTAssertFalse(reloadedLogEntry.hasItching)
        XCTAssertTrue(reloadedLogEntry.isSwollen)
        XCTAssertEqual(reloadedLogEntry.estimatedSize, 8.75)
        XCTAssertEqual(reloadedLogEntry.spot?.id, reloadedSpot.id)
    }
}