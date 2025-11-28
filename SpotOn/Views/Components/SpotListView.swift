//
//  SpotListView.swift
//  SpotOn
//
//  Created by Non on 11/28/25.
//

import SwiftUI
import SwiftData

/// Dedicated view for managing and displaying spot lists
/// Features filtered @Query, empty states, and medical theme styling
struct SpotListView: View {
    // MARK: - Properties

    /// Currently selected profile ID for filtering spots
    let selectedProfileId: UUID?

    /// Optional callback when spot is tapped
    let onSpotTap: ((Spot) -> Void)?

    /// Optional callback for add spot action
    let onAddSpot: (() -> Void)?

    // MARK: - SwiftData Query

    /// Filtered spots for the selected profile using @Query
    @Query(filter: #Predicate<Spot> { spot in
        spot.userProfile?.id != nil
    }, sort: \Spot.createdAt, order: .reverse)
    private var allSpots: [Spot]

    // MARK: - Computed Properties

    /// Filtered spots for the selected profile
    private var filteredSpots: [Spot] {
        guard let selectedId = selectedProfileId else {
            return []
        }
        return allSpots.filter { $0.userProfile?.id == selectedId }
    }

    /// Check if there are spots to display
    private var hasSpots: Bool {
        !filteredSpots.isEmpty
    }

    /// Count of spots for the selected profile
    private var spotCount: Int {
        filteredSpots.count
    }

    /// Detect if device is iPad
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    // MARK: - Medical Theme Colors

    private let medicalBlue = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
    private let backgroundColor = Color(red: 0.95, green: 0.95, blue: 0.97) // #F2F2F7
    private let cardBackgroundColor = Color.white
    private let textColor = Color.primary
    private let subtitleColor = Color.secondary

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if hasSpots {
                // Spots list view
                spotsListSection
            } else {
                // Empty state view
                emptyStateSection
            }
        }
        .background(backgroundColor)
        .accessibilityIdentifier("spotListView")
    }

    // MARK: - View Components

    private var spotsListSection: some View {
        VStack(spacing: 0) {
            // Header with count and add button
            spotsListHeader

            // Spots list
            spotsList
        }
    }

    private var spotsListHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Medical Spots")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)

                Text("\(spotCount) \(spotCount == 1 ? "Spot" : "Spots")")
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(subtitleColor)
                    .accessibilityLabel("\(spotCount) spots tracked")
            }

            Spacer()

            // Add spot button
            if let onAddSpot = onAddSpot {
                Button(action: onAddSpot) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(medicalBlue)
                        )
                }
                .accessibilityLabel("Add new spot")
                .accessibilityHint("Tap to add a new medical spot")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(cardBackgroundColor)
        .accessibilityElement(children: .contain)
    }

    private var spotsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredSpots, id: \.id) { spot in
                    SpotCardView(
                        spot: spot,
                        onTap: {
                            onSpotTap?(spot)
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(cardBackgroundColor)
                    .accessibilityIdentifier("spotCard_\(spot.id)")
                }
            }
        }
        .accessibilityIdentifier("spotsScrollView")
    }

    private var emptyStateSection: some View {
        EmptyStateView(
            configuration: .noSpots,
            onPrimaryAction: onAddSpot,
            onSecondaryAction: {
                // Handle learn more action - could show help or tutorial
                print("Learn more about spot tracking")
            }
        )
        .background(backgroundColor)
    }
}

// MARK: - Extensions

extension SpotListView {
    /// Initialize with selected profile ID and optional callbacks
    init(selectedProfileId: UUID?, onSpotTap: ((Spot) -> Void)? = nil, onAddSpot: (() -> Void)? = nil) {
        self.selectedProfileId = selectedProfileId
        self.onSpotTap = onSpotTap
        self.onAddSpot = onAddSpot
    }

    /// Initialize without selected profile (shows empty state)
    init() {
        self.selectedProfileId = nil
        self.onSpotTap = nil
        self.onAddSpot = nil
    }
}

// MARK: - Preview Helpers

extension Spot {
    /// Create sample spot for preview
    static func sampleSpot(
        id: UUID = UUID(),
        title: String = "Sample Spot",
        bodyPart: String = "Arm",
        isActive: Bool = true,
        createdAt: Date = Date(),
        userProfile: UserProfile? = nil
    ) -> Spot {
        Spot(
            id: id,
            title: title,
            bodyPart: bodyPart,
            isActive: isActive,
            createdAt: createdAt,
            userProfile: userProfile
        )
    }
}

// MARK: - Preview

#Preview("With Spots") {
    @State var isPresented = false

    // Create sample data container
    let container = try! ModelContainer(
        for: UserProfile.self, Spot.self, LogEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    // Create sample user profile
    let userProfile = UserProfile(
        id: UUID(),
        name: "John Doe",
        relation: "Self",
        avatarColor: "#FF6B6B",
        createdAt: Date()
    )

    // Create sample spots
    let spot1 = Spot.sampleSpot(
        title: "Left Arm Mole",
        bodyPart: "Arm",
        isActive: true,
        createdAt: Date(),
        userProfile: userProfile
    )

    let spot2 = Spot.sampleSpot(
        title: "Back Rash",
        bodyPart: "Back",
        isActive: false,
        createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
        userProfile: userProfile
    )

    let spot3 = Spot.sampleSpot(
        title: "Knee Scar",
        bodyPart: "Knee",
        isActive: true,
        createdAt: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
        userProfile: userProfile
    )

    // Insert sample data
    let context = container.mainContext
    context.insert(userProfile)
    context.insert(spot1)
    context.insert(spot2)
    context.insert(spot3)
    try! context.save()

    return NavigationView {
        SpotListView(
            selectedProfileId: userProfile.id,
            onSpotTap: { spot in
                print("Spot tapped: \(spot.title)")
            },
            onAddSpot: {
                isPresented = true
            }
        )
        .navigationTitle("SpotOn")
        .sheet(isPresented: $isPresented) {
            AddSpotView(
                isPresented: $isPresented,
                userProfile: userProfile
            )
        }
    }
    .modelContainer(container)
}

#Preview("Empty State") {
    @State var isPresented = false

    // Create empty container
    let container = try! ModelContainer(
        for: UserProfile.self, Spot.self, LogEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let userProfile = UserProfile(
        id: UUID(),
        name: "Test User",
        relation: "Self",
        avatarColor: "#FF6B6B",
        createdAt: Date()
    )

    return NavigationView {
        SpotListView(
            selectedProfileId: userProfile.id,
            onAddSpot: {
                isPresented = true
            }
        )
        .navigationTitle("SpotOn")
        .sheet(isPresented: $isPresented) {
            AddSpotView(
                isPresented: $isPresented,
                userProfile: userProfile
            )
        }
    }
    .modelContainer(container)
}

#Preview("No Profile Selected") {
    // Create empty container
    let container = try! ModelContainer(
        for: UserProfile.self, Spot.self, LogEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    return NavigationView {
        SpotListView()
            .navigationTitle("SpotOn")
    }
    .modelContainer(container)
}

#Preview("iPad Layout") {
    @State var isPresented = false

    // Create sample data container
    let container = try! ModelContainer(
        for: UserProfile.self, Spot.self, LogEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    // Create sample user profile
    let userProfile = UserProfile(
        id: UUID(),
        name: "Test User",
        relation: "Self",
        avatarColor: "#4ECDC4",
        createdAt: Date()
    )

    // Create many spots for iPad layout testing
    let spots = (0..<10).map { index in
        Spot.sampleSpot(
            title: "Spot \(index + 1)",
            bodyPart: ["Arm", "Leg", "Back", "Chest", "Face"][index % 5],
            isActive: index % 3 != 0,
            createdAt: Calendar.current.date(byAdding: .day, value: -index * 2, to: Date())!,
            userProfile: userProfile
        )
    }

    // Insert sample data
    let context = container.mainContext
    context.insert(userProfile)
    spots.forEach { context.insert($0) }
    try! context.save()

    return NavigationView {
        SpotListView(
            selectedProfileId: userProfile.id,
            onSpotTap: { spot in
                print("iPad spot tapped: \(spot.title)")
            },
            onAddSpot: {
                isPresented = true
            }
        )
        .navigationTitle("SpotOn")
        .preferredColorScheme(.light)
        .sheet(isPresented: $isPresented) {
            AddSpotView(
                isPresented: $isPresented,
                userProfile: userProfile
            )
        }
    }
    .modelContainer(container)
}