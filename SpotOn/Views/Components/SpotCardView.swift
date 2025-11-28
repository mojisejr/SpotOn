//
//  SpotCardView.swift
//  SpotOn
//
//  Created by Non on 11/28/25.
//

import SwiftUI

/// Individual spot card component displaying spot information
/// Features medical theme styling with status indicators and accessibility support
struct SpotCardView: View {
    // MARK: - Properties

    /// The spot to display
    let spot: Spot

    /// Action to perform when user taps this spot
    let onTap: (() -> Void)?

    // MARK: - Medical Theme Colors

    private let medicalBlue = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
    private let activeGreen = Color(red: 0.0, green: 0.8, blue: 0.4) // #00CC66
    private let inactiveGray = Color(red: 0.6, green: 0.6, blue: 0.6) // #999999
    private let cardBackgroundColor = Color.white
    private let textColor = Color.primary
    private let subtitleColor = Color.secondary

    // MARK: - Responsive Design Properties

    /// Detect if device is iPad
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    /// Dynamic card padding based on device type
    private var cardPadding: CGFloat {
        isIPad ? 20 : 16
    }

    /// Dynamic font sizes based on device type
    private var titleFontSize: CGFloat {
        isIPad ? 18 : 16
    }

    private var subtitleFontSize: CGFloat {
        isIPad ? 14 : 12
    }

    /// Dynamic spacing based on device type
    private var contentSpacing: CGFloat {
        isIPad ? 16 : 12
    }

    // MARK: - Computed Properties

    /// Status indicator color based on spot activity
    private var statusColor: Color {
        spot.isActive ? activeGreen : inactiveGray
    }

    /// Status indicator icon based on spot activity
    private var statusIcon: String {
        spot.isActive ? "circle.fill" : "circle"
    }

    /// Display title with fallback for empty titles
    private var displayTitle: String {
        spot.title.isEmpty ? "Untitled Spot" : spot.title
    }

    /// Display body part with fallback for empty body parts
    private var displayBodyPart: String {
        spot.bodyPart.isEmpty ? "Unknown Location" : spot.bodyPart
    }

    /// Formatted creation date
    private var formattedCreationDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: spot.createdAt, relativeTo: Date())
    }

    /// Body part icon based on common body parts
    private var bodyPartIcon: String {
        switch displayBodyPart.lowercased() {
        case let part where part.contains("head"):
            return "head.profile"
        case let part where part.contains("arm"):
            return "figure.arms.open"
        case let part where part.contains("hand"):
            return "hand.raised"
        case let part where part.contains("chest") || part.contains("back"):
            return "figure.walk"
        case let part where part.contains("leg") || part.contains("knee"):
            return "figure.walk"
        case let part where part.contains("foot"):
            return "figure.arms.open"
        default:
            return "location.circle"
        }
    }

    // MARK: - Body

    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(spacing: 0) {
                // Main content area
                HStack(spacing: contentSpacing) {
                    // Status indicator and icon section
                    statusIndicatorSection

                    // Spot information section
                    spotInformationSection

                    // Navigation arrow (if tap action is provided)
                    if onTap != nil {
                        navigationArrowSection
                    }
                }
                .padding(cardPadding)

                // Divider line
                Divider()
                    .padding(.leading, cardPadding + 24) // Align with text content
                    .background(Color.gray.opacity(0.2))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(cardBackgroundColor)
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .accessibilityIdentifier("spotCardView")
        .accessibilityLabel("\(displayTitle), located on \(displayBodyPart), \(spot.isActive ? "active" : "inactive"), created \(formattedCreationDate)")
        .accessibilityHint("Double tap to view spot details")
        .accessibilityAddTraits(.isButton)
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - View Components

    private var statusIndicatorSection: some View {
        VStack(spacing: 8) {
            // Status indicator circle
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 32, height: 32)

                Circle()
                    .fill(statusColor)
                    .frame(width: 20, height: 20)
                    .scaleEffect(spot.isActive ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: spot.isActive)
            }
            .accessibilityIdentifier(spot.isActive ? "activeIndicator" : "inactiveIndicator")

            // Status text
            Text(spot.isActive ? "Active" : "Inactive")
                .font(.system(size: subtitleFontSize - 2, weight: .medium, design: .rounded))
                .foregroundColor(statusColor)
                .accessibilityHidden(true) // Status already in accessibility label
        }
    }

    private var spotInformationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Spot title
            Text(displayTitle)
                .font(.system(size: titleFontSize, weight: .semibold, design: .rounded))
                .foregroundColor(textColor)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .accessibilityIdentifier("spotTitle")

            // Body part with icon
            HStack(spacing: 6) {
                Image(systemName: bodyPartIcon)
                    .font(.system(size: subtitleFontSize, weight: .medium))
                    .foregroundColor(medicalBlue)
                    .accessibilityHidden(true) // Decorative icon

                Text(displayBodyPart)
                    .font(.system(size: subtitleFontSize, weight: .medium, design: .default))
                    .foregroundColor(subtitleColor)
                    .accessibilityIdentifier("spotBodyPart")
            }

            // Creation date
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: subtitleFontSize - 2, weight: .regular))
                    .foregroundColor(subtitleColor)
                    .accessibilityHidden(true) // Decorative icon

                Text("Created \(formattedCreationDate)")
                    .font(.system(size: subtitleFontSize - 2, weight: .regular, design: .default))
                    .foregroundColor(subtitleColor)
                    .accessibilityIdentifier("spotCreationDate")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var navigationArrowSection: some View {
        VStack(spacing: 0) {
            Image(systemName: "chevron.right")
                .font(.system(size: subtitleFontSize + 2, weight: .medium))
                .foregroundColor(subtitleColor.opacity(0.6))
                .accessibilityHidden(true) // Decorative element
        }
    }
}


// MARK: - Preview

#Preview("Active Spot") {
    let userProfile = UserProfile(
        id: UUID(),
        name: "John Doe",
        relation: "Self",
        avatarColor: "#FF6B6B",
        createdAt: Date()
    )

    let activeSpot = Spot(
        id: UUID(),
        title: "Left Arm Mole",
        bodyPart: "Arm",
        isActive: true,
        createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
        userProfile: userProfile
    )

    SpotCardView(spot: activeSpot) {
        print("Active spot tapped")
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Inactive Spot") {
    let userProfile = UserProfile(
        id: UUID(),
        name: "Jane Doe",
        relation: "Spouse",
        avatarColor: "#4ECDC4",
        createdAt: Date()
    )

    let inactiveSpot = Spot(
        id: UUID(),
        title: "Healed Knee Scar",
        bodyPart: "Knee",
        isActive: false,
        createdAt: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
        userProfile: userProfile
    )

    SpotCardView(spot: inactiveSpot) {
        print("Inactive spot tapped")
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Long Title") {
    let userProfile = UserProfile(
        id: UUID(),
        name: "Test User",
        relation: "Self",
        avatarColor: "#96CEB4",
        createdAt: Date()
    )

    let longTitleSpot = Spot(
        id: UUID(),
        title: "This is a very long spot title that should be truncated properly",
        bodyPart: "Back",
        isActive: true,
        createdAt: Date(),
        userProfile: userProfile
    )

    SpotCardView(spot: longTitleSpot, onTap: nil)
        .padding()
        .background(Color.gray.opacity(0.1))
}

#Preview("Empty Fields") {
    let userProfile = UserProfile(
        id: UUID(),
        name: "Test User",
        relation: "Self",
        avatarColor: "#45B7D1",
        createdAt: Date()
    )

    let emptySpot = Spot(
        id: UUID(),
        title: "",
        bodyPart: "",
        isActive: true,
        createdAt: Date(),
        userProfile: userProfile
    )

    SpotCardView(spot: emptySpot, onTap: nil)
        .padding()
        .background(Color.gray.opacity(0.1))
}