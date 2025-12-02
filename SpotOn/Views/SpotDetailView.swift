//
//  SpotDetailView.swift
//  SpotOn
//
//  Created by Non on 11/29/25.
//

import SwiftUI
import SwiftData
import AVFoundation

/// Detail view for individual spots showing timeline of log entries
/// Features medical theme, chronological timeline display, and comprehensive medical data
struct SpotDetailView: View {
    // MARK: - Properties

    /// The spot to display details for
    let spot: Spot

    /// Navigation path environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    /// State for showing Camera overlay sheet
    @State private var showingCamera = false

    /// State for showing Add Log Entry sheet (fallback)
    @State private var showingAddLogEntry = false

    // MARK: - Medical Theme Colors

    private let medicalBlue = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
    private let backgroundColor = Color(red: 0.95, green: 0.95, blue: 0.97) // #F2F2F7
    private let cardBackgroundColor = Color.white
    private let textColor = Color.primary
    private let subtitleColor = Color.secondary

    // MARK: - Responsive Design Properties

    /// Detect if device is iPad
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    /// Detect if device is in landscape orientation
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isLandscape: Bool {
        // Use environment-based detection instead of deprecated UIScreen.main
        horizontalSizeClass == .regular && verticalSizeClass == .compact
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

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: sectionSpacing) {
                    // Spot information section
                    spotInfoSection

                    // Timeline section
                    TimelineView(spot: spot)
                }
                .padding(.horizontal, contentHorizontalPadding)
                .padding(.top, isIPad ? 12 : 8)
            }
            .background(backgroundColor)
            .navigationTitle("Spot Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(medicalBlue)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCamera = true
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(medicalBlue)
                    }
                    .accessibilityLabel("Take Photo")
                    .accessibilityHint("Take a new photo with ghost overlay for consistent tracking")
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingCamera) {
            CameraOverlayView(
                spot: spot,
                cameraManager: CameraManager(imageManager: ImageManager()),
                imageManager: ImageManager(),
                onPhotoCaptured: { image in
                    // Photo captured and LogEntry will be created in CameraOverlayView
                    print("Photo captured for spot: \(spot.title)")
                },
                onError: { error in
                    print("Camera error: \(error.localizedDescription)")
                },
                onCancel: {
                    showingCamera = false
                }
            )
        }
        .sheet(isPresented: $showingAddLogEntry) {
            AddLogEntryView(spot: spot)
        }
        .accessibilityIdentifier("spotDetailView")
    }

    // MARK: - View Components

    /// Section displaying spot information
    private var spotInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Spot title and body part
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(spot.title.isEmpty ? "Unnamed Spot" : spot.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)

                    Text(spot.bodyPart.isEmpty ? "Unknown Location" : spot.bodyPart)
                        .font(.system(size: 18, weight: .medium, design: .default))
                        .foregroundColor(subtitleColor)

                    // Status indicator
                    HStack(spacing: 8) {
                        Circle()
                            .fill(spot.isActive ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)

                        Text(spot.isActive ? "Active" : "Inactive")
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(spot.isActive ? .green : .gray)
                    }
                }

                Spacer()

                // User avatar showing who this spot belongs to
                if let userProfile = spot.userProfile {
                    ZStack {
                        Circle()
                            .fill(Color(hex: userProfile.avatarColor) ?? .blue)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .strokeBorder(cardBackgroundColor, lineWidth: 2)
                            )

                        Text(String(userProfile.name.prefix(1)).uppercased())
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("\(userProfile.name)'s avatar")
                }
            }

            // Creation date
            Text("Created \(spot.createdAt, style: .relative) ago")
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(subtitleColor)

            // Associated user information
            if let userProfile = spot.userProfile {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(medicalBlue)
                        .font(.system(size: 16))

                    Text("Tracking for \(userProfile.name)")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(textColor)

                    if !userProfile.relation.isEmpty {
                        Text("(\(userProfile.relation))")
                            .font(.system(size: 14, weight: .regular, design: .default))
                            .foregroundColor(subtitleColor)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .accessibilityIdentifier("spotInfoSection")
    }
}

// MARK: - Preview

#Preview("Spot with Log Entries") {
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

    // Create sample spot
    let spot = Spot(
        id: UUID(),
        title: "Mole on Left Arm",
        bodyPart: "Left Arm",
        isActive: true,
        createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
        userProfile: userProfile
    )

    // Create sample log entries
    let logEntries = [
        LogEntry(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            imageFilename: "MOLE_RECENT.jpg",
            note: "Looking normal today, no changes observed",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: 5.0,
            spot: spot
        ),
        LogEntry(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            imageFilename: "MOLE_CONCERN.jpg",
            note: "Slight redness noticed, monitoring closely",
            painScore: 2,
            hasBleeding: false,
            hasItching: true,
            isSwollen: false,
            estimatedSize: 5.5,
            spot: spot
        )
    ]

    // Insert sample data
    let context = container.mainContext
    context.insert(userProfile)
    context.insert(spot)
    for entry in logEntries {
        context.insert(entry)
    }
    try! context.save()

    return SpotDetailView(spot: spot)
        .modelContainer(container)
}

#Preview("Empty Spot") {
    // Create sample data container
    let container = try! ModelContainer(
        for: UserProfile.self, Spot.self, LogEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    // Create sample user profile
    let userProfile = UserProfile(
        id: UUID(),
        name: "Jane Doe",
        relation: "Child",
        avatarColor: "#4ECDC4",
        createdAt: Date()
    )

    // Create sample spot with no log entries
    let spot = Spot(
        id: UUID(),
        title: "New Birthmark",
        bodyPart: "Back",
        isActive: true,
        createdAt: Date(),
        userProfile: userProfile
    )

    // Insert sample data
    let context = container.mainContext
    context.insert(userProfile)
    context.insert(spot)
    try! context.save()

    return SpotDetailView(spot: spot)
        .modelContainer(container)
}

#Preview("Inactive Spot") {
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
        avatarColor: "#45B7D1",
        createdAt: Date()
    )

    // Create inactive spot
    let spot = Spot(
        id: UUID(),
        title: "Healed Scar",
        bodyPart: "Knee",
        isActive: false,
        createdAt: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
        userProfile: userProfile
    )

    // Insert sample data
    let context = container.mainContext
    context.insert(userProfile)
    context.insert(spot)
    try! context.save()

    return SpotDetailView(spot: spot)
        .modelContainer(container)
}