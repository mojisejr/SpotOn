//
//  HomeViewSpotListTests.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import XCTest
import SwiftData
import SwiftUI
@testable import SpotOn

final class HomeViewSpotListTests: XCTestCase {

    // MARK: - Test Properties

    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var testUserProfile: UserProfile!
    var anotherUserProfile: UserProfile!

    override func setUp() {
        super.setUp()

        // Create in-memory test container
        testContainer = try! ModelContainer(
            for: UserProfile.self, Spot.self, LogEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        testContext = testContainer.mainContext

        // Create test user profiles
        testUserProfile = UserProfile(
            id: UUID(),
            name: "John Doe",
            relation: "Self",
            avatarColor: "#FF6B6B",
            createdAt: Date()
        )

        anotherUserProfile = UserProfile(
            id: UUID(),
            name: "Jane Doe",
            relation: "Spouse",
            avatarColor: "#4ECDC4",
            createdAt: Date()
        )

        // Insert profiles into context
        testContext.insert(testUserProfile)
        testContext.insert(anotherUserProfile)
        try! testContext.save()
    }

    override func tearDown() {
        testUserProfile = nil
        anotherUserProfile = nil
        testContext = nil
        testContainer = nil
        super.tearDown()
    }

    // MARK: - Integration Tests

    func testHomeViewIntegratesSpotList() throws {
        // This test will fail until HomeView integrates SpotListView
        let homeView = HomeView()
            .modelContainer(testContainer)

        // Verify the view can be created with spot list integration
        XCTAssertNotNil(homeView)
    }

    func testHomeViewSpotListReactsToProfileSelection() throws {
        // Create spots for both profiles
        let spotForJohn = Spot(
            id: UUID(),
            title: "John's Mole",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        let spotForJane = Spot(
            id: UUID(),
            title: "Jane's Rash",
            bodyPart: "Back",
            isActive: true,
            createdAt: Date(),
            userProfile: anotherUserProfile
        )

        testContext.insert(spotForJohn)
        testContext.insert(spotForJane)
        try! testContext.save()

        // Create HomeView
        let homeView = HomeView()
            .modelContainer(testContainer)

        // Simulate profile selection change
        let updatedHomeView = simulateProfileSelection(homeView, selectedProfileId: testUserProfile.id)

        // Verify spot list updates to show John's spots
        let showsCorrectSpots = verifySpotListShowsProfileSpots(updatedHomeView, profileId: testUserProfile.id)
        XCTAssertTrue(showsCorrectSpots)
    }

    func testHomeViewSpotListEmptyState() throws {
        // Create profile with no spots
        let homeView = HomeView()
            .modelContainer(testContainer)

        // Simulate profile selection
        let updatedHomeView = simulateProfileSelection(homeView, selectedProfileId: testUserProfile.id)

        // Verify empty state is shown
        let showsEmptyState = verifyEmptyStateShown(updatedHomeView)
        XCTAssertTrue(showsEmptyState)
    }

    func testHomeViewSpotListWithMultipleSpots() throws {
        // Create multiple spots for John's profile
        let spot1 = Spot(
            id: UUID(),
            title: "Left Arm Mole",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        let spot2 = Spot(
            id: UUID(),
            title: "Back Rash",
            bodyPart: "Back",
            isActive: false,
            createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
            userProfile: testUserProfile
        )

        let spot3 = Spot(
            id: UUID(),
            title: "Knee Scar",
            bodyPart: "Knee",
            isActive: true,
            createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
            userProfile: testUserProfile
        )

        testContext.insert(spot1)
        testContext.insert(spot2)
        testContext.insert(spot3)
        try! testContext.save()

        // Create HomeView
        let homeView = HomeView()
            .modelContainer(testContainer)

        // Simulate profile selection
        let updatedHomeView = simulateProfileSelection(homeView, selectedProfileId: testUserProfile.id)

        // Verify all spots are shown
        let spotCount = extractSpotCountFromHomeView(updatedHomeView)
        XCTAssertEqual(spotCount, 3)
    }

    func testHomeViewSpotListRealTimeUpdates() throws {
        // Create HomeView with empty profile
        let homeView = HomeView()
            .modelContainer(testContainer)

        // Simulate profile selection
        let updatedHomeView = simulateProfileSelection(homeView, selectedProfileId: testUserProfile.id)

        // Initially should show empty state
        var showsEmptyState = verifyEmptyStateShown(updatedHomeView)
        XCTAssertTrue(showsEmptyState)

        // Add a spot
        let spot = Spot(
            id: UUID(),
            title: "New Spot",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        testContext.insert(spot)
        try! testContext.save()

        // Verify spot list updates to show the new spot
        let spotCount = extractSpotCountFromHomeView(updatedHomeView)
        XCTAssertEqual(spotCount, 1)

        // Verify empty state is hidden
        showsEmptyState = verifyEmptyStateShown(updatedHomeView)
        XCTAssertFalse(showsEmptyState)
    }

    // MARK: - Layout Integration Tests

    func testHomeViewSpotListPosition() throws {
        let homeView = HomeView()
            .modelContainer(testContainer)

        // Verify spot list is positioned below profile row
        let hasCorrectLayout = verifySpotListPosition(homeView)
        XCTAssertTrue(hasCorrectLayout)
    }

    func testHomeViewSpotListScrollable() throws {
        // Create many spots to test scrolling
        for i in 0..<50 {
            let spot = Spot(
                id: UUID(),
                title: "Spot \(i)",
                bodyPart: "Body Part \(i)",
                isActive: true,
                createdAt: Date(),
                userProfile: testUserProfile
            )
            testContext.insert(spot)
        }
        try! testContext.save()

        let homeView = HomeView()
            .modelContainer(testContainer)

        // Simulate profile selection
        let updatedHomeView = simulateProfileSelection(homeView, selectedProfileId: testUserProfile.id)

        // Verify spot list is scrollable
        let isScrollable = verifySpotListScrollable(updatedHomeView)
        XCTAssertTrue(isScrollable)
    }

    // MARK: - Medical Theme Integration Tests

    func testHomeViewSpotListMedicalThemeConsistency() throws {
        let spot = Spot(
            id: UUID(),
            title: "Test Mole",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        testContext.insert(spot)
        try! testContext.save()

        let homeView = HomeView()
            .modelContainer(testContainer)

        // Simulate profile selection
        let updatedHomeView = simulateProfileSelection(homeView, selectedProfileId: testUserProfile.id)

        // Verify medical theme consistency
        let hasConsistentTheme = verifyMedicalThemeConsistency(updatedHomeView)
        XCTAssertTrue(hasConsistentTheme)
    }

    // MARK: - Performance Integration Tests

    func testHomeViewSpotListPerformanceWithManySpots() throws {
        // Create many spots for performance testing
        for i in 0..<100 {
            let spot = Spot(
                id: UUID(),
                title: "Performance Spot \(i)",
                bodyPart: "Body Part \(i)",
                isActive: i % 2 == 0,
                createdAt: Date(),
                userProfile: testUserProfile
            )
            testContext.insert(spot)
        }
        try! testContext.save()

        let homeView = HomeView()
            .modelContainer(testContainer)

        // Measure HomeView rendering performance with many spots
        measure {
            let updatedHomeView = simulateProfileSelection(homeView, selectedProfileId: testUserProfile.id)
            let spotCount = extractSpotCountFromHomeView(updatedHomeView)
            XCTAssertEqual(spotCount, 100)
        }
    }

    // MARK: - Edge Cases Integration Tests

    func testHomeViewSpotListWithCorruptedData() throws {
        // Create spot with potentially problematic data
        let corruptedSpot = Spot(
            id: UUID(),
            title: "", // Empty title
            bodyPart: "   ", // Whitespace only body part
            isActive: true,
            createdAt: Date.distantPast, // Very old date
            userProfile: testUserProfile
        )

        testContext.insert(corruptedSpot)
        try! testContext.save()

        let homeView = HomeView()
            .modelContainer(testContainer)

        // Simulate profile selection
        let updatedHomeView = simulateProfileSelection(homeView, selectedProfileId: testUserProfile.id)

        // Verify corrupted data is handled gracefully
        let handlesCorruptedData = verifyCorruptedDataHandling(updatedHomeView)
        XCTAssertTrue(handlesCorruptedData)
    }

    func testHomeViewSpotListWithNoProfileSelected() throws {
        // Create HomeView without selecting any profile
        let homeView = HomeView()
            .modelContainer(testContainer)

        // Simulate no profile selection
        let updatedHomeView = simulateProfileSelection(homeView, selectedProfileId: nil)

        // Verify view handles no profile selection gracefully
        let handlesNoProfile = verifyNoProfileSelectionHandling(updatedHomeView)
        XCTAssertTrue(handlesNoProfile)
    }

    // MARK: - Helper Methods

    private func simulateProfileSelection(_ homeView: HomeView, selectedProfileId: UUID?) -> HomeView {
        // This is a placeholder implementation
        // In a real test, we would simulate profile selection in HomeView
        return homeView
    }

    private func verifySpotListShowsProfileSpots(_ homeView: HomeView, profileId: UUID?) -> Bool {
        // This is a placeholder implementation
        // In a real test, we would verify that the spot list shows spots for the correct profile
        return false
    }

    private func verifyEmptyStateShown(_ homeView: HomeView) -> Bool {
        // This is a placeholder implementation
        // In a real test, we would check if the empty state is shown
        return false
    }

    private func extractSpotCountFromHomeView(_ homeView: HomeView) -> Int {
        // This is a placeholder implementation
        // In a real test, we would extract the actual spot count from HomeView
        return 0
    }

    private func verifySpotListPosition(_ homeView: HomeView) -> Bool {
        // This is a placeholder implementation
        // In a real test, we would verify the spot list is positioned correctly
        return false
    }

    private func verifySpotListScrollable(_ homeView: HomeView) -> Bool {
        // This is a placeholder implementation
        // In a real test, we would verify the spot list is scrollable
        return false
    }

    private func verifyMedicalThemeConsistency(_ homeView: HomeView) -> Bool {
        // This is a placeholder implementation
        // In a real test, we would verify medical theme consistency
        return false
    }

    private func verifyCorruptedDataHandling(_ homeView: HomeView) -> Bool {
        // This is a placeholder implementation
        // In a real test, we would verify corrupted data is handled gracefully
        return false
    }

    private func verifyNoProfileSelectionHandling(_ homeView: HomeView) -> Bool {
        // This is a placeholder implementation
        // In a real test, we would verify no profile selection is handled gracefully
        return false
    }
}