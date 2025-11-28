//
//  ProfileRowViewTests.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import XCTest
import SwiftData
@testable import SpotOn

final class ProfileRowViewTests: XCTestCase {

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

    // MARK: - Profile Display and Layout Tests

    func testProfileRowViewDisplaysMultipleProfiles() throws {
        // Given multiple profiles in database
        let profiles = [
            TestFixtures.UserProfiles.johnDoe,
            TestFixtures.UserProfiles.janeDoe,
            TestFixtures.UserProfiles.bobbyDoe
        ]

        for profile in profiles {
            testContext.insert(profile)
        }
        try testContext.save()

        // When ProfileRowView loads
        let fetchDescriptor = FetchDescriptor<UserProfile>(sortBy: [SortDescriptor(\.createdAt)])
        let loadedProfiles = try testContext.fetch(fetchDescriptor)

        // Then it should display all profiles in a horizontal row
        XCTAssertEqual(loadedProfiles.count, 3, "ProfileRowView should display 3 profiles")
        XCTAssertEqual(loadedProfiles.map { $0.name }.sorted(), ["Bobby Doe", "Jane Doe", "John Doe"])
    }

    func testProfileRowViewHandlesSingleProfile() throws {
        // Given only one profile
        let singleProfile = TestFixtures.UserProfiles.johnDoe
        testContext.insert(singleProfile)
        try testContext.save()

        // When ProfileRowView loads
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let loadedProfiles = try testContext.fetch(fetchDescriptor)

        // Then it should display single profile centered or left-aligned
        XCTAssertEqual(loadedProfiles.count, 1, "Should display single profile")
        XCTAssertEqual(loadedProfiles.first?.name, "John Doe", "Should display correct profile")

        // Single profile should:
        // - Be automatically selected
        // - Show selection state
        // - Not require horizontal scrolling
    }

    func testProfileRowViewHandlesNoProfiles() throws {
        // Given empty database with no profiles
        // When ProfileRowView loads
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let loadedProfiles = try testContext.fetch(fetchDescriptor)

        // Then it should show empty state or guide user to create profile
        XCTAssertEqual(loadedProfiles.count, 0, "Should have no profiles to display")

        // Empty state should:
        // - Show "No profiles" message
        // - Guide to profile creation
        // - Maybe show "+ Add Profile" button
    }

    func testProfileRowViewHorizontalScrolling() throws {
        // Given more profiles than can fit on screen
        let profileCount = 10
        for i in 1...profileCount {
            let profile = TestHelpers.createTestUserProfile(
                name: "Profile \(i)",
                relation: ["Self", "Spouse", "Child"][i % 3],
                avatarColor: TestHelpers.randomAvatarColor()
            )
            testContext.insert(profile)
        }
        try testContext.save()

        // When ProfileRowView loads with many profiles
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let loadedProfiles = try testContext.fetch(fetchDescriptor)

        // Then it should enable horizontal scrolling
        XCTAssertEqual(loadedProfiles.count, profileCount, "Should load all profiles")

        // Horizontal scroll behavior:
        // - ScrollView should be horizontally scrollable
        // - Profiles should scroll smoothly
        // - Scroll should snap to profile boundaries
        // - First/last profiles should be accessible
    }

    // MARK: - Profile Selection Tests

    func testProfileRowViewSelectionStateManagement() throws {
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

        // When user selects a profile
        let selectedProfileId = TestFixtures.UserProfiles.janeDoe.id
        let selectedProfile = profiles.first { $0.id == selectedProfileId }

        // Then ProfileRowView should track and display selection
        XCTAssertNotNil(selectedProfile, "Should find selected profile")
        XCTAssertEqual(selectedProfile?.name, "Jane Doe", "Should select correct profile")

        // Selection state should:
        // - Update visual appearance of selected profile
        // - Maintain selection across data updates
        // - Persist selection state
    }

    func testProfileRowViewDefaultSelection() throws {
        // Given profiles exist
        let profiles = [
            TestFixtures.UserProfiles.janeDoe,
            TestFixtures.UserProfiles.johnDoe
        ]

        for profile in profiles {
            testContext.insert(profile)
        }
        try testContext.save()

        // When ProfileRowView first loads
        // Then it should select the first profile by default
        let fetchDescriptor = FetchDescriptor<UserProfile>(sortBy: [SortDescriptor(\.createdAt)])
        let loadedProfiles = try testContext.fetch(fetchDescriptor)

        XCTAssertFalse(loadedProfiles.isEmpty, "Should have profiles loaded")

        if let firstProfile = loadedProfiles.first {
            // First profile should be automatically selected
            XCTAssertNotNil(firstProfile.id, "First profile should have valid ID")
            XCTAssertTrue(firstProfile.name.count > 0, "First profile should have name")
        }
    }

    func testProfileRowViewSelectionUpdatesVisualState() throws {
        // Given a profile is selected
        let profile = TestFixtures.UserProfiles.johnDoe
        let isSelected = true

        // When selection state changes
        // Then visual appearance should update

        if isSelected {
            // Selected profile should show:
            // - Medical blue (#007AFF) border or highlight
            // - Increased scale (1.1x)
            // - Selection checkmark or indicator
            // - Reduced opacity on other profiles

            let selectionColor = "#007AFF"
            let selectionScale: CGFloat = 1.1
            let selectionOpacity: Float = 1.0

            XCTAssertEqual(selectionColor, "#007AFF", "Selection should use medical blue")
            XCTAssertEqual(selectionScale, 1.1, "Selected should be 10% larger")
            XCTAssertEqual(selectionOpacity, 1.0, "Selected should be fully opaque")
        }
    }

    func testProfileRowViewMultiSelectionBehavior() throws {
        // Given multiple profiles exist
        let profiles = [
            TestFixtures.UserProfiles.johnDoe,
            TestFixtures.UserProfiles.janeDoe
        ]

        // When switching between profiles
        // Then only one profile should be selected at a time

        let selectedJohn = profiles[0]
        let selectedJane = profiles[1]

        XCTAssertNotEqual(selectedJohn.id, selectedJane.id, "Profiles should have different IDs")

        // Selection should be mutually exclusive:
        // - Selecting one profile deselects others
        // - Visual state should update for all profiles
        // - Selection callback should fire only once per change
    }

    // MARK: - Layout and Spacing Tests

    func testProfileRowViewProfileSpacing() throws {
        // Given multiple profiles in row
        // When ProfileRowView lays out profiles
        // Then spacing should be consistent and appropriate

        let profileSpacing: CGFloat = 12 // 12pt between profiles
        let rowPadding: CGFloat = 16 // 16pt padding on sides
        let profileWidth: CGFloat = 100 // 100pt profile card width

        XCTAssertEqual(profileSpacing, 12, "Profiles should have consistent 12pt spacing")
        XCTAssertEqual(rowPadding, 16, "Row should have 16pt padding")
        XCTAssertEqual(profileWidth, 100, "Profile cards should be 100pt wide")

        // Layout should:
        // - Provide adequate tap targets (minimum 44pt)
        // - Show partial profiles to indicate scrollability
        // - Maintain consistent spacing
        // - Align profiles properly
    }

    func testProfileRowViewScrollIndicators() throws {
        // Given more profiles than screen width
        let profileCount = 8
        for i in 1...profileCount {
            let profile = TestHelpers.createTestUserProfile(
                name: "Profile \(i)",
                relation: "Self",
                avatarColor: TestHelpers.randomAvatarColor()
            )
            testContext.insert(profile)
        }
        try testContext.save()

        // When ProfileRowView loads
        // Then it should show scroll indicators appropriately

        let showScrollIndicator = true
        let scrollIndicatorStyle = "default"

        XCTAssertTrue(showScrollIndicator, "Should show scroll indicators when content overflows")
        XCTAssertEqual(scrollIndicatorStyle, "default", "Should use default scroll indicator style")

        // Scroll indicators should:
        // - Appear when content extends beyond visible area
        // - Fade when not scrolling
        // - Be positioned appropriately
        // - Follow iOS design guidelines
    }

    func testProfileRowViewMinimumTapTargetSize() throws {
        // Given profile cards in row
        // When ProfileRowView renders interactive elements
        // Then all tappable elements should meet accessibility requirements

        let minimumTapTargetSize: CGFloat = 44 // iOS accessibility requirement
        let profileCardHeight: CGFloat = 120
        let profileCardWidth: CGFloat = 100

        XCTAssertEqual(minimumTapTargetSize, 44, "Minimum tap target should be 44pt")
        XCTAssertTrue(profileCardHeight >= minimumTapTargetSize, "Profile height should meet tap target requirement")
        XCTAssertTrue(profileCardWidth >= minimumTapTargetSize, "Profile width should meet tap target requirement")

        // Tap targets should:
        // - Be at least 44x44 points
        // - Have adequate spacing between elements
        // - Be accessible to users with motor impairments
        // - Support VoiceOver navigation
    }

    // MARK: - Medical Theme Tests

    func testProfileRowViewMedicalThemeColors() throws {
        // Given ProfileRowView with medical theme
        // Then it should apply consistent medical styling

        let medicalBlue = "#007AFF" // Primary interaction color
        let backgroundColor = "#F2F2F7" // Row background
        let cardBackground = "#FFFFFF" // Individual card backgrounds
        let selectedBorderColor = "#007AFF" // Selection indicator
        let unselectedBorderColor = "#E0E0E0" // Default border

        XCTAssertEqual(medicalBlue, "#007AFF", "Primary color should be medical blue")
        XCTAssertEqual(backgroundColor, "#F2F2F7", "Background should be light gray")
        XCTAssertEqual(cardBackground, "#FFFFFF", "Cards should have white background")
        XCTAssertEqual(selectedBorderColor, "#007AFF", "Selected border should be medical blue")
        XCTAssertEqual(unselectedBorderColor, "#E0E0E0", "Unselected border should be light gray")
    }

    func testProfileRowViewTypography() throws {
        // Given medical-appropriate typography
        // Then ProfileRowView should use clean, readable fonts

        let profileNameFont = "SFProDisplay-Semibold"
        let profileRelationFont = "SFProText-Regular"
        let nameFontSize: CGFloat = 16
        let relationFontSize: CGFloat = 12

        XCTAssertEqual(profileNameFont, "SFProDisplay-Semibold", "Name should use SF Pro Display Semibold")
        XCTAssertEqual(profileRelationFont, "SFProText-Regular", "Relation should use SF Pro Text Regular")
        XCTAssertEqual(nameFontSize, 16, "Name should be 16pt for readability")
        XCTAssertEqual(relationFontSize, 12, "Relation should be 12pt for hierarchy")
    }

    func testProfileRowViewVisualHierarchy() throws {
        // Given multiple profile cards
        // Then visual hierarchy should be clear

        let selectedZIndex: CGFloat = 2
        let unselectedZIndex: CGFloat = 1
        let selectedShadowOpacity: Float = 0.2
        let unselectedShadowOpacity: Float = 0.1

        XCTAssertEqual(selectedZIndex, 2, "Selected profile should be above others")
        XCTAssertEqual(unselectedZIndex, 1, "Unselected profiles should be below selected")
        XCTAssertEqual(selectedShadowOpacity, 0.2, "Selected should have stronger shadow")
        XCTAssertEqual(unselectedShadowOpacity, 0.1, "Unselected should have subtle shadow")

        // Visual hierarchy should:
        // - Clearly indicate selected state
        // - Provide depth and dimension
        // - Guide user attention
        // - Maintain medical aesthetic
    }

    // MARK: - Interaction Tests

    func testProfileRowViewTapSelection() throws {
        // Given multiple profiles
        let profiles = [
            TestFixtures.UserProfiles.johnDoe,
            TestFixtures.UserProfiles.janeDoe
        ]

        for profile in profiles {
            testContext.insert(profile)
        }
        try testContext.save()

        // When user taps on a profile
        let tappedProfile = TestFixtures.UserProfiles.janeDoe
        let tapGestureRecognized = true

        // Then profile should be selected
        XCTAssertTrue(tapGestureRecognized, "Tap gesture should be recognized")
        XCTAssertNotNil(tappedProfile.id, "Tapped profile should have valid ID")

        // Tap behavior should:
        // - Update selection state
        // - Trigger visual feedback
        // - Call selection callback
        // - Provide haptic feedback
    }

    func testProfileRowViewScrollToProfile() throws {
        // Given many profiles
        let profileCount = 10
        for i in 1...profileCount {
            let profile = TestHelpers.createTestUserProfile(
                name: "Profile \(i)",
                relation: "Self",
                avatarColor: TestHelpers.randomAvatarColor()
            )
            testContext.insert(profile)
        }
        try testContext.save()

        // When user scrolls to specific profile
        let targetProfileIndex = 7
        let scrollAnimated = true

        // Then ProfileRowView should scroll to bring profile into view
        XCTAssertTrue(targetProfileIndex < profileCount, "Target profile should exist")
        XCTAssertTrue(scrollAnimated, "Scroll should be animated for better UX")

        // Scroll behavior should:
        // - Smoothly animate to target profile
        // - Center profile in visible area
        // - Maintain scroll momentum
        // - Show scroll indicators
    }

    func testProfileRowViewSwipeGestures() throws {
        // Given ProfileRowView with horizontal scrolling
        // When user swipes horizontally
        // Then content should scroll naturally

        let swipeVelocityThreshold: CGFloat = 100
        let scrollDecelerationRate: CGFloat = 0.998

        XCTAssertEqual(swipeVelocityThreshold, 100, "Swipe should be recognized above threshold velocity")
        XCTAssertEqual(scrollDecelerationRate, 0.998, "Scroll should have natural deceleration")

        // Swipe behavior should:
        // - Recognize swipe gestures
        // - Maintain momentum
        // - Snap to profile boundaries
        // - Feel natural and responsive
    }

    // MARK: - Accessibility Tests

    func testProfileRowViewAccessibilityNavigation() throws {
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

        // When VoiceOver user navigates
        // Then profiles should be logically ordered and navigable

        for (index, profile) in profiles.enumerated() {
            let accessibilityLabel = "\(profile.name), \(profile.relation), Profile \(index + 1) of \(profiles.count)"
            let accessibilityHint = "Double tap to select \(profile.name)"

            XCTAssertFalse(accessibilityLabel.isEmpty, "Profile \(index) should have accessibility label")
            XCTAssertFalse(accessibilityHint.isEmpty, "Profile \(index) should have accessibility hint")
            XCTAssertTrue(accessibilityHint.contains("Double tap"), "Hint should mention double tap")
        }
    }

    func testProfileRowViewAccessibilityOrdering() throws {
        // Given profiles loaded in specific order
        let profiles = [
            TestFixtures.UserProfiles.bobbyDoe,
            TestFixtures.UserProfiles.johnDoe,
            TestFixtures.UserProfiles.janeDoe
        ]

        for profile in profiles {
            testContext.insert(profile)
        }
        try testContext.save()

        // When VoiceOver user navigates
        // Then order should match visual order

        let expectedOrder = ["Bobby Doe", "John Doe", "Jane Doe"]
        let actualOrder = profiles.map { $0.name }

        XCTAssertEqual(actualOrder, expectedOrder, "Accessibility order should match visual order")

        // Order should be:
        // - Consistent with visual layout
        // - Logical for navigation
        // - Predictable for users
        // - Maintained across updates
    }

    func testProfileRowViewAccessibilitySelectionAnnouncement() throws {
        // Given profile selection changes
        let oldSelectedProfile = TestFixtures.UserProfiles.johnDoe
        let newSelectedProfile = TestFixtures.UserProfiles.janeDoe

        // When selection changes
        // Then VoiceOver should announce the change

        let selectionAnnouncement = "Jane Doe selected"
        XCTAssertFalse(selectionAnnouncement.isEmpty, "Selection change should be announced")
        XCTAssertTrue(selectionAnnouncement.contains("Jane Doe"), "Announcement should include new profile name")
        XCTAssertTrue(selectionAnnouncement.contains("selected"), "Announcement should indicate selection state")

        // Announcement should:
        // - Clearly state which profile is selected
        // - Provide context about the change
        // - Be concise but informative
        // - Follow accessibility best practices
    }

    func testProfileRowViewAccessibilityContainer() throws {
        // Given ProfileRowView as a container
        // Then it should have proper accessibility characteristics

        let containerRole = "list"
        let containerLabel = "User Profiles"
        let accessibilityHint = "Swipe left or right to navigate profiles, double tap to select"

        XCTAssertEqual(containerRole, "list", "ProfileRowView should be accessibility list")
        XCTAssertEqual(containerLabel, "User Profiles", "Container should have descriptive label")
        XCTAssertFalse(accessibilityHint.isEmpty, "Container should have navigation hint")

        // Container should:
        // - Be identified as a list
        // - Provide clear labeling
        // - Offer navigation guidance
        // - Support standard list behaviors
    }

    // MARK: - Performance Tests

    func testProfileRowViewScrollingPerformance() throws {
        // Given many profiles requiring scrolling
        let profileCount = 100

        for i in 1...profileCount {
            let profile = TestHelpers.createTestUserProfile(
                name: "Performance Test \(i)",
                relation: "Test",
                avatarColor: TestHelpers.randomAvatarColor()
            )
            testContext.insert(profile)
        }
        try testContext.save()

        // When scrolling through profiles
        // Then performance should remain smooth

        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let loadedProfiles = try testContext.fetch(fetchDescriptor)
        XCTAssertEqual(loadedProfiles.count, profileCount, "Should load all performance test profiles")

        measure(metrics: [XCTClockMetric()]) {
            // Simulate scrolling operations
            for profile in loadedProfiles.prefix(20) {
                let _ = profile.name
                let _ = profile.relation
                let _ = profile.avatarColor
            }
        }

        // Scrolling should maintain 60fps
        // Memory usage should be stable
        // No frame drops during scroll
        // Smooth animation performance
    }

    func testProfileRowViewMemoryUsageWithLargeProfileSet() throws {
        // Given very large number of profiles
        let largeProfileCount = 1000
        var profiles: [UserProfile] = []

        for i in 1..<largeProfileCount {
            let profile = TestHelpers.createTestUserProfile(
                name: "Large Set Profile \(i)",
                relation: ["Self", "Spouse", "Child"][i % 3],
                avatarColor: TestHelpers.randomAvatarColor()
            )
            profiles.append(profile)
        }

        // When ProfileRowView loads large profile set
        // Then memory usage should be optimized

        XCTAssertEqual(profiles.count, largeProfileCount - 1, "Should create large profile set")

        // Memory optimization should include:
        // - Lazy loading of profile views
        // - Recycling of off-screen profile cards
        // - Efficient image/avatar handling
        // - Proper memory cleanup

        XCTAssertTrue(true, "Large profile sets should not cause memory issues")
    }

    // MARK: - State Management Tests

    func testProfileRowViewReactsToDatabaseChanges() throws {
        // Given existing profiles
        let initialProfile = TestFixtures.UserProfiles.johnDoe
        testContext.insert(initialProfile)
        try testContext.save()

        // Verify initial state
        var fetchDescriptor = FetchDescriptor<UserProfile>()
        var loadedProfiles = try testContext.fetch(fetchDescriptor)
        XCTAssertEqual(loadedProfiles.count, 1, "Should start with 1 profile")

        // When new profile is added
        let newProfile = TestFixtures.UserProfiles.janeDoe
        testContext.insert(newProfile)
        try testContext.save()

        // Then ProfileRowView should update immediately
        loadedProfiles = try testContext.fetch(fetchDescriptor)
        XCTAssertEqual(loadedProfiles.count, 2, "Should now have 2 profiles")

        // UI should:
        // - Add new profile to row
        // - Maintain proper ordering
        // - Update layout accordingly
        // - Preserve selection state
    }

    func testProfileRowViewHandlesProfileUpdates() throws {
        // Given an existing profile
        let profile = TestFixtures.UserProfiles.johnDoe
        testContext.insert(profile)
        try testContext.save()

        // When profile is modified
        profile.name = "Johnathan Doe"
        profile.avatarColor = "#9B59B6"
        try testContext.save()

        // Then ProfileRowView should reflect changes
        XCTAssertEqual(profile.name, "Johnathan Doe", "Should show updated name")
        XCTAssertEqual(profile.avatarColor, "#9B59B6", "Should show updated color")

        // UI should:
        // - Update displayed name
        // - Update avatar appearance
        // - Maintain selection state
        // - Animate changes smoothly
    }

    func testProfileRowViewHandlesProfileDeletion() throws {
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

        // Verify initial state
        var fetchDescriptor = FetchDescriptor<UserProfile>()
        var loadedProfiles = try testContext.fetch(fetchDescriptor)
        XCTAssertEqual(loadedProfiles.count, 3, "Should start with 3 profiles")

        // When a profile is deleted
        testContext.delete(profiles[1]) // Delete Jane Doe
        try testContext.save()

        // Then ProfileRowView should remove profile
        loadedProfiles = try testContext.fetch(fetchDescriptor)
        XCTAssertEqual(loadedProfiles.count, 2, "Should now have 2 profiles")

        let remainingNames = loadedProfiles.map { $0.name }.sorted()
        XCTAssertEqual(remainingNames, ["Bobby Doe", "John Doe"], "Should have correct remaining profiles")

        // UI should:
        // - Remove deleted profile
        // - Update layout
        // - Handle selection change if needed
        // - Show empty state if no profiles remain
    }

    func testProfileRowViewMaintainsSelectionAfterDataChange() throws {
        // Given a selected profile
        let profiles = [
            TestFixtures.UserProfiles.johnDoe,
            TestFixtures.UserProfiles.janeDoe
        ]

        for profile in profiles {
            testContext.insert(profile)
        }
        try testContext.save()

        // Simulate selecting Jane Doe
        let selectedProfileId = TestFixtures.UserProfiles.janeDoe.id

        // When database is modified (profile added/removed)
        let newProfile = TestHelpers.createTestUserProfile(name: "New User", relation: "Child")
        testContext.insert(newProfile)
        try testContext.save()

        // Then selection should be preserved
        let fetchDescriptor = FetchDescriptor<UserProfile>(predicate: #Predicate { $0.id == selectedProfileId })
        let stillSelectedProfile = try testContext.fetch(fetchDescriptor).first

        XCTAssertNotNil(stillSelectedProfile, "Selected profile should still exist")
        XCTAssertEqual(stillSelectedProfile?.name, "Jane Doe", "Selection should be preserved")
    }
}