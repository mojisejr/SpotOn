//
//  TestHelpers.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import Foundation
import SwiftData
@testable import SpotOn

/// Helper class providing common test utilities for SpotOn tests
class TestHelpers {

    // MARK: - Test Data Factory Methods

    /// Creates a test UserProfile with default values
    static func createTestUserProfile(
        name: String = "Test User",
        relation: String = "Self",
        avatarColor: String = "#FF6B6B"
    ) -> UserProfile {
        UserProfile(
            id: UUID(),
            name: name,
            relation: relation,
            avatarColor: avatarColor,
            createdAt: Date()
        )
    }

    /// Creates a test Spot with default values
    static func createTestSpot(
        title: String = "Test Spot",
        bodyPart: String = "Test Body Part",
        isActive: Bool = true,
        userProfile: UserProfile
    ) -> Spot {
        Spot(
            id: UUID(),
            title: title,
            bodyPart: bodyPart,
            isActive: isActive,
            createdAt: Date(),
            userProfile: userProfile
        )
    }

    /// Creates a test LogEntry with default values
    static func createTestLogEntry(
        imageFilename: String = "TEST_IMAGE.jpg",
        note: String = "Test log entry",
        painScore: Int = 0,
        hasBleeding: Bool = false,
        hasItching: Bool = false,
        isSwollen: Bool = false,
        estimatedSize: Double? = nil,
        spot: Spot
    ) -> LogEntry {
        LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: imageFilename,
            note: note,
            painScore: painScore,
            hasBleeding: hasBleeding,
            hasItching: hasItching,
            isSwollen: isSwollen,
            estimatedSize: estimatedSize,
            spot: spot
        )
    }

    /// Creates a complete test hierarchy: User -> Spot -> LogEntry
    static func createTestHierarchy(
        userName: String = "Hierarchy Test User",
        spotTitle: String = "Hierarchy Test Spot",
        logEntryNote: String = "Hierarchy test log entry",
        painScore: Int = 2,
        hasBleeding: Bool = false,
        hasItching: Bool = true,
        isSwollen: Bool = false,
        estimatedSize: Double? = 5.5
    ) -> (user: UserProfile, spot: Spot, logEntry: LogEntry) {
        let user = createTestUserProfile(name: userName)
        let spot = createTestSpot(title: spotTitle, userProfile: user)
        let logEntry = createTestLogEntry(
            note: logEntryNote,
            painScore: painScore,
            hasBleeding: hasBleeding,
            hasItching: hasItching,
            isSwollen: isSwollen,
            estimatedSize: estimatedSize,
            spot: spot
        )

        return (user, spot, logEntry)
    }

    // MARK: - Database Setup Helpers

    /// Creates an in-memory ModelContainer for testing
    static func createTestModelContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: UserProfile.self, Spot.self, LogEntry.self, configurations: config)
    }

    /// Sets up a complete test database with sample data
    static func setupTestDatabase(in modelContext: ModelContext) throws -> (users: [UserProfile], spots: [Spot], logEntries: [LogEntry]) {
        var users: [UserProfile] = []
        var spots: [Spot] = []
        var logEntries: [LogEntry] = []

        // Create sample users
        let userProfiles = [
            ("John Doe", "Self", "#FF6B6B"),
            ("Jane Doe", "Spouse", "#4ECDC4"),
            ("Bobby Doe", "Child", "#45B7D1")
        ]

        for (name, relation, color) in userProfiles {
            let user = createTestUserProfile(name: name, relation: relation, avatarColor: color)
            users.append(user)
            modelContext.insert(user)
        }

        // Create sample spots for each user
        let sampleSpots = [
            ("Mole on Arm", "Left Arm"),
            ("Rash on Chest", "Chest"),
            ("Scar on Knee", "Right Knee"),
            ("Birthmark on Back", "Upper Back")
        ]

        for (userIndex, user) in users.enumerated() {
            for (spotIndex, (title, bodyPart)) in sampleSpots.enumerated() {
                if userIndex == 0 && spotIndex < 2 { // John gets 2 spots
                    let spot = createTestSpot(
                        title: "\(title) - \(user.name)",
                        bodyPart: bodyPart,
                        isActive: spotIndex % 2 == 0,
                        userProfile: user
                    )
                    spots.append(spot)
                    modelContext.insert(spot)

                    // Create log entries for each spot
                    let sampleEntries = [
                        ("Initial observation", 1, false, false, false, 3.0),
                        ("Slight redness noticed", 2, false, true, false, 3.5),
                        ("Applied cream", 1, false, true, false, 3.2),
                        ("Condition improving", 0, false, false, false, 2.8)
                    ]

                    for (entryIndex, (note, pain, bleeding, itching, swollen, size)) in sampleEntries.enumerated() {
                        let logEntry = createTestLogEntry(
                            imageFilename: "IMG_\(userIndex)_\(spotIndex)_\(entryIndex).jpg",
                            note: note,
                            painScore: pain,
                            hasBleeding: bleeding,
                            hasItching: itching,
                            isSwollen: swollen,
                            estimatedSize: size,
                            spot: spot
                        )
                        logEntries.append(logEntry)
                        modelContext.insert(logEntry)
                    }
                } else if userIndex == 1 && spotIndex == 0 { // Jane gets 1 spot
                    let spot = createTestSpot(
                        title: "\(title) - \(user.name)",
                        bodyPart: bodyPart,
                        isActive: true,
                        userProfile: user
                    )
                    spots.append(spot)
                    modelContext.insert(spot)

                    let logEntry = createTestLogEntry(
                        note: "Jane's initial log entry",
                        painScore: 3,
                        hasBleeding: true,
                        hasItching: false,
                        isSwollen: true,
                        estimatedSize: 7.0,
                        spot: spot
                    )
                    logEntries.append(logEntry)
                    modelContext.insert(logEntry)
                }
            }
        }

        try modelContext.save()
        return (users, spots, logEntries)
    }

    // MARK: - Assertion Helpers

    /// Asserts that two UserProfile objects are equal (excluding timestamp for testing)
    static func assertUserProfileEqual(_ user1: UserProfile, _ user2: UserProfile, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(user1.id, user2.id, "User IDs should match", file: file, line: line)
        XCTAssertEqual(user1.name, user2.name, "User names should match", file: file, line: line)
        XCTAssertEqual(user1.relation, user2.relation, "User relations should match", file: file, line: line)
        XCTAssertEqual(user1.avatarColor, user2.avatarColor, "User avatar colors should match", file: file, line: line)
        // Note: We don't compare createdAt as it may vary by milliseconds in tests
    }

    /// Asserts that two Spot objects are equal (excluding timestamp for testing)
    static func assertSpotEqual(_ spot1: Spot, _ spot2: Spot, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(spot1.id, spot2.id, "Spot IDs should match", file: file, line: line)
        XCTAssertEqual(spot1.title, spot2.title, "Spot titles should match", file: file, line: line)
        XCTAssertEqual(spot1.bodyPart, spot2.bodyPart, "Spot body parts should match", file: file, line: line)
        XCTAssertEqual(spot1.isActive, spot2.isActive, "Spot active status should match", file: file, line: line)
        XCTAssertEqual(spot1.userProfile?.id, spot2.userProfile?.id, "Spot user profiles should match", file: file, line: line)
        // Note: We don't compare createdAt as it may vary by milliseconds in tests
    }

    /// Asserts that two LogEntry objects are equal (excluding timestamp for testing)
    static func assertLogEntryEqual(_ entry1: LogEntry, _ entry2: LogEntry, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(entry1.id, entry2.id, "Log entry IDs should match", file: file, line: line)
        XCTAssertEqual(entry1.imageFilename, entry2.imageFilename, "Log entry filenames should match", file: file, line: line)
        XCTAssertEqual(entry1.note, entry2.note, "Log entry notes should match", file: file, line: line)
        XCTAssertEqual(entry1.painScore, entry2.painScore, "Log entry pain scores should match", file: file, line: line)
        XCTAssertEqual(entry1.hasBleeding, entry2.hasBleeding, "Log entry bleeding status should match", file: file, line: line)
        XCTAssertEqual(entry1.hasItching, entry2.hasItching, "Log entry itching status should match", file: file, line: line)
        XCTAssertEqual(entry1.isSwollen, entry2.isSwollen, "Log entry swelling status should match", file: file, line: line)
        XCTAssertEqual(entry1.estimatedSize, entry2.estimatedSize, "Log entry estimated sizes should match", file: file, line: line)
        XCTAssertEqual(entry1.spot?.id, entry2.spot?.id, "Log entry spots should match", file: file, line: line)
        // Note: We don't compare timestamp as it may vary by milliseconds in tests
    }

    // MARK: - Test Data Generators

    /// Generates random valid avatar colors
    static func randomAvatarColor() -> String {
        let colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F"]
        return colors.randomElement()!
    }

    /// Generates random valid body parts
    static func randomBodyPart() -> String {
        let parts = ["Head", "Face", "Neck", "Chest", "Back", "Abdomen", "Left Arm", "Right Arm", "Left Leg", "Right Leg"]
        return parts.randomElement()!
    }

    /// Generates random valid relations
    static func randomRelation() -> String {
        let relations = ["Self", "Father", "Mother", "Child", "Spouse", "Other"]
        return relations.randomElement()!
    }

    /// Generates random medical note text
    static func randomMedicalNote() -> String {
        let notes = [
            "Looking normal today",
            "Slight redness observed",
            "No changes from previous entry",
            "Applied medicated cream",
            "Doctor visit scheduled",
            "Condition seems to be improving",
            "Monitoring for changes",
            "Follow up needed"
        ]
        return notes.randomElement()!
    }

    /// Generates random image filename
    static func randomImageFilename() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        return "IMG_\(timestamp)_\(Int.random(in: 1000...9999)).jpg"
    }

    // MARK: - Cleanup Helpers

    /// Cleans up all data from a ModelContext
    static func cleanupAllData(in modelContext: ModelContext) throws {
        // Delete in reverse order to respect relationships
        let logEntries = try modelContext.fetch(FetchDescriptor<LogEntry>())
        for entry in logEntries {
            modelContext.delete(entry)
        }

        let spots = try modelContext.fetch(FetchDescriptor<Spot>())
        for spot in spots {
            modelContext.delete(spot)
        }

        let users = try modelContext.fetch(FetchDescriptor<UserProfile>())
        for user in users {
            modelContext.delete(user)
        }

        try modelContext.save()
    }

    /// Counts objects in the database for verification
    static func countObjects(in modelContext: ModelContext) throws -> (users: Int, spots: Int, logEntries: Int) {
        let userCount = try modelContext.fetch(FetchDescriptor<UserProfile>()).count
        let spotCount = try modelContext.fetch(FetchDescriptor<Spot>()).count
        let logEntryCount = try modelContext.fetch(FetchDescriptor<LogEntry>()).count

        return (userCount, spotCount, logEntryCount)
    }
}