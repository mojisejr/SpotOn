//
//  ProfileCardView.swift
//  SpotOn
//
//  Created by Non on 11/28/25.
//

import SwiftUI

/// Individual profile card component displaying user avatar and information
/// Features medical theme styling with selection states and accessibility support
struct ProfileCardView: View {
    // MARK: - Properties

    /// The user profile to display
    let profile: UserProfile

    /// Whether this profile is currently selected
    let isSelected: Bool

    /// Action to perform when user taps this profile
    let onTap: () -> Void

    // MARK: - Medical Theme Colors

    private let medicalBlue = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
    private let cardBackgroundColor = Color.white
    private let textColor = Color.primary
    private let subtitleColor = Color.secondary
    private let unselectedBorderColor = Color.gray.opacity(0.3)

    // MARK: - Computed Properties

    /// Extract initials from profile name for avatar display
    private var initials: String {
        let name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            return "?"
        }

        let components = name.split(separator: " ")
        if components.count >= 2 {
            return "\(components.first!.prefix(1))\(components.last!.prefix(1))".uppercased()
        } else {
            return String(name.prefix(1)).uppercased()
        }
    }

    /// Convert hex color string to SwiftUI Color
    private var avatarColor: Color {
        Color(hex: profile.avatarColor) ?? .blue
    }

    /// Display name with fallback for empty names
    private var displayName: String {
        profile.name.isEmpty ? "Unnamed Profile" : profile.name
    }

    /// Display relation with fallback for empty relations
    private var displayRelation: String {
        profile.relation.isEmpty ? "Family Member" : profile.relation
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Avatar Section
                ZStack {
                    // Selection indicator ring
                    if isSelected {
                        Circle()
                            .stroke(medicalBlue, lineWidth: 4)
                            .frame(width: 72, height: 72)
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                    }

                    // Avatar background
                    Circle()
                        .fill(avatarColor)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .strokeBorder(cardBackgroundColor, lineWidth: 3)
                        )

                    // Initials text
                    Text(initials)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                // Profile Information
                VStack(spacing: 4) {
                    // Profile name
                    Text(displayName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    // Profile relation
                    Text(displayRelation)
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(subtitleColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .frame(width: 100)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                isSelected ? medicalBlue : unselectedBorderColor,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? medicalBlue.opacity(0.2) : .black.opacity(0.1),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .opacity(isSelected ? 1.0 : 0.9)
        }
        .accessibilityIdentifier("profileCardView")
        .accessibilityLabel("\(displayName), \(displayRelation), Profile")
        .accessibilityHint("Double tap to select this profile")
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Color Extension

extension Color {
    /// Initialize Color from hex string
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview("Selected State") {
    let selectedProfile = UserProfile(
        id: UUID(),
        name: "John Doe",
        relation: "Self",
        avatarColor: "#FF6B6B",
        createdAt: Date()
    )

    return ProfileCardView(
        profile: selectedProfile,
        isSelected: true,
        onTap: { print("Selected profile tapped") }
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Unselected State") {
    let unselectedProfile = UserProfile(
        id: UUID(),
        name: "Jane Doe",
        relation: "Spouse",
        avatarColor: "#4ECDC4",
        createdAt: Date()
    )

    return ProfileCardView(
        profile: unselectedProfile,
        isSelected: false,
        onTap: { print("Unselected profile tapped") }
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Empty Name") {
    let emptyNameProfile = UserProfile(
        id: UUID(),
        name: "",
        relation: "Self",
        avatarColor: "#96CEB4",
        createdAt: Date()
    )

    return ProfileCardView(
        profile: emptyNameProfile,
        isSelected: false,
        onTap: { print("Empty name profile tapped") }
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}