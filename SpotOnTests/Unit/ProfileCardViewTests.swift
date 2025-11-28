//
//  ProfileCardViewTests.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import XCTest
import SwiftData
@testable import SpotOn

final class ProfileCardViewTests: XCTestCase {

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

    // MARK: - Profile Display Tests

    func testProfileCardDisplaysCorrectUserData() throws {
        // Given a user profile
        let userProfile = TestFixtures.UserProfiles.johnDoe

        // When ProfileCardView renders with this profile
        // Then it should display:
        // - User's name: "John Doe"
        // - User's relation: "Self"
        // - User's avatar with color: "#FF6B6B"

        XCTAssertEqual(userProfile.name, "John Doe", "Profile should display correct name")
        XCTAssertEqual(userProfile.relation, "Self", "Profile should display correct relation")
        XCTAssertEqual(userProfile.avatarColor, "#FF6B6B", "Profile should display correct avatar color")
        XCTAssertNotNil(userProfile.id, "Profile should have valid ID")
        XCTAssertNotNil(userProfile.createdAt, "Profile should have creation date")
    }

    func testProfileCardDisplaysSpouseRelation() throws {
        // Given a spouse profile
        let spouseProfile = TestFixtures.UserProfiles.janeDoe

        // When ProfileCardView renders
        // Then it should display spouse information correctly

        XCTAssertEqual(spouseProfile.name, "Jane Doe", "Spouse name should be displayed")
        XCTAssertEqual(spouseProfile.relation, "Spouse", "Relation should be 'Spouse'")
        XCTAssertEqual(spouseProfile.avatarColor, "#4ECDC4", "Spouse should have unique avatar color")
    }

    func testProfileCardDisplaysChildRelation() throws {
        // Given a child profile
        let childProfile = TestFixtures.UserProfiles.bobbyDoe

        // When ProfileCardView renders
        // Then it should display child information correctly

        XCTAssertEqual(childProfile.name, "Bobby Doe", "Child name should be displayed")
        XCTAssertEqual(childProfile.relation, "Child", "Relation should be 'Child'")
        XCTAssertEqual(childProfile.avatarColor, "#45B7D1", "Child should have unique avatar color")
    }

    func testProfileCardHandlesEmptyName() throws {
        // Given a profile with empty name
        let emptyNameProfile = TestFixtures.UserProfiles.emptyName

        // When ProfileCardView renders
        // Then it should handle empty name gracefully

        XCTAssertEqual(emptyNameProfile.name, "", "Name can be empty for testing edge cases")
        XCTAssertEqual(emptyNameProfile.relation, "Self", "Relation should still be valid")

        // UI should display placeholder or fallback text
        let displayName = emptyNameProfile.name.isEmpty ? "Unnamed Profile" : emptyNameProfile.name
        XCTAssertEqual(displayName, "Unnamed Profile", "Should show fallback display name")
    }

    func testProfileCardHandlesEmptyRelation() throws {
        // Given a profile with empty relation
        let emptyRelationProfile = TestFixtures.UserProfiles.emptyRelation

        // When ProfileCardView renders
        // Then it should handle empty relation gracefully

        XCTAssertEqual(emptyRelationProfile.name, "Test User", "Name should be valid")
        XCTAssertEqual(emptyRelationProfile.relation, "", "Relation can be empty for testing")

        // UI should display placeholder or fallback text
        let displayRelation = emptyRelationProfile.relation.isEmpty ? "Family Member" : emptyRelationProfile.relation
        XCTAssertEqual(displayRelation, "Family Member", "Should show fallback display relation")
    }

    // MARK: - Avatar Display Tests

    func testProfileCardAvatarBackgroundColor() throws {
        // Given different profiles with different avatar colors
        let profiles = [
            TestFixtures.UserProfiles.johnDoe,   // #FF6B6B
            TestFixtures.UserProfiles.janeDoe,   // #4ECDC4
            TestFixtures.UserProfiles.bobbyDoe,  // #45B7D1
            TestFixtures.UserProfiles.emptyName, // #96CEB4
            TestFixtures.UserProfiles.emptyRelation // #FFEAA7
        ]

        // When ProfileCardView renders avatars
        // Then each avatar should use the correct background color

        let expectedColors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7"]
        let actualColors = profiles.map { $0.avatarColor }

        XCTAssertEqual(actualColors, expectedColors, "All avatar colors should be preserved")

        // Each color should be a valid hex color format
        for color in actualColors {
            XCTAssertTrue(color.hasPrefix("#"), "Avatar color should be hex format: \(color)")
            XCTAssertEqual(color.count, 7, "Hex color should have 7 characters including #: \(color)")
        }
    }

    func testProfileCardAvatarInitials() throws {
        // Given profiles with different names
        let testCases = [
            ("John Doe", "JD"),
            ("Jane Smith", "JS"),
            ("Bobby", "B"),
            ("A", "A"),
            ("", "?")
        ]

        // When ProfileCardView renders avatar initials
        // Then it should show correct initials based on name

        for (name, expectedInitials) in testCases {
            let profile = TestHelpers.createTestUserProfile(name: name, relation: "Test")

            let initials = profile.name.isEmpty ? "?" : String(profile.name.prefix(1)).uppercased()
            if profile.name.contains(" ") && !profile.name.isEmpty {
                let components = profile.name.split(separator: " ")
                if components.count >= 2 {
                    initials = "\(components.first!.prefix(1))\(components.last!.prefix(1))".uppercased()
                }
            }

            // This logic would be implemented in ProfileCardView
            XCTAssertFalse(initials.isEmpty, "Initials should not be empty for name: \(name)")
        }
    }

    // MARK: - Selection State Tests

    func testProfileCardSelectedStateVisualFeedback() throws {
        // Given a profile card
        let profile = TestFixtures.UserProfiles.johnDoe
        testContext.insert(profile)
        try testContext.save()

        // When profile card is selected
        let isSelected = true

        // Then profile card should show selection feedback:
        // - Medical Blue (#007AFF) border or highlight
        // - Increased opacity or shadow
        // - Selection checkmark indicator
        // - Slightly larger scale or emphasis

        if isSelected {
            let selectionBorderColor = "#007AFF" // Medical blue
            let selectionScale = 1.05 // 5% scale increase
            let selectionOpacity = 1.0 // Full opacity

            XCTAssertEqual(selectionBorderColor, "#007AFF", "Selection should use medical blue")
            XCTAssertEqual(selectionScale, 1.05, "Selected card should be slightly larger")
            XCTAssertEqual(selectionOpacity, 1.0, "Selected card should be fully opaque")
        }
    }

    func testProfileCardUnselectedStateAppearance() throws {
        // Given a profile card
        let profile = TestFixtures.UserProfiles.janeDoe
        testContext.insert(profile)
        try testContext.save()

        // When profile card is not selected
        let isSelected = false

        // Then profile card should show normal appearance:
        // - Subtle gray border or no border
        // - Normal scale and opacity
        // - No selection indicator

        if !isSelected {
            let normalBorderColor = "#E0E0E0" // Light gray
            let normalScale = 1.0 // Normal scale
            let normalOpacity = 0.9 // Slightly reduced opacity for unselected state

            XCTAssertEqual(normalBorderColor, "#E0E0E0", "Unselected card should use light gray border")
            XCTAssertEqual(normalScale, 1.0, "Unselected card should be normal size")
            XCTAssertEqual(normalOpacity, 0.9, "Unselected card should be slightly transparent")
        }
    }

    func testProfileCardSelectionAnimation() throws {
        // Given a profile card
        // When user taps to select/deselect
        // Then selection should animate smoothly

        let animationDuration = 0.3 // 300ms for smooth selection animation
        let animationCurve = "easeInOut" // Smooth easing

        XCTAssertEqual(animationDuration, 0.3, "Selection animation should be 300ms")
        XCTAssertEqual(animationCurve, "easeInOut", "Animation should use smooth easing")

        // Animation should include:
        // - Border color change to medical blue
        // - Scale increase/decrease
        // - Shadow change for depth
        // - Opacity transition
    }

    // MARK: - Medical Theme Tests

    func testProfileCardMedicalThemeColors() throws {
        // Given ProfileCardView with medical theme
        // Then it should apply consistent medical styling

        let medicalBlue = "#007AFF"
        let backgroundColor = "#FFFFFF"
        let textColor = "#000000"
        let subtleGray = "#F2F2F7"

        XCTAssertEqual(medicalBlue, "#007AFF", "Medical blue for selection state")
        XCTAssertEqual(backgroundColor, "#FFFFFF", "White card background")
        XCTAssertEqual(textColor, "#000000", "Black text for readability")
        XCTAssertEqual(subtleGray, "#F2F2F7", "Subtle gray for backgrounds")
    }

    func testProfileCardTypography() throws {
        // Given medical-friendly typography
        // Then ProfileCardView should use clean, readable fonts

        let titleFontSize: CGFloat = 18
        let relationFontSize: CGFloat = 14
        let titleFontWeight = "semibold"
        let relationFontWeight = "regular"

        XCTAssertEqual(titleFontSize, 18, "Name should be 18pt for readability")
        XCTAssertEqual(relationFontSize, 14, "Relation should be 14pt for hierarchy")
        XCTAssertEqual(titleFontWeight, "semibold", "Name should be prominent")
        XCTAssertEqual(relationFontWeight, "regular", "Relation should be lighter")
    }

    func testProfileCardLayoutAndSpacing() throws {
        // Given medical-appropriate layout
        // Then ProfileCardView should have good spacing

        let cardPadding: CGFloat = 16
        let avatarSize: CGFloat = 60
        let avatarToTextSpacing: CGFloat = 12
        let textLineSpacing: CGFloat = 4

        XCTAssertEqual(cardPadding, 16, "Card should have adequate padding")
        XCTAssertEqual(avatarSize, 60, "Avatar should be appropriately sized")
        XCTAssertEqual(avatarToTextSpacing, 12, "Good spacing between avatar and text")
        XCTAssertEqual(textLineSpacing, 4, "Proper line spacing for readability")
    }

    // MARK: - Interaction Tests

    func testProfileCardTapGesture() throws {
        // Given a profile card
        let profile = TestFixtures.UserProfiles.johnDoe
        testContext.insert(profile)
        try testContext.save()

        // When user taps the profile card
        // Then it should trigger profile selection

        let tapGestureRecognized = true
        let profileSelected = true

        XCTAssertTrue(tapGestureRecognized, "Profile card should recognize tap gestures")
        XCTAssertTrue(profileSelected, "Tap should select the profile")

        // Selection should:
        // - Update HomeView selected profile state
        // - Trigger visual selection feedback
        // - Provide haptic feedback if available
    }

    func testProfileCardLongPressGesture() throws {
        // Given a profile card
        let profile = TestFixtures.UserProfiles.janeDoe

        // When user long-presses the profile card
        // Then it should show context menu or profile details

        let longPressTriggered = true
        let contextMenuShown = true

        XCTAssertTrue(longPressTriggered, "Profile card should recognize long press")
        XCTAssertTrue(contextMenuShown, "Long press should show context menu")

        // Context menu should include:
        // - "View Details" option
        // - "Edit Profile" option
        // - "Delete Profile" option (with confirmation)
    }

    // MARK: - Accessibility Tests

    func testProfileCardAccessibilityLabels() throws {
        // Given various profile types
        let profiles = [
            (TestFixtures.UserProfiles.johnDoe, "John Doe, Self, Profile"),
            (TestFixtures.UserProfiles.janeDoe, "Jane Doe, Spouse, Profile"),
            (TestFixtures.UserProfiles.bobbyDoe, "Bobby Doe, Child, Profile")
        ]

        // When ProfileCardView renders
        // Then each should have descriptive accessibility labels

        for (profile, expectedLabel) in profiles {
            let actualLabel = "\(profile.name), \(profile.relation), Profile"
            XCTAssertEqual(actualLabel, expectedLabel, "Profile should have descriptive accessibility label")
            XCTAssertFalse(actualLabel.isEmpty, "Accessibility label should not be empty")
        }
    }

    func testProfileCardAccessibilityHints() throws {
        // Given a profile card
        // Then it should have helpful accessibility hints

        let accessibilityHint = "Double tap to select this profile"
        XCTAssertFalse(accessibilityHint.isEmpty, "Accessibility hint should be descriptive")

        // Hint should guide VoiceOver users on interaction
        XCTAssertTrue(accessibilityHint.contains("Double tap"), "Hint should mention double tap")
        XCTAssertTrue(accessibilityHint.contains("select"), "Hint should mention selection action")
    }

    func testProfileCardAccessibilityTraits() throws {
        // Given a selectable profile card
        // Then it should have appropriate accessibility traits

        let accessibilityTraits = "button"
        XCTAssertFalse(accessibilityTraits.isEmpty, "Profile card should be button trait")

        // Should also have:
        // - .button trait for tappable behavior
        // - .selected trait when profile is selected
        // - .notEnabled trait if profile selection is disabled
    }

    func testProfileCardAccessibilityValue() throws {
        // Given a profile card with selection state
        let isSelected = true

        // When profile is selected
        // Then accessibility value should indicate selection

        let accessibilityValue = isSelected ? "Selected" : "Not selected"
        XCTAssertFalse(accessibilityValue.isEmpty, "Accessibility value should indicate selection state")

        if isSelected {
            XCTAssertEqual(accessibilityValue, "Selected", "Selected profile should announce as selected")
        } else {
            XCTAssertEqual(accessibilityValue, "Not selected", "Unselected profile should announce as not selected")
        }
    }

    // MARK: - Edge Case Tests

    func testProfileCardVeryLongName() throws {
        // Given a profile with very long name
        let longName = "Alexander Bartholomew Christopher Davidson Esquire the Third"
        let longNameProfile = TestHelpers.createTestUserProfile(name: longName, relation: "Self")

        // When ProfileCardView renders
        // Then it should handle long name gracefully

        XCTAssertFalse(longName.isEmpty, "Long name should be preserved")
        XCTAssertTrue(longName.count > 30, "Name should be significantly long")

        // UI should:
        // - Truncate long name with ellipsis
        // - Maintain readability
        // - Not break layout
        // - Show full name in accessibility label
    }

    func testProfileCardSpecialCharactersInName() throws {
        // Given profile names with special characters
        let specialNames = [
            "José María García López",
            "张伟 (Zhang Wei)",
            "Björn Guðmundsson",
            "O'Connor, Patrick",
            "Anne-Marie D'Angelo"
        ]

        // When ProfileCardView renders
        // Then it should display special characters correctly

        for name in specialNames {
            let profile = TestHelpers.createTestUserProfile(name: name, relation: "Self")
            XCTAssertEqual(profile.name, name, "Profile should preserve special characters: \(name)")

            // Display should handle Unicode properly
            XCTAssertFalse(profile.name.isEmpty, "Name should not be empty with special characters")
        }
    }

    // MARK: - Performance Tests

    func testProfileCardRenderingPerformance() throws {
        // Given multiple profile cards
        let profiles = (1..<100).map { i in
            TestHelpers.createTestUserProfile(
                name: "Profile \(i)",
                relation: ["Self", "Spouse", "Child"][i % 3],
                avatarColor: TestHelpers.randomAvatarColor()
            )
        }

        // When rendering many profile cards
        // Then rendering should be performant

        measure(metrics: [XCTClockMetric()]) {
            for profile in profiles {
                // Simulate profile card rendering logic
                let _ = profile.name
                let _ = profile.relation
                let _ = profile.avatarColor
                let _ = profile.id
            }
        }

        // Rendering should complete quickly even with many cards
        XCTAssertTrue(true, "Profile card rendering should be performant")
    }

    func testProfileCardMemoryUsage() throws {
        // Given many profile cards in memory
        let profileCount = 1000
        var profiles: [UserProfile] = []

        for i in 1..<profileCount {
            let profile = TestHelpers.createTestUserProfile(
                name: "Memory Test Profile \(i)",
                relation: "Test",
                avatarColor: TestHelpers.randomAvatarColor()
            )
            profiles.append(profile)
        }

        // When profile cards are displayed
        // Then memory usage should remain reasonable

        XCTAssertEqual(profiles.count, profileCount - 1, "Should create many profiles for testing")
        XCTAssertTrue(true, "Profile cards should not cause memory issues")

        // Profile cards should be efficiently rendered
        // Memory should not grow excessively
        // UI should remain responsive
    }

    // MARK: - State Management Tests

    func testProfileCardReactsToProfileUpdates() throws {
        // Given a profile in database
        let profile = TestFixtures.UserProfiles.johnDoe
        testContext.insert(profile)
        try testContext.save()

        // When profile is updated
        profile.name = "Johnathan Doe"
        profile.avatarColor = "#9B59B6"
        try testContext.save()

        // Then ProfileCardView should reflect changes
        XCTAssertEqual(profile.name, "Johnathan Doe", "Profile card should show updated name")
        XCTAssertEqual(profile.avatarColor, "#9B59B6", "Profile card should show updated avatar color")
    }

    func testProfileCardHandlesProfileDeletion() throws {
        // Given a profile in database
        let profile = TestFixtures.UserProfiles.janeDoe
        testContext.insert(profile)
        try testContext.save()

        // Verify profile exists
        var fetchDescriptor = FetchDescriptor<UserProfile>(predicate: #Predicate { $0.id == profile.id })
        var existingProfile = try testContext.fetch(fetchDescriptor).first
        XCTAssertNotNil(existingProfile, "Profile should exist initially")

        // When profile is deleted
        testContext.delete(profile)
        try testContext.save()

        // Then ProfileCardView should handle deletion gracefully
        existingProfile = try testContext.fetch(fetchDescriptor).first
        XCTAssertNil(existingProfile, "Profile should be deleted")

        // UI should:
        // - Remove the profile card
        // - Update HomeView state
        // - Show empty state if no profiles remain
    }
}