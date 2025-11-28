//
//  UserProfileTests.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import XCTest
import SwiftData
@testable import SpotOn

final class UserProfileTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        // Create in-memory test container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: UserProfile.self, configurations: config)
        modelContext = ModelContext(modelContainer)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }

    // MARK: - Initialization Tests

    func testUserProfileInitialization() throws {
        // Given
        let userProfile = UserProfile(
            id: UUID(),
            name: "John Doe",
            relation: "Self",
            avatarColor: "#FF6B6B",
            createdAt: Date()
        )

        // Then
        XCTAssertNotNil(userProfile.id)
        XCTAssertEqual(userProfile.name, "John Doe")
        XCTAssertEqual(userProfile.relation, "Self")
        XCTAssertEqual(userProfile.avatarColor, "#FF6B6B")
        XCTAssertNotNil(userProfile.createdAt)
    }

    // MARK: - Property Tests

    func testUserProfileNameProperty() throws {
        // Given
        let validName = "Jane Smith"
        let userProfile = UserProfile(
            id: UUID(),
            name: validName,
            relation: "Spouse",
            avatarColor: "#4ECDC4",
            createdAt: Date()
        )

        // Then
        XCTAssertEqual(userProfile.name, validName)
        XCTAssertFalse(userProfile.name.isEmpty)
    }

    func testUserProfileRelationProperty() throws {
        // Given
        let validRelations = ["Self", "Father", "Mother", "Child", "Spouse", "Other"]

        for relation in validRelations {
            let userProfile = UserProfile(
                id: UUID(),
                name: "Test User",
                relation: relation,
                avatarColor: "#45B7D1",
                createdAt: Date()
            )

            // Then
            XCTAssertEqual(userProfile.relation, relation)
            XCTAssertFalse(userProfile.relation.isEmpty)
        }
    }

    func testUserProfileAvatarColorProperty() throws {
        // Given
        let validColors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD"]

        for color in validColors {
            let userProfile = UserProfile(
                id: UUID(),
                name: "Test User",
                relation: "Self",
                avatarColor: color,
                createdAt: Date()
            )

            // Then
            XCTAssertEqual(userProfile.avatarColor, color)
            XCTAssertTrue(userProfile.avatarColor.hasPrefix("#"))
            XCTAssertEqual(userProfile.avatarColor.count, 7) // #RRGGBB format
        }
    }

    // MARK: - Edge Case Tests

    func testUserProfileWithEmptyName() throws {
        // Given
        let emptyName = ""
        let userProfile = UserProfile(
            id: UUID(),
            name: emptyName,
            relation: "Self",
            avatarColor: "#FF6B6B",
            createdAt: Date()
        )

        // Then
        XCTAssertEqual(userProfile.name, emptyName)
        XCTAssertTrue(userProfile.name.isEmpty)
    }

    func testUserProfileWithEmptyRelation() throws {
        // Given
        let emptyRelation = ""
        let userProfile = UserProfile(
            id: UUID(),
            name: "Test User",
            relation: emptyRelation,
            avatarColor: "#4ECDC4",
            createdAt: Date()
        )

        // Then
        XCTAssertEqual(userProfile.relation, emptyRelation)
        XCTAssertTrue(userProfile.relation.isEmpty)
    }

    func testUserProfileWithEmptyAvatarColor() throws {
        // Given
        let emptyColor = ""
        let userProfile = UserProfile(
            id: UUID(),
            name: "Test User",
            relation: "Self",
            avatarColor: emptyColor,
            createdAt: Date()
        )

        // Then
        XCTAssertEqual(userProfile.avatarColor, emptyColor)
        XCTAssertTrue(userProfile.avatarColor.isEmpty)
    }

    func testUserProfileWithNilAvatarColor() throws {
        // This test will depend on whether avatarColor is optional or not
        // Adjust based on actual model implementation
        let userProfile = UserProfile(
            id: UUID(),
            name: "Test User",
            relation: "Self",
            avatarColor: "",
            createdAt: Date()
        )

        // Then
        XCTAssertNotNil(userProfile.avatarColor)
    }

    // MARK: - Date Tests

    func testUserProfileCreatedAtDate() throws {
        // Given
        let beforeCreation = Date()
        let userProfile = UserProfile(
            id: UUID(),
            name: "Test User",
            relation: "Self",
            avatarColor: "#FF6B6B",
            createdAt: Date()
        )
        let afterCreation = Date()

        // Then
        XCTAssertGreaterThanOrEqual(userProfile.createdAt, beforeCreation)
        XCTAssertLessThanOrEqual(userProfile.createdAt, afterCreation)
    }

    func testUserProfileWithSpecificDate() throws {
        // Given
        let specificDate = Date(timeIntervalSince1970: 1640995200) // Jan 1, 2022
        let userProfile = UserProfile(
            id: UUID(),
            name: "Test User",
            relation: "Self",
            avatarColor: "#4ECDC4",
            createdAt: specificDate
        )

        // Then
        XCTAssertEqual(userProfile.createdAt, specificDate)
    }

    // MARK: - UUID Tests

    func testUserProfileUniqueID() throws {
        // Given
        let userProfile1 = UserProfile(
            id: UUID(),
            name: "User 1",
            relation: "Self",
            avatarColor: "#FF6B6B",
            createdAt: Date()
        )

        let userProfile2 = UserProfile(
            id: UUID(),
            name: "User 2",
            relation: "Father",
            avatarColor: "#4ECDC4",
            createdAt: Date()
        )

        // Then
        XCTAssertNotEqual(userProfile1.id, userProfile2.id)
        XCTAssertNotEqual(userProfile1.name, userProfile2.name)
        XCTAssertNotEqual(userProfile1.relation, userProfile2.relation)
    }

    func testUserProfileWithSpecificID() throws {
        // Given
        let specificID = UUID()
        let userProfile = UserProfile(
            id: specificID,
            name: "Test User",
            relation: "Self",
            avatarColor: "#45B7D1",
            createdAt: Date()
        )

        // Then
        XCTAssertEqual(userProfile.id, specificID)
    }

    // MARK: - SwiftData Integration Tests

    func testUserProfileInsertion() throws {
        // Given
        let userProfile = UserProfile(
            id: UUID(),
            name: "Insert Test User",
            relation: "Self",
            avatarColor: "#96CEB4",
            createdAt: Date()
        )

        // When
        modelContext.insert(userProfile)
        try modelContext.save()

        // Then
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let fetchedUsers = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(fetchedUsers.count, 1)
        XCTAssertEqual(fetchedUsers.first?.name, "Insert Test User")
        XCTAssertEqual(fetchedUsers.first?.relation, "Self")
        XCTAssertEqual(fetchedUsers.first?.avatarColor, "#96CEB4")
    }

    func testUserProfileDeletion() throws {
        // Given
        let userProfile = UserProfile(
            id: UUID(),
            name: "Delete Test User",
            relation: "Father",
            avatarColor: "#FFEAA7",
            createdAt: Date()
        )

        modelContext.insert(userProfile)
        try modelContext.save()

        // Verify insertion
        var fetchDescriptor = FetchDescriptor<UserProfile>()
        var fetchedUsers = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedUsers.count, 1)

        // When
        modelContext.delete(userProfile)
        try modelContext.save()

        // Then
        fetchedUsers = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedUsers.count, 0)
    }

    func testUserProfileQuery() throws {
        // Given
        let users = [
            UserProfile(id: UUID(), name: "John", relation: "Self", avatarColor: "#FF6B6B", createdAt: Date()),
            UserProfile(id: UUID(), name: "Jane", relation: "Spouse", avatarColor: "#4ECDC4", createdAt: Date()),
            UserProfile(id: UUID(), name: "Bob", relation: "Father", avatarColor: "#45B7D1", createdAt: Date())
        ]

        for user in users {
            modelContext.insert(user)
        }
        try modelContext.save()

        // When
        let fetchDescriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate<UserProfile> { $0.relation == "Self" }
        )
        let fetchedUsers = try modelContext.fetch(fetchDescriptor)

        // Then
        XCTAssertEqual(fetchedUsers.count, 1)
        XCTAssertEqual(fetchedUsers.first?.name, "John")
    }

    // MARK: - Performance Tests

    func testUserProfileCreationPerformance() throws {
        measure {
            for _ in 0..<1000 {
                let _ = UserProfile(
                    id: UUID(),
                    name: "Performance Test User",
                    relation: "Self",
                    avatarColor: "#FF6B6B",
                    createdAt: Date()
                )
            }
        }
    }
}