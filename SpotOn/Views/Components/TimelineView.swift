//
//  TimelineView.swift
//  SpotOn
//
//  Created by Non on 11/29/25.
//

import SwiftUI
import SwiftData

/// Timeline view for displaying chronological log entries for a specific spot
/// Features medical theme, chronological ordering, and empty state handling
struct TimelineView: View {
    // MARK: - Properties

    /// The spot to display timeline for
    let spot: Spot

    // MARK: - SwiftData Query

    /// Filtered log entries for the specific spot using @Query
    @Query(filter: #Predicate<LogEntry> { entry in
        entry.spot?.id != nil
    }, sort: \LogEntry.timestamp, order: .reverse)
    private var allLogEntries: [LogEntry]

    // MARK: - Computed Properties

    /// Filtered log entries for the specific spot
    private var filteredLogEntries: [LogEntry] {
        allLogEntries.filter { $0.spot?.id == spot.id }
    }

    /// Check if there are log entries to display
    private var hasLogEntries: Bool {
        !filteredLogEntries.isEmpty
    }

    /// Count of log entries for the spot
    private var logEntryCount: Int {
        filteredLogEntries.count
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
            // Timeline header
            timelineHeader

            if hasLogEntries {
                // Timeline with log entries
                timelineContent
            } else {
                // Empty state
                emptyStateView
            }
        }
        .accessibilityIdentifier("timelineView")
    }

    // MARK: - View Components

    /// Header section for the timeline
    private var timelineHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progress Timeline")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)

                    Text("\(logEntryCount) \(logEntryCount == 1 ? "Entry" : "Entries")")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(subtitleColor)
                        .accessibilityLabel("\(logEntryCount) timeline entries")
                }

                Spacer()

                // Timeline visual indicator
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(medicalBlue)
                    .accessibilityHidden(true)
            }

            // Timeline description
            Text("Track the progression of this spot over time")
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundColor(subtitleColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(cardBackgroundColor)
        .accessibilityElement(children: .contain)
    }

    /// Main timeline content with log entries
    private var timelineContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(filteredLogEntries.enumerated()), id: \.element.id) { index, logEntry in
                    VStack(spacing: 0) {
                        // Timeline connection line
                        if index < filteredLogEntries.count - 1 {
                            timelineConnectionLine
                        }

                        // Log entry card
                        LogEntryCardView(logEntry: logEntry)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(cardBackgroundColor)
                            .accessibilityIdentifier("logEntryCard_\(logEntry.id)")
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .accessibilityIdentifier("timelineScrollView")
    }

    /// Visual timeline connection line between entries
    private var timelineConnectionLine: some View {
        HStack {
            // Timeline dot
            Circle()
                .fill(medicalBlue)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(cardBackgroundColor, lineWidth: 3)
                )
                .padding(.leading, 28)

            // Connection line
            Rectangle()
                .fill(medicalBlue.opacity(0.3))
                .frame(width: 2, height: 20)
                .padding(.leading, 28)

            Spacer()
        }
        .padding(.horizontal, 16)
        .background(cardBackgroundColor)
    }

    /// Empty state view when no log entries exist
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Empty state icon
            ZStack {
                Circle()
                    .fill(medicalBlue.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(medicalBlue)
            }

            // Empty state text
            VStack(spacing: 12) {
                Text("No Progress Yet")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)

                Text("Start tracking this spot by adding your first log entry")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(subtitleColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Take photos and add notes to monitor changes over time")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(subtitleColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Action hint (visual only - actual add functionality will be implemented later)
            HStack {
                Image(systemName: "camera.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(medicalBlue)

                Text("Use the camera to add your first entry")
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(medicalBlue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(medicalBlue.opacity(0.1))
            )
        }
        .padding(32)
        .background(cardBackgroundColor)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("emptyTimelineState")
    }
}

// MARK: - Extensions

extension TimelineView {
    /// Initialize with spot
    init(spot: Spot) {
        self.spot = spot
    }
}

// MARK: - Preview

#Preview("Timeline with Entries") {
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
        createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
        userProfile: userProfile
    )

    // Create multiple log entries with different timestamps
    let logEntries = [
        LogEntry(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!, // 2 hours ago
            imageFilename: "MOLE_RECENT.jpg",
            note: "Looking much better today, redness has subsided significantly",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: 4.8,
            spot: spot
        ),
        LogEntry(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, // 1 day ago
            imageFilename: "MOLE_YESTERDAY.jpg",
            note: "Still some redness but less than yesterday",
            painScore: 1,
            hasBleeding: false,
            hasItching: true,
            isSwollen: false,
            estimatedSize: 5.2,
            spot: spot
        ),
        LogEntry(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, // 3 days ago
            imageFilename: "MOLE_CONCERN.jpg",
            note: "More redness noticed, decided to monitor closely",
            painScore: 2,
            hasBleeding: false,
            hasItching: true,
            isSwollen: false,
            estimatedSize: 5.5,
            spot: spot
        ),
        LogEntry(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, // 1 week ago
            imageFilename: "MOLE_INITIAL.jpg",
            note: "Initial observation - normal appearance",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: 5.0,
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

    return TimelineView(spot: spot)
        .modelContainer(container)
}

#Preview("Empty Timeline") {
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

    return TimelineView(spot: spot)
        .modelContainer(container)
}

#Preview("Single Entry Timeline") {
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

    // Create sample spot
    let spot = Spot(
        id: UUID(),
        title: "Recent Spot",
        bodyPart: "Face",
        isActive: true,
        createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
        userProfile: userProfile
    )

    // Create single log entry
    let logEntry = LogEntry(
        id: UUID(),
        timestamp: Calendar.current.date(byAdding: .hour, value: -4, to: Date())!,
        imageFilename: "SINGLE_ENTRY.jpg",
        note: "First observation - needs monitoring",
        painScore: 1,
        hasBleeding: false,
        hasItching: false,
        isSwollen: false,
        estimatedSize: 3.2,
        spot: spot
    )

    // Insert sample data
    let context = container.mainContext
    context.insert(userProfile)
    context.insert(spot)
    context.insert(logEntry)
    try! context.save()

    return TimelineView(spot: spot)
        .modelContainer(container)
}