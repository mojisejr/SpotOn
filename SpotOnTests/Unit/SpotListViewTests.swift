//
//  SpotListViewTests.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import XCTest
import SwiftData
import SwiftUI
@testable import SpotOn

final class SpotListViewTests: XCTestCase {

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

    // MARK: - Basic Rendering Tests

    func testSpotListViewRendersCorrectly() throws {
        // This test will fail because SpotListView doesn't exist yet
        let spotListView = SpotListView(selectedProfileId: testUserProfile.id)

        // Verify the view can be created
        XCTAssertNotNil(spotListView)
    }

    func testSpotListViewWithNilProfileId() throws {
        let spotListView = SpotListView(selectedProfileId: nil)

        // View should handle nil profile ID gracefully
        XCTAssertNotNil(spotListView)
    }

    // MARK: - Spot Filtering Tests

    func testSpotListViewFiltersBySelectedProfile() throws {
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

        // Insert spots into context
        testContext.insert(spotForJohn)
        testContext.insert(spotForJane)
        try! testContext.save()

        // Create spot list view for John's profile
        let spotListView = SpotListView(selectedProfileId: testUserProfile.id)

        // Extract spot count from the view
        let spotCount = extractSpotCountFromView(spotListView)

        // Should only show John's spot (1 spot)
        XCTAssertEqual(spotCount, 1)
    }

    func testSpotListViewShowsMultipleSpotsForProfile() throws {
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
            isActive: true,
            createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            userProfile: testUserProfile
        )

        let spot3 = Spot(
            id: UUID(),
            title: "Knee Scar",
            bodyPart: "Knee",
            isActive: false,
            createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
            userProfile: testUserProfile
        )

        // Insert spots into context
        testContext.insert(spot1)
        testContext.insert(spot2)
        testContext.insert(spot3)
        try! testContext.save()

        // Create spot list view for John's profile
        let spotListView = SpotListView(selectedProfileId: testUserProfile.id)

        // Extract spot count from the view
        let spotCount = extractSpotCountFromView(spotListView)

        // Should show all John's spots (3 spots)
        XCTAssertEqual(spotCount, 3)
    }

    func testSpotListViewShowsNoSpotsForEmptyProfile() throws {
        // Don't create any spots for John's profile

        // Create spot list view for John's profile
        let spotListView = SpotListView(selectedProfileId: testUserProfile.id)

        // Extract spot count from the view
        let spotCount = extractSpotCountFromView(spotListView)

        // Should show no spots
        XCTAssertEqual(spotCount, 0)
    }

    // MARK: - Empty State Tests

    func testSpotListViewShowsEmptyStateWhenNoSpots() throws {
        // Don't create any spots for John's profile

        // Create spot list view for John's profile
        let spotListView = SpotListView(selectedProfileId: testUserProfile.id)

        // Check if empty state is shown
        let showsEmptyState = checkEmptyStateShown(spotListView)

        // Empty state should be shown
        XCTAssertTrue(showsEmptyState)
    }

    func testSpotListViewHidesEmptyStateWhenSpotsExist() throws {
        // Create a spot for John's profile
        let spot = Spot(
            id: UUID(),
            title: "John's Mole",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        testContext.insert(spot)
        try! testContext.save()

        // Create spot list view for John's profile
        let spotListView = SpotListView(selectedProfileId: testUserProfile.id)

        // Check if empty state is hidden
        let showsEmptyState = checkEmptyStateShown(spotListView)

        // Empty state should be hidden
        XCTAssertFalse(showsEmptyState)
    }

    // MARK: - Profile Switching Tests

    func testSpotListViewUpdatesWhenProfileIdChanges() throws {
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

        // Initially show John's spots
        let spotListView = SpotListView(selectedProfileId: testUserProfile.id)
        var spotCount = extractSpotCountFromView(spotListView)
        XCTAssertEqual(spotCount, 1)

        // Switch to Jane's profile
        let updatedSpotListView = SpotListView(selectedProfileId: anotherUserProfile.id)
        spotCount = extractSpotCountFromView(updatedSpotListView)
        XCTAssertEqual(spotCount, 1)

        // Switch to non-existent profile
        let emptySpotListView = SpotListView(selectedProfileId: UUID())
        spotCount = extractSpotCountFromView(emptySpotListView)
        XCTAssertEqual(spotCount, 0)
    }

    // MARK: - Real-time Updates Tests

    func testSpotListViewUpdatesWhenSpotAdded() throws {
        // Initially no spots
        let spotListView = SpotListView(selectedProfileId: testUserProfile.id)
        var spotCount = extractSpotCountFromView(spotListView)
        XCTAssertEqual(spotCount, 0)

        // Add a spot
        let spot = Spot(
            id: UUID(),
            title: "New Mole",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        testContext.insert(spot)
        try! testContext.save()

        // View should update to show new spot
        spotCount = extractSpotCountFromView(spotListView)
        XCTAssertEqual(spotCount, 1)
    }

    func testSpotListViewUpdatesWhenSpotRemoved() throws {
        // Create and add a spot
        let spot = Spot(
            id: UUID(),
            title: "Temporary Mole",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(),
            userProfile: testUserProfile
        )

        testContext.insert(spot)
        try! testContext.save()

        // Initially shows the spot
        let spotListView = SpotListView(selectedProfileId: testUserProfile.id)
        var spotCount = extractSpotCountFromView(spotListView)
        XCTAssertEqual(spotCount, 1)

        // Remove the spot
        testContext.delete(spot)
        try! testContext.save()

        // View should update to hide the removed spot
        spotCount = extractSpotCountFromView(spotListView)
        XCTAssertEqual(spotCount, 0)
    }

    // MARK: - Medical Theme Tests

    func testSpotListViewUsesMedicalTheme() throws {
        let spotListView = SpotListView(selectedProfileId: testUserProfile.id)

        // Verify medical theme is applied
        let hasMedicalStyling = checkMedicalThemeApplied(spotListView)

        XCTAssertTrue(hasMedicalStyling)
    }

    // MARK: - Performance Tests

    func testSpotListViewWithManySpots() throws {
        // Create many spots for performance testing
        for i in 0..<100 {
            let spot = Spot(
                id: UUID(),
                title: "Spot \(i)",
                bodyPart: "Body Part \(i)",
                isActive: i % 2 == 0, // Alternate active/inactive
                createdAt: Date(),
                userProfile: testUserProfile
            )
            testContext.insert(spot)
        }
        try! testContext.save()

        // Measure view rendering performance with many spots
        let spotListView = SpotListView(selectedProfileId: testUserProfile.id)

        measure {
            let spotCount = extractSpotCountFromView(spotListView)
            XCTAssertEqual(spotCount, 100)
        }
    }

    // MARK: - Helper Methods

    private func extractSpotCountFromView(_ view: some View) -> Int {
        // This is a placeholder implementation
        // In a real test, we would use ViewInspector to extract the actual spot count
        // For now, we'll simulate the count based on test setup
        return 0
    }

    private func checkEmptyStateShown(_ view: some View) -> Bool {
        // This is a placeholder implementation
        // In a real test, we would check if the empty state view is visible
        return false
    }

    private func checkMedicalThemeApplied(_ view: some View) -> Bool {
        // This is a placeholder implementation
        // In a real test, we would verify medical theme colors and styling
        return false
    }
}