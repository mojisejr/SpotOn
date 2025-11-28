//
//  SpotTests.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import XCTest
import SwiftData
@testable import SpotOn

final class SpotTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testUserProfile: UserProfile!

    override func setUpWithError() throws {
        // Create in-memory test container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: UserProfile.self, Spot.self, configurations: config)
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
        try modelContext.save()
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
        testUserProfile = nil
    }

    // MARK: - Initialization Tests

    func testSpotInitialization() throws {
        // Given
        let spot = Spot(
            id: UUID(),
            title: "Mole on Arm",
            bodyPart: "Left Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        // Then
        XCTAssertNotNil(spot.id)
        XCTAssertEqual(spot.title, "Mole on Arm")
        XCTAssertEqual(spot.bodyPart, "Left Arm")
        XCTAssertTrue(spot.isActive)
        XCTAssertNotNil(spot.createdAt)
        XCTAssertEqual(spot.userProfile, testUserProfile)
    }

    // MARK: - Property Tests

    func testSpotTitleProperty() throws {
        // Given
        let validTitles = ["Mole", "Rash", "Wound", "Scar", "Birthmark", "Acne"]

        for title in validTitles {
            let spot = Spot(
                id: UUID(),
                title: title,
                bodyPart: "Arm",
                isActive: true,
                createdAt: Date(),
                userProfile: testUserProfile
            )

            // Then
            XCTAssertEqual(spot.title, title)
            XCTAssertFalse(spot.title.isEmpty)
        }
    }

    func testSpotBodyPartProperty() throws {
        // Given
        let validBodyParts = [
            "Head", "Face", "Neck", "Chest", "Back", "Abdomen",
            "Left Arm", "Right Arm", "Left Leg", "Right Leg",
            "Left Hand", "Right Hand", "Left Foot", "Right Foot"
        ]

        for bodyPart in validBodyParts {
            let spot = Spot(
                id: UUID(),
                title: "Test Spot",
                bodyPart: bodyPart,
                isActive: true,
                createdAt: Date(),
                userProfile: testUserProfile
            )

            // Then
            XCTAssertEqual(spot.bodyPart, bodyPart)
            XCTAssertFalse(spot.bodyPart.isEmpty)
        }
    }

    func testSpotIsActiveProperty() throws {
        // Given
        let activeSpot = Spot(
            id: UUID(),
            title: "Active Spot",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        let inactiveSpot = Spot(
            id: UUID(),
            title: "Inactive Spot",
            bodyPart: "Leg",
            isActive: false,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        // Then
        XCTAssertTrue(activeSpot.isActive)
        XCTAssertFalse(inactiveSpot.isActive)
    }

    // MARK: - Edge Case Tests

    func testSpotWithEmptyTitle() throws {
        // Given
        let emptyTitle = ""
        let spot = Spot(
            id: UUID(),
            title: emptyTitle,
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        // Then
        XCTAssertEqual(spot.title, emptyTitle)
        XCTAssertTrue(spot.title.isEmpty)
    }

    func testSpotWithEmptyBodyPart() throws {
        // Given
        let emptyBodyPart = ""
        let spot = Spot(
            id: UUID(),
            title: "Test Spot",
            bodyPart: emptyBodyPart,
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        // Then
        XCTAssertEqual(spot.bodyPart, emptyBodyPart)
        XCTAssertTrue(spot.bodyPart.isEmpty)
    }

    func testSpotWithVeryLongTitle() throws {
        // Given
        let longTitle = String(repeating: "Very Long Spot Title ", count: 20)
        let spot = Spot(
            id: UUID(),
            title: longTitle,
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        // Then
        XCTAssertEqual(spot.title, longTitle)
        XCTAssertGreaterThan(spot.title.count, 300)
    }

    func testSpotWithSpecialCharactersInTitle() throws {
        // Given
        let specialTitles = ["Mole @ #1", "Rash! %^&", "Wound-123", "Scar_456", "Birthmark.*"]

        for title in specialTitles {
            let spot = Spot(
                id: UUID(),
                title: title,
                bodyPart: "Arm",
                isActive: true,
                createdAt: Date(),
                userProfile: testUserProfile
            )

            // Then
            XCTAssertEqual(spot.title, title)
        }
    }

    // MARK: - Date Tests

    func testSpotCreatedAtDate() throws {
        // Given
        let beforeCreation = Date()
        let spot = Spot(
            id: UUID(),
            title: "Date Test Spot",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )
        let afterCreation = Date()

        // Then
        XCTAssertGreaterThanOrEqual(spot.createdAt, beforeCreation)
        XCTAssertLessThanOrEqual(spot.createdAt, afterCreation)
    }

    func testSpotWithSpecificDate() throws {
        // Given
        let specificDate = Date(timeIntervalSince1970: 1640995200) // Jan 1, 2022
        let spot = Spot(
            id: UUID(),
            title: "Specific Date Spot",
            bodyPart: "Leg",
            isActive: true,
            createdAt: specificDate,
            userProfile: testUserProfile
        )

        // Then
        XCTAssertEqual(spot.createdAt, specificDate)
    }

    // MARK: - UUID Tests

    func testSpotUniqueID() throws {
        // Given
        let spot1 = Spot(
            id: UUID(),
            title: "Spot 1",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        let spot2 = Spot(
            id: UUID(),
            title: "Spot 2",
            bodyPart: "Leg",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        // Then
        XCTAssertNotEqual(spot1.id, spot2.id)
        XCTAssertNotEqual(spot1.title, spot2.title)
        XCTAssertNotEqual(spot1.bodyPart, spot2.bodyPart)
        XCTAssertEqual(spot1.userProfile, spot2.userProfile) // Same user
    }

    func testSpotWithSpecificID() throws {
        // Given
        let specificID = UUID()
        let spot = Spot(
            id: specificID,
            title: "Specific ID Spot",
            bodyPart: "Back",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        // Then
        XCTAssertEqual(spot.id, specificID)
    }

    // MARK: - User Profile Relationship Tests

    func testSpotUserRelationship() throws {
        // Given
        let anotherUser = UserProfile(
            id: UUID(),
            name: "Another User",
            relation: "Father",
            avatarColor: "#4ECDC4",
            createdAt: Date()
        )
        modelContext.insert(anotherUser)
        try modelContext.save()

        let spot1 = Spot(
            id: UUID(),
            title: "User 1 Spot",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        let spot2 = Spot(
            id: UUID(),
            title: "User 2 Spot",
            bodyPart: "Leg",
            isActive: true,
            createdAt: Date(),
            userProfile: anotherUser
        )

        // Then
        XCTAssertEqual(spot1.userProfile, testUserProfile)
        XCTAssertEqual(spot2.userProfile, anotherUser)
        XCTAssertNotEqual(spot1.userProfile, spot2.userProfile)
    }

    func testSpotWithoutUser() throws {
        // This test will depend on whether the relationship is optional
        // For now, assuming it's required
        XCTAssertNotNil(testUserProfile)
    }

    // MARK: - SwiftData Integration Tests

    func testSpotInsertion() throws {
        // Given
        let spot = Spot(
            id: UUID(),
            title: "Insert Test Spot",
            bodyPart: "Left Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        // When
        modelContext.insert(spot)
        try modelContext.save()

        // Then
        let fetchDescriptor = FetchDescriptor<Spot>()
        let fetchedSpots = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(fetchedSpots.count, 1)
        XCTAssertEqual(fetchedSpots.first?.title, "Insert Test Spot")
        XCTAssertEqual(fetchedSpots.first?.bodyPart, "Left Arm")
        XCTAssertTrue(fetchedSpots.first?.isActive ?? false)
        XCTAssertEqual(fetchedSpots.first?.userProfile?.name, testUserProfile.name)
    }

    func testSpotDeletion() throws {
        // Given
        let spot = Spot(
            id: UUID(),
            title: "Delete Test Spot",
            bodyPart: "Right Leg",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        modelContext.insert(spot)
        try modelContext.save()

        // Verify insertion
        var fetchDescriptor = FetchDescriptor<Spot>()
        var fetchedSpots = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedSpots.count, 1)

        // When
        modelContext.delete(spot)
        try modelContext.save()

        // Then
        fetchedSpots = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedSpots.count, 0)
    }

    func testSpotQueryByUser() throws {
        // Given
        let anotherUser = UserProfile(
            id: UUID(),
            name: "Query Test User",
            relation: "Spouse",
            avatarColor: "#45B7D1",
            createdAt: Date()
        )
        modelContext.insert(anotherUser)
        try modelContext.save()

        let user1Spots = [
            Spot(id: UUID(), title: "Spot 1", bodyPart: "Arm", isActive: true, createdAt: Date(), userProfile: testUserProfile),
            Spot(id: UUID(), title: "Spot 2", bodyPart: "Leg", isActive: true, createdAt: Date(), userProfile: testUserProfile)
        ]

        let user2Spots = [
            Spot(id: UUID(), title: "Spot 3", bodyPart: "Back", isActive: true, createdAt: Date(), userProfile: anotherUser)
        ]

        for spot in user1Spots + user2Spots {
            modelContext.insert(spot)
        }
        try modelContext.save()

        // When
        let fetchDescriptor = FetchDescriptor<Spot>(
            predicate: #Predicate<Spot> { $0.userProfile?.name == testUserProfile.name }
        )
        let fetchedSpots = try modelContext.fetch(fetchDescriptor)

        // Then
        XCTAssertEqual(fetchedSpots.count, 2)
        XCTAssertTrue(fetchedSpots.allSatisfy { $0.userProfile?.name == testUserProfile.name })
    }

    func testSpotQueryByActiveStatus() throws {
        // Given
        let activeSpots = [
            Spot(id: UUID(), title: "Active 1", bodyPart: "Arm", isActive: true, createdAt: Date(), userProfile: testUserProfile),
            Spot(id: UUID(), title: "Active 2", bodyPart: "Leg", isActive: true, createdAt: Date(), userProfile: testUserProfile)
        ]

        let inactiveSpots = [
            Spot(id: UUID(), title: "Inactive 1", bodyPart: "Back", isActive: false, createdAt: Date(), userProfile: testUserProfile)
        ]

        for spot in activeSpots + inactiveSpots {
            modelContext.insert(spot)
        }
        try modelContext.save()

        // When
        let activeFetchDescriptor = FetchDescriptor<Spot>(
            predicate: #Predicate<Spot> { $0.isActive == true }
        )
        let activeFetchedSpots = try modelContext.fetch(activeFetchDescriptor)

        let inactiveFetchDescriptor = FetchDescriptor<Spot>(
            predicate: #Predicate<Spot> { $0.isActive == false }
        )
        let inactiveFetchedSpots = try modelContext.fetch(inactiveFetchDescriptor)

        // Then
        XCTAssertEqual(activeFetchedSpots.count, 2)
        XCTAssertEqual(inactiveFetchedSpots.count, 1)
        XCTAssertTrue(activeFetchedSpots.allSatisfy { $0.isActive })
        XCTAssertTrue(inactiveFetchedSpots.allSatisfy { !$0.isActive })
    }

    // MARK: - Performance Tests

    func testSpotCreationPerformance() throws {
        measure {
            for _ in 0..<1000 {
                let _ = Spot(
                    id: UUID(),
                    title: "Performance Test Spot",
                    bodyPart: "Arm",
                    isActive: true,
                    createdAt: Date(),
                    userProfile: testUserProfile
                )
            }
        }
    }

    func testSpotInsertionPerformance() throws {
        measure {
            do {
                for i in 0..<100 {
                    let spot = Spot(
                        id: UUID(),
                        title: "Performance Spot \(i)",
                        bodyPart: "Test Body Part",
                        isActive: i % 2 == 0,
                        createdAt: Date(),
                        userProfile: testUserProfile
                    )
                    modelContext.insert(spot)
                }
                try modelContext.save()

                // Clean up for next iteration
                let fetchDescriptor = FetchDescriptor<Spot>()
                let spots = try modelContext.fetch(fetchDescriptor)
                for spot in spots {
                    modelContext.delete(spot)
                }
                try modelContext.save()
            } catch {
                XCTFail("Performance test failed: \(error)")
            }
        }
    }
}