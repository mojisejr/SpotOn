//
//  ProfileRowView.swift
//  SpotOn
//
//  Created by Non on 11/28/25.
//

import SwiftUI

/// Horizontal scrolling row of profile cards with selection management
/// Features medical theme, smooth scrolling, and accessibility support
struct ProfileRowView: View {
    // MARK: - Properties

    /// Array of user profiles to display
    let profiles: [UserProfile]

    /// Currently selected profile ID
    @Binding var selectedProfileId: UUID?

    /// Callback when profile selection changes
    let onProfileSelected: (UserProfile) -> Void

    // MARK: - Medical Theme Colors

    private let medicalBlue = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
    private let backgroundColor = Color(red: 0.95, green: 0.95, blue: 0.97) // #F2F2F7

    // MARK: - Computed Properties

    /// Check if any profiles exist
    private var hasProfiles: Bool {
        !profiles.isEmpty
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            profileHeader
            profileContent
        }
        .onAppear {
            setupInitialSelection()
        }
        .onChange(of: profiles) { _, newProfiles in
            handleProfilesChange(newProfiles)
        }
    }

    // MARK: - View Components

    private var profileHeader: some View {
        Group {
            if hasProfiles {
                HStack {
                    Text("Select Profile")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .accessibilityIdentifier("profileRowViewTitle")
                        .accessibilityAddTraits(.isHeader)

                    Spacer()

                    Text("\(profiles.count) \(profiles.count == 1 ? "Profile" : "Profiles")")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.secondary)
                        .accessibilityLabel("\(profiles.count) profiles available")
                }
            }
        }
    }

    private var profileContent: some View {
        Group {
            if hasProfiles {
                profileScrollView
            } else {
                emptyProfileState
            }
        }
    }

    private var profileScrollView: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 12) {
                ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                    profileCard(for: profile, at: index)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .frame(height: 140)
        .background(backgroundColor.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityIdentifier("profileRowView")
        .accessibilityElement(children: .contain)
        .accessibilityLabel("User Profiles")
        .accessibilityHint("Swipe left or right to navigate profiles, double tap to select")
    }

    private func profileCard(for profile: UserProfile, at index: Int) -> some View {
        ProfileCardView(
            profile: profile,
            isSelected: profile.id == selectedProfileId,
            onTap: {
                selectProfile(profile)
            }
        )
        .accessibilityLabel("\(profile.name), \(profile.relation), Profile \(index + 1) of \(profiles.count)")
        .accessibilityHint("Double tap to select \(profile.name)")
    }

    private var emptyProfileState: some View {
        HStack {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.secondary)

            Text("No profiles available")
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 20)
        .background(backgroundColor.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Helper Methods

    private func selectProfile(_ profile: UserProfile) {
        selectedProfileId = profile.id
        onProfileSelected(profile)

        // Provide haptic feedback on selection
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    private func setupInitialSelection() {
        if selectedProfileId == nil, let firstProfile = profiles.first {
            selectedProfileId = firstProfile.id
            onProfileSelected(firstProfile)
        }
    }

    private func handleProfilesChange(_ newProfiles: [UserProfile]) {
        if let selectedId = selectedProfileId {
            let selectedProfileExists = newProfiles.contains { $0.id == selectedId }
            if !selectedProfileExists {
                if let firstProfile = newProfiles.first {
                    selectedProfileId = firstProfile.id
                    onProfileSelected(firstProfile)
                }
            }
        } else {
            if let firstProfile = newProfiles.first {
                selectedProfileId = firstProfile.id
                onProfileSelected(firstProfile)
            }
        }
    }
}

// MARK: - Preview

#Preview("With Profiles") {
    let profiles = [
        UserProfile(
            id: UUID(),
            name: "John Doe",
            relation: "Self",
            avatarColor: "#FF6B6B",
            createdAt: Date()
        ),
        UserProfile(
            id: UUID(),
            name: "Jane Doe",
            relation: "Spouse",
            avatarColor: "#4ECDC4",
            createdAt: Date()
        ),
        UserProfile(
            id: UUID(),
            name: "Bobby Doe",
            relation: "Child",
            avatarColor: "#45B7D1",
            createdAt: Date()
        ),
        UserProfile(
            id: UUID(),
            name: "Sarah Doe",
            relation: "Child",
            avatarColor: "#9B59B6",
            createdAt: Date()
        )
    ]

    return ProfileRowView(
        profiles: profiles,
        selectedProfileId: .constant(profiles.first!.id),
        onProfileSelected: { profile in
            print("Selected: \(profile.name)")
        }
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("No Profiles") {
    ProfileRowView(
        profiles: [],
        selectedProfileId: .constant(nil),
        onProfileSelected: { profile in
            print("Selected: \(profile.name)")
        }
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Single Profile") {
    let singleProfile = UserProfile(
        id: UUID(),
        name: "John Doe",
        relation: "Self",
        avatarColor: "#FF6B6B",
        createdAt: Date()
    )

    return ProfileRowView(
        profiles: [singleProfile],
        selectedProfileId: .constant(singleProfile.id),
        onProfileSelected: { profile in
            print("Selected: \(profile.name)")
        }
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}