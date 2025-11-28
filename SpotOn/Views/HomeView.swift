//
//  HomeView.swift
//  SpotOn
//
//  Created by Non on 11/28/25.
//

import SwiftUI
import SwiftData

/// Main home view replacing DebugDashboardView
/// Features profile selection, medical theme, and SwiftData integration
struct HomeView: View {
    // MARK: - SwiftData Properties

    /// Fetch all user profiles from SwiftData
    @Query private var profiles: [UserProfile]

    // MARK: - State Properties

    /// Currently selected profile ID
    @State private var selectedProfileId: UUID?

    /// Currently selected profile object (computed from selectedProfileId)
    @State private var selectedProfile: UserProfile?

    /// Whether to show profile creation flow
    @State private var showingProfileCreation = false

    /// Error state handling
    @State private var errorMessage: String?
    @State private var showingError = false

    // MARK: - Medical Theme Colors

    private let medicalBlue = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
    private let backgroundColor = Color(red: 0.95, green: 0.95, blue: 0.97) // #F2F2F7
    private let cardBackgroundColor = Color.white

    // MARK: - Responsive Design Properties

    /// Detect if device is iPad
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    /// Detect if device is in landscape orientation
    private var isLandscape: Bool {
        UIScreen.main.bounds.width > UIScreen.main.bounds.height
    }

    /// Responsive horizontal padding for main content
    private var contentHorizontalPadding: CGFloat {
        if isIPad {
            return isLandscape ? 40 : 32 // More padding for iPad
        } else {
            return isLandscape ? 20 : 16 // Standard iPhone padding
        }
    }

    /// Responsive spacing between sections
    private var sectionSpacing: CGFloat {
        if isIPad {
            return isLandscape ? 32 : 24 // More spacing on iPad
        } else {
            return isLandscape ? 20 : 16 // Compact spacing on iPhone
        }
    }

    /// Navigation style based on device type and orientation
    private var shouldUseDoubleColumn: Bool {
        isIPad && isLandscape
    }

    /// Check if any profiles exist
    private var hasProfiles: Bool {
        !profiles.isEmpty
    }

    /// Get selected profile from profiles array
    private var selectedUserProfile: UserProfile? {
        profiles.first { $0.id == selectedProfileId }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if hasProfiles {
                        // Profile selection section
                        profileSection

                        // Main content area
                        mainContentSection
                    } else {
                        // Empty state when no profiles exist
                        EmptyStateView(onCreateProfile: createProfile)
                    }
                }
            }
            .navigationTitle("SpotOn")
            .navigationBarTitleDisplayMode(isIPad && isLandscape ? .inline : .large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if hasProfiles {
                        Button(action: createProfile) {
                            Image(systemName: "plus")
                                .font(.system(size: isIPad ? 20 : 18, weight: .medium))
                        }
                        .accessibilityLabel("Add new profile")
                        .accessibilityHint("Create a new user profile")
                    }
                }
            }
            .onAppear {
                setupInitialState()
            }
            .onChange(of: profiles) { _, newProfiles in
                handleProfilesChange(newProfiles)
            }
            .onChange(of: selectedProfileId) { _, newProfileId in
                updateSelectedProfile(newProfileId)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - View Components

    /// Profile selection section at the top of the view
    private var profileSection: some View {
        VStack(spacing: 0) {
            ProfileRowView(
                profiles: profiles,
                selectedProfileId: $selectedProfileId,
                onProfileSelected: { profile in
                    selectedProfile = profile
                }
            )
            .padding(.horizontal, contentHorizontalPadding)
            .padding(.top, isIPad ? 12 : 8)

            Divider()
                .padding(.vertical, sectionSpacing)
                .background(backgroundColor)
        }
    }

    /// Main content section showing selected profile information
    private var mainContentSection: some View {
        ScrollView {
            VStack(spacing: sectionSpacing) {
                if let profile = selectedUserProfile {
                    // Selected profile information card
                    selectedProfileCard(profile: profile)

                    // Spots summary section
                    spotsSummarySection(profile: profile)

                    // Recent activity section
                    recentActivitySection(profile: profile)

                    // Quick actions section
                    quickActionsSection(profile: profile)
                } else {
                    // Fallback state if no profile is selected
                    noProfileSelectedView
                }

                Spacer(minLength: isIPad ? 60 : 40)
            }
            .padding(.horizontal, contentHorizontalPadding)
            .padding(.top, isIPad ? 12 : 8)
        }
        .accessibilityIdentifier("homeViewMainContent")
    }

    /// Card displaying selected profile information
    private func selectedProfileCard(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(profile.name.isEmpty ? "Unnamed Profile" : profile.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)

                    Text(profile.relation.isEmpty ? "Family Member" : profile.relation)
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Profile avatar
                ZStack {
                    Circle()
                        .fill(Color(hex: profile.avatarColor) ?? .blue)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .strokeBorder(cardBackgroundColor, lineWidth: 2)
                        )

                    Text(String(profile.name.prefix(1)).uppercased())
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            // Profile creation date
            Text("Created \(profile.createdAt, style: .relative) ago")
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .accessibilityIdentifier("selectedProfileCard")
    }

    /// Spots summary section for the selected profile
    private func spotsSummarySection(profile: UserProfile) -> some View {
        SpotListView(
            selectedProfileId: profile.id,
            onSpotTap: { spot in
                // Prepare for future navigation to SpotDetailView (Task 2.4)
                print("Spot tapped: \(spot.title) - Navigation will be implemented in Task 2.4")
            },
            onAddSpot: {
                // Prepare for future add spot functionality (Task 2.3)
                print("Add spot tapped - Will be implemented in Task 2.3")
            }
        )
        .accessibilityIdentifier("spotsSummarySection")
    }

    /// Recent activity section for the selected profile
    private func recentActivitySection(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)

            // Placeholder for recent activity - will be implemented in future tasks
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))

                    Text("No recent activity")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.secondary)

                    Spacer()
                }

                Text("Activity will appear here as you track and update medical spots.")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(backgroundColor)
            )
        }
        .accessibilityIdentifier("recentActivitySection")
    }

    /// Quick actions section for common tasks
    private func quickActionsSection(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Add Spot button
                QuickActionButton(
                    title: "Add Spot",
                    icon: "plus.circle.fill",
                    color: medicalBlue,
                    action: {
                        // Will be implemented in future tasks
                        print("Add spot tapped for \(profile.name)")
                    }
                )

                // Camera button
                QuickActionButton(
                    title: "Take Photo",
                    icon: "camera.fill",
                    color: .green,
                    action: {
                        // Will be implemented in future tasks
                        print("Camera tapped for \(profile.name)")
                    }
                )

                // View All Spots button
                QuickActionButton(
                    title: "All Spots",
                    icon: "list.bullet",
                    color: .orange,
                    action: {
                        // Will be implemented in future tasks
                        print("View all spots tapped for \(profile.name)")
                    }
                )

                // Doctor Summary button
                QuickActionButton(
                    title: "Doctor View",
                    icon: "stethoscope",
                    color: .red,
                    action: {
                        // Will be implemented in future tasks
                        print("Doctor summary tapped for \(profile.name)")
                    }
                )
            }
        }
        .accessibilityIdentifier("quickActionsSection")
    }

    /// View shown when no profile is selected (fallback state)
    private var noProfileSelectedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.secondary)

            Text("No Profile Selected")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)

            Text("Please select a profile from the options above to view their medical tracking information.")
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .accessibilityIdentifier("noProfileSelectedView")
    }

    // MARK: - Helper Methods

    /// Set up initial state when view appears
    private func setupInitialState() {
        // Auto-select first profile if no selection exists
        if selectedProfileId == nil, let firstProfile = profiles.first {
            selectedProfileId = firstProfile.id
            selectedProfile = firstProfile
        }
    }

    /// Handle changes to the profiles array
    private func handleProfilesChange(_ newProfiles: [UserProfile]) {
        if let selectedId = selectedProfileId {
            // Check if selected profile still exists
            let selectedExists = newProfiles.contains { $0.id == selectedId }

            if !selectedExists {
                // Select first available profile if current selection no longer exists
                if let firstProfile = newProfiles.first {
                    selectedProfileId = firstProfile.id
                    selectedProfile = firstProfile
                }
            }
        } else {
            // Auto-select first profile if no selection and profiles exist
            if let firstProfile = newProfiles.first {
                selectedProfileId = firstProfile.id
                selectedProfile = firstProfile
            }
        }
    }

    /// Update selected profile when selection changes
    private func updateSelectedProfile(_ profileId: UUID?) {
        selectedProfile = profiles.first { $0.id == profileId }
    }

    /// Handle profile creation
    private func createProfile() {
        // TODO: Implement profile creation flow
        // This will be implemented in a future task
        showingProfileCreation = true
        print("Profile creation requested - will be implemented in future task")
    }
}

// MARK: - Quick Action Button Component

/// Quick action button for common tasks
private struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .accessibilityLabel(title)
        .accessibilityHint("Tap to \(title.lowercased())")
    }
}

// MARK: - Preview

#Preview("With Profiles") {
    // Create sample profiles for preview
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
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        )
    ]

    return HomeView()
        .modelContainer(for: UserProfile.self, inMemory: true)
        .onAppear {
            // Add sample profiles for preview
            // This would typically be handled by the test setup
        }
}

#Preview("Empty State") {
    HomeView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}

