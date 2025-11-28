//
//  SwiftDataTestHelpers.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import Foundation
import SwiftData
@testable import SpotOn

/// Comprehensive SwiftData testing utilities for in-memory database isolation
class SwiftDataTestHelpers {

    // MARK: - Test Container Setup

    /// Creates a fully isolated in-memory ModelContainer for testing
    /// - Returns: A ModelContainer configured for in-memory storage
    /// - Throws: ModelContainer creation errors
    static func createInMemoryContainer() throws -> ModelContainer {
        let config = ModelConfiguration(
            isStoredInMemoryOnly: true,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(
                for: UserProfile.self,
                Spot.self,
                LogEntry.self,
                configurations: config
            )
            return container
        } catch {
            throw TestError.containerCreationFailed(error)
        }
    }

    /// Creates a test container with predefined data for integration testing
    /// - Parameter fixtureType: Type of test data to populate
    /// - Returns: Tuple containing container and context with test data
    /// - Throws: Setup errors
    static func createContainerWithFixtures(
        fixtureType: FixtureType = .sampleData
    ) throws -> (container: ModelContainer, context: ModelContext) {
        let container = try createInMemoryContainer()
        let context = ModelContext(container)

        switch fixtureType {
        case .empty:
            // No data - clean slate
            break
        case .sampleData:
            try populateSampleData(in: context)
        case .minimalData:
            try populateMinimalData(in: context)
        case .medicalScenarios:
            try populateMedicalScenarios(in: context)
        case .edgeCases:
            try populateEdgeCases(in: context)
        }

        try context.save()
        return (container, context)
    }

    // MARK: - Data Population Methods

    /// Populates context with comprehensive sample data
    private static func populateSampleData(in context: ModelContext) throws {
        // Create users
        let users = [
            UserProfile(id: UUID(), name: "John Doe", relation: "Self", avatarColor: "#FF6B6B", createdAt: Date()),
            UserProfile(id: UUID(), name: "Jane Doe", relation: "Spouse", avatarColor: "#4ECDC4", createdAt: Date()),
            UserProfile(id: UUID(), name: "Bobby Doe", relation: "Child", avatarColor: "#45B7D1", createdAt: Date())
        ]

        for user in users {
            context.insert(user)
        }

        // Create spots for each user
        let spotData = [
            (userIndex: 0, title: "Mole on Arm", bodyPart: "Left Arm", isActive: true),
            (userIndex: 0, title: "Rash on Chest", bodyPart: "Chest", isActive: true),
            (userIndex: 1, title: "Scar on Knee", bodyPart: "Right Knee", isActive: false),
            (userIndex: 2, title: "Birthmark on Back", bodyPart: "Upper Back", isActive: true)
        ]

        var spots: [Spot] = []
        for spotInfo in spotData {
            let spot = Spot(
                id: UUID(),
                title: spotInfo.title,
                bodyPart: spotInfo.bodyPart,
                isActive: spotInfo.isActive,
                createdAt: Date(),
                userProfile: users[spotInfo.userIndex]
            )
            spots.append(spot)
            context.insert(spot)
        }

        // Create log entries for spots
        let logEntryData = [
            (spotIndex: 0, note: "Initial observation", painScore: 0, hasBleeding: false, hasItching: false, isSwollen: false),
            (spotIndex: 0, note: "Slight redness", painScore: 2, hasBleeding: false, hasItching: true, isSwollen: false),
            (spotIndex: 1, note: "Rash developing", painScore: 3, hasBleeding: false, hasItching: true, isSwollen: true),
            (spotIndex: 2, note: "Scar healing well", painScore: 1, hasBleeding: false, hasItching: false, isSwollen: false),
            (spotIndex: 3, note: "Birthmark stable", painScore: 0, hasBleeding: false, hasItching: false, isSwollen: false)
        ]

        for entryInfo in logEntryData {
            let logEntry = LogEntry(
                id: UUID(),
                timestamp: Date(),
                imageFilename: "IMG_\(UUID().uuidString).jpg",
                note: entryInfo.note,
                painScore: entryInfo.painScore,
                hasBleeding: entryInfo.hasBleeding,
                hasItching: entryInfo.hasItching,
                isSwollen: entryInfo.isSwollen,
                estimatedSize: Double.random(in: 2.0...10.0),
                spot: spots[entryInfo.spotIndex]
            )
            context.insert(logEntry)
        }
    }

    /// Populates context with minimal test data (one user, one spot, one entry)
    private static func populateMinimalData(in context: ModelContext) throws {
        let user = UserProfile(
            id: UUID(),
            name: "Test User",
            relation: "Self",
            avatarColor: "#FF6B6B",
            createdAt: Date()
        )
        context.insert(user)

        let spot = Spot(
            id: UUID(),
            title: "Test Spot",
            bodyPart: "Test Body Part",
            isActive: true,
            createdAt: Date(),
            userProfile: user
        )
        context.insert(spot)

        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "test.jpg",
            note: "Test log entry",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: spot
        )
        context.insert(logEntry)
    }

    /// Populates context with various medical scenarios for testing
    private static func populateMedicalScenarios(in context: ModelContext) throws {
        let user = UserProfile(
            id: UUID(),
            name: "Medical Test User",
            relation: "Self",
            avatarColor: "#FF6B6B",
            createdAt: Date()
        )
        context.insert(user)

        // Create spots with different medical conditions
        let medicalSpots = [
            ("Normal Mole", "Left Arm", true),
            ("Irritated Rash", "Chest", true),
            ("Bleeding Wound", "Right Hand", true),
            ("Swollen Area", "Left Leg", true),
            ("Chronic Condition", "Back", true)
        ]

        var spots: [Spot] = []
        for (title, bodyPart, isActive) in medicalSpots {
            let spot = Spot(
                id: UUID(),
                title: title,
                bodyPart: bodyPart,
                isActive: isActive,
                createdAt: Date(),
                userProfile: user
            )
            spots.append(spot)
            context.insert(spot)
        }

        // Create log entries with various symptoms
        let medicalEntries: [(spotIndex: Int, note: String, pain: Int, bleeding: Bool, itching: Bool, swollen: Bool, size: Double?)] = [
            (0, "Normal appearance", 0, false, false, false, 5.0),
            (1, "Red and itchy", 3, false, true, false, 8.5),
            (2, "Minor bleeding", 6, true, false, true, 12.0),
            (3, "Swollen but not painful", 1, false, false, true, 15.0),
            (4, "Chronic inflammation", 4, false, true, true, 20.0)
        ]

        for entryInfo in medicalEntries {
            let logEntry = LogEntry(
                id: UUID(),
                timestamp: Date(),
                imageFilename: "MEDICAL_\(UUID().uuidString).jpg",
                note: entryInfo.note,
                painScore: entryInfo.pain,
                hasBleeding: entryInfo.bleeding,
                hasItching: entryInfo.itching,
                isSwollen: entryInfo.swollen,
                estimatedSize: entryInfo.size,
                spot: spots[entryInfo.spotIndex]
            )
            context.insert(logEntry)
        }
    }

    /// Populates context with edge cases for testing
    private static func populateEdgeCases(in context: ModelContext) throws {
        // User with empty name
        let emptyNameUser = UserProfile(
            id: UUID(),
            name: "",
            relation: "Self",
            avatarColor: "#FF6B6B",
            createdAt: Date()
        )
        context.insert(emptyNameUser)

        // Spot with empty title
        let emptyTitleSpot = Spot(
            id: UUID(),
            title: "",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: emptyNameUser
        )
        context.insert(emptyTitleSpot)

        // Log entry with extreme values
        let extremeEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "EXTREME.jpg",
            note: String(repeating: "Very long note. ", count: 100),
            painScore: 10,
            hasBleeding: true,
            hasItching: true,
            isSwollen: true,
            estimatedSize: 999.9,
            spot: emptyTitleSpot
        )
        context.insert(extremeEntry)

        // Zero values
        let zeroEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "ZERO.jpg",
            note: "",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: 0.0,
            spot: emptyTitleSpot
        )
        context.insert(zeroEntry)
    }

    // MARK: - Query Helpers

    /// Fetches all objects of a specific type from the context
    static funcfetchAll<T: PersistentModel>(_ type: T.Type, from context: ModelContext) throws -> [T] {
        let descriptor = FetchDescriptor<T>()
        return try context.fetch(descriptor)
    }

    /// Counts objects of a specific type in the context
    static func count<T: PersistentModel>(_ type: T.Type, in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<T>()
        return try context.fetchCount(descriptor)
    }

    /// Fetches user profile by name
    static func fetchUser(byName name: String, from context: ModelContext) throws -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate<UserProfile> { $0.name == name }
        )
        return try context.fetch(descriptor).first
    }

    /// Fetches active spots for a user
    static func fetchActiveSpots(for user: UserProfile, from context: ModelContext) throws -> [Spot] {
        let descriptor = FetchDescriptor<Spot>(
            predicate: #Predicate<Spot> { $0.userProfile?.id == user.id && $0.isActive == true }
        )
        return try context.fetch(descriptor)
    }

    /// Fetches log entries with pain score above threshold
    static func fetchHighPainEntries(above threshold: Int, from context: ModelContext) throws -> [LogEntry] {
        let descriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { $0.painScore > threshold }
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Validation Helpers

    /// Validates database integrity and relationships
    static func validateDatabaseIntegrity(in context: ModelContext) throws -> DatabaseValidationResult {
        let userCount = try count(UserProfile.self, in: context)
        let spotCount = try count(Spot.self, in: context)
        let logEntryCount = try count(LogEntry.self, in: context)

        // Check for orphaned spots (spots without users)
        let orphanedSpots = try fetchAll(Spot.self, from: context)
            .filter { $0.userProfile == nil }

        // Check for orphaned log entries (entries without spots)
        let orphanedLogEntries = try fetchAll(LogEntry.self, from: context)
            .filter { $0.spot == nil }

        // Check for invalid pain scores
        let invalidPainScores = try fetchAll(LogEntry.self, from: context)
            .filter { $0.painScore < 0 || $0.painScore > 10 }

        return DatabaseValidationResult(
            userCount: userCount,
            spotCount: spotCount,
            logEntryCount: logEntryCount,
            orphanedSpots: orphanedSpots,
            orphanedLogEntries: orphanedLogEntries,
            invalidPainScores: invalidPainScores,
            isValid: orphanedSpots.isEmpty && orphanedLogEntries.isEmpty && invalidPainScores.isEmpty
        )
    }

    // MARK: - Cleanup Helpers

    /// Performs complete cleanup of the test database
    static func cleanupDatabase(in context: ModelContext) throws {
        // Delete in reverse order to respect relationships
        let logEntries = try fetchAll(LogEntry.self, from: context)
        for entry in logEntries {
            context.delete(entry)
        }

        let spots = try fetchAll(Spot.self, from: context)
        for spot in spots {
            context.delete(spot)
        }

        let users = try fetchAll(UserProfile.self, from: context)
        for user in users {
            context.delete(user)
        }

        try context.save()
    }

    /// Resets the database to a clean state
    static func resetDatabase(in context: ModelContext) throws {
        try cleanupDatabase(in: context)
        // Verify cleanup
        let result = try validateDatabaseIntegrity(in: context)
        if !result.isValid || result.userCount > 0 || result.spotCount > 0 || result.logEntryCount > 0 {
            throw TestError.databaseResetFailed
        }
    }
}

// MARK: - Supporting Types

enum FixtureType {
    case empty
    case sampleData
    case minimalData
    case medicalScenarios
    case edgeCases
}

struct DatabaseValidationResult {
    let userCount: Int
    let spotCount: Int
    let logEntryCount: Int
    let orphanedSpots: [Spot]
    let orphanedLogEntries: [LogEntry]
    let invalidPainScores: [LogEntry]
    let isValid: Bool

    var hasIssues: Bool {
        !isValid || !orphanedSpots.isEmpty || !orphanedLogEntries.isEmpty || !invalidPainScores.isEmpty
    }

    var issuesSummary: String {
        var issues: [String] = []
        if !orphanedSpots.isEmpty {
            issues.append("\(orphanedSpots.count) orphaned spots")
        }
        if !orphanedLogEntries.isEmpty {
            issues.append("\(orphanedLogEntries.count) orphaned log entries")
        }
        if !invalidPainScores.isEmpty {
            issues.append("\(invalidPainScores.count) invalid pain scores")
        }
        return issues.joined(separator: ", ")
    }
}

enum TestError: Error, LocalizedError {
    case containerCreationFailed(Error)
    case databaseSetupFailed(String)
    case databaseResetFailed
    case validationFailed(String)

    var errorDescription: String? {
        switch self {
        case .containerCreationFailed(let error):
            return "Failed to create test container: \(error.localizedDescription)"
        case .databaseSetupFailed(let message):
            return "Database setup failed: \(message)"
        case .databaseResetFailed:
            return "Failed to reset database to clean state"
        case .validationFailed(let message):
            return "Database validation failed: \(message)"
        }
    }
}