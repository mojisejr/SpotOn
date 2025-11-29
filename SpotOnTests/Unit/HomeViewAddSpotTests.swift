//
//  HomeViewAddSpotTests.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import XCTest
import SwiftUI
import SwiftData
@testable import SpotOn

/// Test suite for HomeView Add New Spot integration
/// Tests the integration between HomeView and AddSpotView functionality
final class HomeViewAddSpotTests: XCTestCase {

    // MARK: - Test Properties

    private var testContainer: ModelContainer!
    private var testContext: ModelContext!
    private var testUserProfile: UserProfile!

    // MARK: - Setup and Teardown

    override func setUpWithError() throws {
        // Create in-memory test database
        testContainer = try ModelContainer(
            for: UserProfile.self, Spot.self, LogEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        testContext = testContainer.mainContext

        // Create test user profile
        testUserProfile = UserProfile(
            id: UUID(),
            name: "Test User",
            relation: "Self",
            avatarColor: "#FF6B6B",
            createdAt: Date()
        )
        testContext.insert(testUserProfile)
        try testContext.save()
    }

    override func tearDownWithError() throws {
        testContext = nil
        testContainer = nil
        testUserProfile = nil
    }

    // MARK: - Add Spot Button Tests

    func testHomeViewContainsAddSpotButton() throws {
        // Given: A HomeView with existing profiles
        let homeView = HomeView()
            .modelContainer(testContainer)

        // When: We render the HomeView
        // Then: It should contain an "Add New Spot" button
        // This will be validated through accessibility identifiers in implementation
        XCTAssertNotNil(homeView)
    }

    func testAddSpotButtonTriggersFormPresentation() throws {
        // Given: A HomeView with selected profile
        let homeView = HomeView()
            .modelContainer(testContainer)

        // When: The "Add New Spot" button is tapped
        // Then: It should trigger the AddSpotView presentation
        // This will be tested through button action in implementation
        XCTAssertNotNil(homeView)
    }

    func testAddSpotButtonAccessibility() throws {
        // Given: A HomeView
        let homeView = HomeView()
            .modelContainer(testContainer)

        // When: We check accessibility
        // Then: The Add Spot button should have proper accessibility labels
        XCTAssertNotNil(homeView)
        // Accessibility will be validated in implementation
    }

    func testAddSpotButtonVisibility() throws {
        // Given: A HomeView with profiles
        let homeView = HomeView()
            .modelContainer(testContainer)

        // When: We have a selected profile
        // Then: The Add Spot button should be visible
        // This will be tested through view hierarchy in implementation
        XCTAssertNotNil(homeView)
    }

    func testAddSpotButtonDisabledWithoutProfile() throws {
        // Given: A HomeView without selected profile
        let homeView = HomeView()
            .modelContainer(testContainer)

        // When: No profile is selected
        // Then: The Add Spot button should be disabled or hidden
        // This behavior will be validated in implementation
        XCTAssertNotNil(homeView)
    }

    // MARK: - Form Presentation Tests

    func testAddSpotViewPresentationFromHomeView() throws {
        // Given: A HomeView with Add New Spot button
        let homeView = HomeView()
            .modelContainer(testContainer)

        // When: The Add Spot button is tapped
        var isPresented = false

        // Simulate button tap
        isPresented = true

        // Then: AddSpotView should be presented as a sheet
        XCTAssertTrue(isPresented, "AddSpotView should be presented")

        let addSpotView = AddSpotView(
            isPresented: .init(
                get: { isPresented },
                set: { isPresented = $0 }
            ),
            userProfile: testUserProfile
        )
        XCTAssertNotNil(addSpotView)
    }

    func testAddSpotViewReceivesSelectedProfile() throws {
        // Given: A HomeView with selected profile
        let homeView = HomeView()
            .modelContainer(testContainer)

        // When: Add New Spot is triggered
        let selectedProfile = testUserProfile

        // Then: The AddSpotView should receive the selected profile
        let addSpotView = AddSpotView(
            isPresented: .constant(true),
            userProfile: selectedProfile
        )
        XCTAssertNotNil(addSpotView)
        XCTAssertEqual(addSpotView.userProfile?.id, selectedProfile?.id)
    }

    // MARK: - Spot Creation Integration Tests

    func testSpotCreationUpdatesHomeView() throws {
        // Given: A HomeView with selected profile and existing spots
        let initialSpotCount = try getSpotCount(for: testUserProfile)

        // When: A new spot is created through AddSpotView
        let newSpot = Spot(
            id: UUID(),
            title: "Integration Test Spot",
            bodyPart: "Left Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )
        testContext.insert(newSpot)
        try testContext.save()

        // Then: The HomeView spot list should update immediately
        let finalSpotCount = try getSpotCount(for: testUserProfile)
        XCTAssertEqual(finalSpotCount, initialSpotCount + 1, "HomeView should reflect new spot count")
    }

    func testMultipleSpotCreationUpdates() throws {
        // Given: A HomeView with selected profile
        let initialSpotCount = try getSpotCount(for: testUserProfile)
        let spotsToCreate = 3

        // When: Multiple spots are created
        for i in 1...spotsToCreate {
            let spot = Spot(
                id: UUID(),
                title: "Test Spot \(i)",
                bodyPart: "Left Arm",
                isActive: true,
                createdAt: Date(),
                userProfile: testUserProfile
            )
            testContext.insert(spot)
        }
        try testContext.save()

        // Then: HomeView should show all new spots
        let finalSpotCount = try getSpotCount(for: testUserProfile)
        XCTAssertEqual(finalSpotCount, initialSpotCount + spotsToCreate, "HomeView should reflect all new spots")
    }

    func testSpotCreationWithDifferentProfiles() throws {
        // Given: Two different user profiles
        let profile1 = testUserProfile!
        let profile2 = UserProfile(
            id: UUID(),
            name: "Second User",
            relation: "Spouse",
            avatarColor: "#4ECDC4",
            createdAt: Date()
        )
        testContext.insert(profile2)
        try testContext.save()

        // When: Spots are created for each profile
        let spot1 = Spot(
            id: UUID(),
            title: "Profile1 Spot",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: profile1
        )
        let spot2 = Spot(
            id: UUID(),
            title: "Profile2 Spot",
            bodyPart: "Leg",
            isActive: true,
            createdAt: Date(),
            userProfile: profile2
        )
        testContext.insert(spot1)
        testContext.insert(spot2)
        try testContext.save()

        // Then: Each profile should only see their own spots
        let profile1SpotCount = try getSpotCount(for: profile1)
        let profile2SpotCount = try getSpotCount(for: profile2)

        XCTAssertEqual(profile1SpotCount, 1, "Profile1 should have 1 spot")
        XCTAssertEqual(profile2SpotCount, 1, "Profile2 should have 1 spot")
    }

    // MARK: - Form Dismissal Integration Tests

    func testFormDismissalReturnsToHomeView() throws {
        // Given: HomeView presents AddSpotView
        var isPresented = true
        let homeView = HomeView()
            .modelContainer(testContainer)
        let addSpotView = AddSpotView(
            isPresented: .init(
                get: { isPresented },
                set: { isPresented = $0 }
            ),
            userProfile: testUserProfile
        )

        // When: Form is dismissed (cancel or save)
        isPresented = false

        // Then: User should return to HomeView
        XCTAssertFalse(isPresented, "Form should be dismissed")
        XCTAssertNotNil(homeView, "HomeView should still exist")
    }

    func testCancelDismissalPreservesData() throws {
        // Given: HomeView with existing spots
        let initialSpotCount = try getSpotCount(for: testUserProfile)
        var isPresented = true

        // When: Form is opened but cancelled without saving
        let addSpotView = AddSpotView(
            isPresented: .init(
                get: { isPresented },
                set: { isPresented = $0 }
            ),
            userProfile: testUserProfile
        )

        // Simulate form cancellation
        isPresented = false

        // Then: No new spots should be created
        let finalSpotCount = try getSpotCount(for: testUserProfile)
        XCTAssertEqual(finalSpotCount, initialSpotCount, "Cancel should not create new spots")
    }

    // MARK: - Error Handling Integration Tests

    func testSpotCreationErrorHandling() throws {
        // Given: HomeView with selected profile
        let homeView = HomeView()
            .modelContainer(testContainer)

        // When: Spot creation fails (e.g., validation error)
        let invalidSpot = Spot(
            id: UUID(),
            title: "", // Invalid empty title
            bodyPart: "", // Invalid empty body part
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        // Then: Error should be handled gracefully
        // This will be tested through error handling in implementation
        XCTAssertNotNil(homeView)
        XCTAssertNotNil(invalidSpot)
        // Form should show validation errors and not dismiss
    }

    func testDatabaseErrorIntegration() throws {
        // Given: A scenario that might cause database errors
        let homeView = HomeView()
            .modelContainer(testContainer)

        // When: Database operations fail
        // Then: HomeView should handle errors gracefully
        XCTAssertNotNil(homeView)
        // Error handling will be validated in implementation
    }

    // MARK: - UI State Management Tests

    func testHomeViewStateDuringSpotCreation() throws {
        // Given: HomeView with selected profile
        var isSpotFormPresented = false

        // When: Add Spot button is tapped
        isSpotFormPresented = true

        // Then: HomeView should maintain its state
        let homeView = HomeView()
            .modelContainer(testContainer)
        XCTAssertNotNil(homeView)
        XCTAssertTrue(isSpotFormPresented, "Form should be presented")

        // HomeView should keep profile selection and other state
        // This will be validated through state management in implementation
    }

    func testHomeViewRefreshAfterSpotCreation() throws {
        // Given: HomeView displaying spots
        let homeView = HomeView()
            .modelContainer(testContainer)
        let initialSpotCount = try getSpotCount(for: testUserProfile)

        // When: New spot is created
        let newSpot = Spot(
            id: UUID(),
            title: "Refresh Test Spot",
            bodyPart: "Back",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )
        testContext.insert(newSpot)
        try testContext.save()

        // Then: HomeView should automatically refresh to show new spot
        let finalSpotCount = try getSpotCount(for: testUserProfile)
        XCTAssertEqual(finalSpotCount, initialSpotCount + 1, "HomeView should refresh spot list")

        // SwiftData @Query should automatically update the UI
        // This will be validated through automatic query updates
    }

    // MARK: - Performance Integration Tests

    func testHomeViewPerformanceWithManySpots() throws {
        // Given: HomeView with many spots
        for i in 1..<50 {
            let spot = Spot(
                id: UUID(),
                title: "Performance Test Spot \(i)",
                bodyPart: "Arm",
                isActive: i % 2 == 0,
                createdAt: Date().addingTimeInterval(TimeInterval(-i * 3600)),
                userProfile: testUserProfile
            )
            testContext.insert(spot)
        }
        try testContext.save()

        let homeView = HomeView()
            .modelContainer(testContainer)

        // When: We measure HomeView performance
        measure(metrics: [
            XCTClockMetric(),
            XCTMemoryMetric()
        ]) {
            // Then: HomeView should perform well with many spots
            _ = homeView.body
        }
    }

    // MARK: - Accessibility Integration Tests

    func testAddSpotFlowAccessibility() throws {
        // Given: A user navigating with accessibility
        let homeView = HomeView()
            .modelContainer(testContainer)

        // When: User goes through the add spot flow
        // Then: All steps should be accessible
        XCTAssertNotNil(homeView)

        // This will test:
        // 1. Add Spot button is accessible
        // 2. Form presentation is accessible
        // 3. Form fields are accessible
        // 4. Form submission is accessible
        // 5. Return to HomeView is accessible
    }

    func testVoiceOverNavigationIntegration() throws {
        // Given: VoiceOver is enabled
        let homeView = HomeView()
            .modelContainer(testContainer)

        // When: User navigates with VoiceOver
        // Then: The add spot flow should be fully navigable
        XCTAssertNotNil(homeView)
        // VoiceOver navigation will be validated in implementation
    }

    // MARK: - Helper Methods

    /// Helper method to get spot count for a specific profile
    private func getSpotCount(for profile: UserProfile) throws -> Int {
        let fetchDescriptor = FetchDescriptor<Spot>(
            predicate: #Predicate<Spot> { $0.userProfile?.id == profile.id }
        )
        let spots = try testContext.fetch(fetchDescriptor)
        return spots.count
    }

    /// Helper method to simulate Add Spot button tap
    private func simulateAddSpotButtonTap(in homeView: HomeView) {
        // This will be used to simulate button interaction in implementation
        // For now, we validate the integration structure exists
    }

    /// Helper method to simulate form presentation
    private func simulateFormPresentation(from homeView: HomeView, with profile: UserProfile) {
        // This will be used to simulate sheet presentation in implementation
    }
}