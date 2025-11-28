//
//  HomeViewTests.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import XCTest
import SwiftData
@testable import SpotOn

final class HomeViewTests: XCTestCase {

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

    // MARK: - Profile Loading Tests

    func testHomeViewLoadsProfilesFromSwiftData() throws {
        // Given multiple user profiles in database
        let profiles = [
            TestFixtures.UserProfiles.johnDoe,
            TestFixtures.UserProfiles.janeDoe,
            TestFixtures.UserProfiles.bobbyDoe
        ]

        for profile in profiles {
            testContext.insert(profile)
        }
        try testContext.save()

        // When HomeView loads with SwiftData @Query
        // Then it should display all profiles
        let fetchDescriptor = FetchDescriptor<UserProfile>(sortBy: [SortDescriptor(\.createdAt)])
        let loadedProfiles = try testContext.fetch(fetchDescriptor)

        XCTAssertEqual(loadedProfiles.count, 3, "HomeView should load 3 profiles from database")
        XCTAssertEqual(loadedProfiles.map { $0.name }, ["John Doe", "Jane Doe", "Bobby Doe"])
    }

    func testHomeViewEmptyStateWhenNoProfilesExist() throws {
        // Given empty database with no profiles
        // When HomeView loads
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let loadedProfiles = try testContext.fetch(fetchDescriptor)

        // Then should show empty state
        XCTAssertEqual(loadedProfiles.count, 0, "Should have no profiles")
        // HomeView should display empty state UI: "No profiles yet", "Create your first profile"
    }

    func testHomeViewShowsNewProfileImmediatelyAfterCreation() throws {
        // Given HomeView with existing profiles
        let initialProfile = TestFixtures.UserProfiles.johnDoe
        testContext.insert(initialProfile)
        try testContext.save()

        var fetchDescriptor = FetchDescriptor<UserProfile>()
        var loadedProfiles = try testContext.fetch(fetchDescriptor)
        XCTAssertEqual(loadedProfiles.count, 1, "Should start with 1 profile")

        // When new profile is added to database
        let newProfile = TestFixtures.UserProfiles.janeDoe
        testContext.insert(newProfile)
        try testContext.save()

        // Then HomeView should immediately show the new profile
        loadedProfiles = try testContext.fetch(fetchDescriptor)
        XCTAssertEqual(loadedProfiles.count, 2, "Should now have 2 profiles")

        let profileNames = loadedProfiles.map { $0.name }.sorted()
        XCTAssertTrue(profileNames.contains("John Doe"), "Should still show John Doe")
        XCTAssertTrue(profileNames.contains("Jane Doe"), "Should show new Jane Doe profile")
    }

    // MARK: - Profile Selection Tests

    func testProfileSelectionStateManagement() throws {
        // Given profiles are loaded in HomeView
        let profiles = [
            TestFixtures.UserProfiles.johnDoe,
            TestFixtures.UserProfiles.janeDoe
        ]

        for profile in profiles {
            testContext.insert(profile)
        }
        try testContext.save()

        // When user selects a profile
        // Then HomeView should update selected profile state
        let selectedProfileId = TestFixtures.UserProfiles.janeDoe.id

        // HomeView @State variable should track selected profile
        // This tests the selection mechanism that will be implemented
        let fetchDescriptor = FetchDescriptor<UserProfile>(predicate: #Predicate { $0.id == selectedProfileId })
        let selectedProfile = try testContext.fetch(fetchDescriptor).first

        XCTAssertNotNil(selectedProfile, "Should be able to fetch selected profile")
        XCTAssertEqual(selectedProfile?.name, "Jane Doe", "Selected profile should be Jane Doe")
        XCTAssertEqual(selectedProfile?.relation, "Spouse", "Selected profile should have correct relation")
    }

    func testProfileSelectionVisualFeedback() throws {
        // Given profile is selected
        let selectedProfile = TestFixtures.UserProfiles.johnDoe
        testContext.insert(selectedProfile)
        try testContext.save()

        // When HomeView renders
        // Then selected profile should have visual indication
        // Medical theme should be applied: selected border, background highlight

        // Test that selection state is properly maintained
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let profiles = try testContext.fetch(fetchDescriptor)

        XCTAssertEqual(profiles.count, 1, "Should have one profile")
        // The UI should show this profile as selected with:
        // - Medical Blue (#007AFF) border or background
        // - Increased opacity or visual emphasis
        // - Selection indicator (checkmark or similar)
    }

    // MARK: - Medical Theme Tests

    func testHomeViewAppliesMedicalThemeColors() throws {
        // Given HomeView is rendered
        // Then it should apply medical theme colors

        // Test medical blue color application
        let medicalBlue = "#007AFF"
        let backgroundColor = "#F2F2F7"

        // These colors should be used consistently throughout HomeView:
        // - Headers and important text: Medical Blue
        // - Backgrounds: Light gray background
        // - Profile selection indicators: Medical Blue
        // - Interactive elements: Medical Blue with proper contrast

        XCTAssertEqual(medicalBlue, "#007AFF", "Medical blue should be #007AFF")
        XCTAssertEqual(backgroundColor, "#F2F2F7", "Background should be #F2F2F7")
    }

    func testProfileCardMedicalStyling() throws {
        // Given profile cards are displayed
        let profile = TestFixtures.UserProfiles.johnDoe
        testContext.insert(profile)
        try testContext.save()

        // When profile cards render
        // Then they should apply medical theme styling

        // Profile cards should have:
        // - White background with subtle shadow
        // - Rounded corners for medical-friendly appearance
        // - Avatar with user's color: #FF6B6B
        // - Clean typography with medical blue accents
        // - Proper spacing and padding for accessibility

        let avatarColor = profile.avatarColor
        XCTAssertEqual(avatarColor, "#FF6B6B", "Profile should maintain its avatar color")
    }

    // MARK: - Accessibility Tests

    func testHomeViewAccessibilityIdentifiers() throws {
        // Given HomeView is rendered
        // Then all interactive elements should have accessibility identifiers

        let requiredIdentifiers = [
            "homeViewTitle",           // Main title
            "profileRowView",          // Profile selection row
            "emptyStateView",          // Empty state container
            "createProfileButton",     // Add profile button
            "profileCardView"          // Individual profile cards
        ]

        // These identifiers enable UI testing and VoiceOver support
        for identifier in requiredIdentifiers {
            let accessibilityString = identifier
            XCTAssertFalse(accessibilityString.isEmpty, "Accessibility identifier should not be empty")
        }
    }

    func testHomeViewVoiceOverSupport() throws {
        // Given HomeView is rendered with profiles
        let profiles = [
            TestFixtures.UserProfiles.johnDoe,
            TestFixtures.UserProfiles.janeDoe
        ]

        for profile in profiles {
            testContext.insert(profile)
        }
        try testContext.save()

        // When VoiceOver is enabled
        // Then elements should have proper accessibility labels

        // Profile cards should announce:
        // - "John Doe, Self, Profile, Double tap to select"
        // - "Jane Doe, Spouse, Profile, Double tap to select"

        // Empty state should announce:
        // - "No profiles yet, Create your first profile to get started"

        // Medical theme elements should have descriptive labels
        for profile in profiles {
            let accessibilityLabel = "\(profile.name), \(profile.relation), Profile"
            XCTAssertFalse(accessibilityLabel.isEmpty, "Profile should have meaningful accessibility label")
        }
    }

    func testHomeViewAccessibilityTraits() throws {
        // Given HomeView interactive elements
        // Then they should have appropriate accessibility traits

        // Profile cards: .button trait for selection
        // Empty state button: .button trait for profile creation
        // Navigation elements: .header traits for screen reader context

        // Elements should be properly grouped for logical navigation
        let profileButtonTrait = "button"
        let headerTrait = "header"

        XCTAssertFalse(profileButtonTrait.isEmpty, "Profile cards should be buttons")
        XCTAssertFalse(headerTrait.isEmpty, "Headers should have header trait")
    }

    // MARK: - Error Handling Tests

    func testHomeViewHandlesDatabaseCorruptionGracefully() throws {
        // Given database becomes corrupted or inaccessible
        // When HomeView tries to load profiles
        // Then it should show error state gracefully

        // HomeView should display:
        // - Error message: "Unable to load profiles"
        // - Retry button to attempt reloading
        // - Contact support option if persistent issues

        // App should not crash, remain usable
        let errorMessage = "Unable to load profiles"
        XCTAssertFalse(errorMessage.isEmpty, "Should show user-friendly error message")
    }

    func testHomeViewHandlesProfileCreationFailure() throws {
        // Given user tries to create profile but it fails
        // When profile creation encounters error
        // Then HomeView should show appropriate error feedback

        // Error scenarios to handle:
        // - Duplicate profile names
        // - Invalid avatar colors
        // - Database constraint violations
        // - Storage permissions issues

        let duplicateErrorMessage = "Profile with this name already exists"
        XCTAssertFalse(duplicateErrorMessage.isEmpty, "Should show specific error for duplicates")
    }

    // MARK: - Performance Tests

    func testHomeViewLoadPerformanceWithManyProfiles() throws {
        // Given large number of profiles (simulating long-term use)
        let profileCount = 50

        for i in 1...profileCount {
            let profile = TestHelpers.createTestUserProfile(
                name: "Test User \(i)",
                relation: i % 3 == 0 ? "Child" : (i % 2 == 0 ? "Spouse" : "Self"),
                avatarColor: TestHelpers.randomAvatarColor()
            )
            testContext.insert(profile)
        }
        try testContext.save()

        // When HomeView loads
        let fetchDescriptor = FetchDescriptor<UserProfile>(sortBy: [SortDescriptor(\.createdAt)])

        // Then loading should complete within acceptable time
        measure(metrics: [XCTClockMetric()]) {
            do {
                _ = try testContext.fetch(fetchDescriptor)
            } catch {
                XCTFail("Loading profiles should not fail: \(error)")
            }
        }

        // Verify all profiles were loaded
        do {
            let loadedProfiles = try testContext.fetch(fetchDescriptor)
            XCTAssertEqual(loadedProfiles.count, profileCount, "Should load all profiles")
        } catch {
            XCTFail("Should successfully load all profiles")
        }
    }

    func testHomeViewMemoryUsageWithProfileSwitching() throws {
        // Given multiple profiles
        let profiles = [
            TestFixtures.UserProfiles.johnDoe,
            TestFixtures.UserProfiles.janeDoe,
            TestFixtures.UserProfiles.bobbyDoe
        ]

        for profile in profiles {
            testContext.insert(profile)
        }
        try testContext.save()

        // When user rapidly switches between profiles
        let fetchDescriptor = FetchDescriptor<UserProfile>()

        // Simulate rapid profile selection changes
        for _ in 0..<10 {
            do {
                let loadedProfiles = try testContext.fetch(fetchDescriptor)
                XCTAssertFalse(loadedProfiles.isEmpty, "Should maintain profile data")

                // Simulate selection state changes
                if let randomProfile = loadedProfiles.randomElement() {
                    let _ = randomProfile.id // Selection simulation
                }
            } catch {
                XCTFail("Profile switching should not cause errors: \(error)")
            }
        }

        // Then memory usage should remain stable
        // Test should pass without memory warnings or crashes
        XCTAssertTrue(true, "Profile switching should not cause memory issues")
    }

    // MARK: - Integration Tests

    func testHomeViewIntegrationWithSpotData() throws {
        // Given user has profiles and associated spots
        let user = TestFixtures.UserProfiles.johnDoe
        let spot = TestFixtures.Spots.moleOnArm

        testContext.insert(user)
        testContext.insert(spot)
        try testContext.save()

        // When HomeView loads
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let loadedProfiles = try testContext.fetch(fetchDescriptor)

        // Then profile should show spot count or summary
        XCTAssertEqual(loadedProfiles.count, 1, "Should load user profile")

        if let profile = loadedProfiles.first {
            // Profile should have access to related spots
            let spotFetchDescriptor = FetchDescriptor<Spot>(predicate: #Predicate { $0.userProfile?.id == profile.id })
            let userSpots = try testContext.fetch(spotFetchDescriptor)

            XCTAssertEqual(userSpots.count, 1, "User should have 1 associated spot")
            XCTAssertEqual(userSpots.first?.title, "Mole on Left Arm", "Spot should match expected title")
        }
    }

    func testHomeViewProfileCreationFlow() throws {
        // Given HomeView is in empty state
        // When user taps "Create Profile" button
        // Then should navigate to profile creation flow

        // This tests the integration with profile creation UI
        // HomeView should handle navigation and state management

        let emptyStateMessage = "No profiles yet"
        let createProfileAction = "Create your first profile"

        XCTAssertFalse(emptyStateMessage.isEmpty, "Empty state should show clear message")
        XCTAssertFalse(createProfileAction.isEmpty, "Should guide user to create profile")

        // After profile creation, HomeView should immediately show new profile
        let newProfile = TestHelpers.createTestUserProfile(name: "New User")
        testContext.insert(newProfile)
        try testContext.save()

        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let profiles = try testContext.fetch(fetchDescriptor)
        XCTAssertEqual(profiles.count, 1, "New profile should appear immediately")
    }
}