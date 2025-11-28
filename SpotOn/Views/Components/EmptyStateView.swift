//
//  EmptyStateView.swift
//  SpotOn
//
//  Created by Non on 11/28/25.
//

import SwiftUI

/// Reusable empty state component for various no-data scenarios
/// Features medical theme styling with helpful guidance and action prompts
struct EmptyStateView: View {
    // MARK: - Properties

    /// Configuration for the empty state
    let configuration: EmptyStateConfiguration

    /// Action to perform when user taps the primary action button
    let onPrimaryAction: (() -> Void)?

    /// Action to perform when user taps the secondary action button (optional)
    let onSecondaryAction: (() -> Void)?

    /// Initialize with configuration and optional actions
    init(configuration: EmptyStateConfiguration, onPrimaryAction: (() -> Void)? = nil, onSecondaryAction: (() -> Void)? = nil) {
        self.configuration = configuration
        self.onPrimaryAction = onPrimaryAction
        self.onSecondaryAction = onSecondaryAction
    }

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

    /// Dynamic container padding based on device type
    private var containerPadding: CGFloat {
        isIPad ? 40 : 32
    }

    /// Dynamic icon size based on device type
    private var iconSize: CGFloat {
        isIPad ? 80 : 64
    }

    /// Dynamic font sizes based on device type
    private var titleFontSize: CGFloat {
        isIPad ? 24 : 20
    }

    private var subtitleFontSize: CGFloat {
        isIPad ? 18 : 16
    }

    private var descriptionFontSize: CGFloat {
        isIPad ? 16 : 14
    }

    /// Dynamic spacing based on device type
    private var contentSpacing: CGFloat {
        isIPad ? 24 : 20
    }

    private var sectionSpacing: CGFloat {
        isIPad ? 32 : 24
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Main empty state content
                VStack(spacing: sectionSpacing) {
                    // Icon section
                    iconSection

                    // Text content section
                    textContentSection

                    // Actions section
                    if configuration.showActions {
                        actionsSection
                    }
                }
                .padding(containerPadding)

                Spacer(minLength: 40)
            }
        }
        .background(backgroundColor)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Empty state: \(configuration.title)")
    }

    // MARK: - View Components

    private var iconSection: some View {
        VStack(spacing: contentSpacing) {
            // Main icon with background circle
            ZStack {
                Circle()
                    .fill(medicalBlue.opacity(0.1))
                    .frame(width: iconSize + 20, height: iconSize + 20)

                Image(systemName: configuration.systemImage)
                    .font(.system(size: iconSize, weight: .light))
                    .foregroundColor(medicalBlue)
            }
            .accessibilityHidden(true) // Decorative element

            // Optional badge or status indicator
            if let badgeText = configuration.badgeText {
                Text(badgeText)
                    .font(.system(size: descriptionFontSize, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(medicalBlue)
                    )
                    .accessibilityLabel(badgeText)
            }
        }
    }

    private var textContentSection: some View {
        VStack(spacing: contentSpacing) {
            // Title
            Text(configuration.title)
                .font(.system(size: titleFontSize, weight: .semibold, design: .rounded))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            // Subtitle (if provided)
            if let subtitle = configuration.subtitle {
                Text(subtitle)
                    .font(.system(size: subtitleFontSize, weight: .medium, design: .default))
                    .foregroundColor(subtitleColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Description
            Text(configuration.description)
                .font(.system(size: descriptionFontSize, weight: .regular, design: .default))
                .foregroundColor(subtitleColor)
                .multilineTextAlignment(.center)
                .lineLimit(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, isIPad ? 20 : 0)
        }
    }

    private var actionsSection: some View {
        VStack(spacing: contentSpacing) {
            // Primary action button
            if let primaryActionTitle = configuration.primaryActionTitle {
                Button(action: {
                    onPrimaryAction?()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: configuration.primaryActionIcon ?? "plus.circle.fill")
                            .font(.system(size: 18, weight: .medium))

                        Text(primaryActionTitle)
                            .font(.system(size: subtitleFontSize, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(medicalBlue)
                    )
                }
                .accessibilityLabel(primaryActionTitle)
                .accessibilityHint("Tap to \(primaryActionTitle.lowercased())")
                .accessibilityAddTraits(.isButton)
                .buttonStyle(ScaleButtonStyle())
            }

            // Secondary action button (if provided)
            if let secondaryActionTitle = configuration.secondaryActionTitle {
                Button(action: {
                    onSecondaryAction?()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: configuration.secondaryActionIcon ?? "questionmark.circle")
                            .font(.system(size: 16, weight: .medium))

                        Text(secondaryActionTitle)
                            .font(.system(size: descriptionFontSize, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(medicalBlue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(medicalBlue, lineWidth: 1.5)
                            .fill(Color.clear)
                    )
                }
                .accessibilityLabel(secondaryActionTitle)
                .accessibilityHint("Tap to \(secondaryActionTitle.lowercased())")
                .accessibilityAddTraits(.isButton)
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
}

// MARK: - Empty State Configuration

struct EmptyStateConfiguration {
    let title: String
    let subtitle: String?
    let description: String
    let systemImage: String
    let badgeText: String?
    let showActions: Bool
    let primaryActionTitle: String?
    let primaryActionIcon: String?
    let secondaryActionTitle: String?
    let secondaryActionIcon: String?

    init(
        title: String,
        subtitle: String? = nil,
        description: String,
        systemImage: String,
        badgeText: String? = nil,
        showActions: Bool = true,
        primaryActionTitle: String? = nil,
        primaryActionIcon: String? = nil,
        secondaryActionTitle: String? = nil,
        secondaryActionIcon: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.systemImage = systemImage
        self.badgeText = badgeText
        self.showActions = showActions
        self.primaryActionTitle = primaryActionTitle
        self.primaryActionIcon = primaryActionIcon
        self.secondaryActionTitle = secondaryActionTitle
        self.secondaryActionIcon = secondaryActionIcon
    }
}

// MARK: - Predefined Configurations

extension EmptyStateConfiguration {
    /// Configuration for no spots scenario
    static var noSpots: EmptyStateConfiguration {
        EmptyStateConfiguration(
            title: "No Spots Tracked Yet",
            subtitle: "Start Your Health Journey",
            description: "Begin tracking skin conditions by taking photos of moles, rashes, or wounds. Regular monitoring helps detect changes early.",
            systemImage: "camera.viewfinder",
            badgeText: "New",
            showActions: true,
            primaryActionTitle: "Add Your First Spot",
            primaryActionIcon: "plus.circle.fill",
            secondaryActionTitle: "Learn More",
            secondaryActionIcon: "info.circle"
        )
    }

    /// Configuration for no profiles scenario
    static var noProfiles: EmptyStateConfiguration {
        EmptyStateConfiguration(
            title: "No Family Members",
            subtitle: "Set Up Your Health Profile",
            description: "Create profiles for yourself and family members to start tracking medical spots and monitoring health conditions.",
            systemImage: "person.3.sequence",
            showActions: true,
            primaryActionTitle: "Create First Profile",
            primaryActionIcon: "person.badge.plus"
        )
    }

    /// Configuration for no data scenario (generic)
    static var noData: EmptyStateConfiguration {
        EmptyStateConfiguration(
            title: "No Data Available",
            description: "There's no information to display at the moment. Try adding some data or check back later.",
            systemImage: "tray",
            showActions: false
        )
    }

    /// Configuration for network error scenario
    static var networkError: EmptyStateConfiguration {
        EmptyStateConfiguration(
            title: "Connection Issue",
            description: "Unable to load data due to network problems. Please check your connection and try again.",
            systemImage: "wifi.slash",
            showActions: true,
            primaryActionTitle: "Try Again",
            primaryActionIcon: "arrow.clockwise"
        )
    }
}

// MARK: - Convenience Initializers

extension EmptyStateView {
    
    /// Initialize for no spots scenario
    init(onAddSpot: (() -> Void)? = nil, onLearnMore: (() -> Void)? = nil) {
        self.init(
            configuration: .noSpots,
            onPrimaryAction: onAddSpot,
            onSecondaryAction: onLearnMore
        )
    }

    /// Initialize for no profiles scenario
    init(onCreateProfile: (() -> Void)? = nil) {
        self.init(
            configuration: .noProfiles,
            onPrimaryAction: onCreateProfile
        )
    }

    /// Legacy initializer for backward compatibility
    init(onCreateProfile: @escaping () -> Void) {
        self.init(
            configuration: .noProfiles,
            onPrimaryAction: onCreateProfile
        )
    }
}

// MARK: - Scale Button Style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("No Spots") {
    @State var isPresented = false

    let userProfile = UserProfile(
        id: UUID(),
        name: "Test User",
        relation: "Self",
        avatarColor: "#FF6B6B",
        createdAt: Date()
    )

    return NavigationView {
        EmptyStateView(
            onAddSpot: {
                isPresented = true
            },
            onLearnMore: { print("Learn more tapped") }
        )
        .navigationTitle("SpotOn")
        .sheet(isPresented: $isPresented) {
            AddSpotView(
                isPresented: $isPresented,
                userProfile: userProfile
            )
        }
    }
}

#Preview("No Profiles") {
    NavigationView {
        EmptyStateView(
            configuration: .noProfiles,
            onPrimaryAction: { print("Create profile tapped") }
        )
        .navigationTitle("SpotOn")
    }
}

#Preview("No Data") {
    NavigationView {
        EmptyStateView(configuration: .noData)
            .navigationTitle("SpotOn")
    }
}

#Preview("Network Error") {
    NavigationView {
        EmptyStateView(
            configuration: .networkError,
            onPrimaryAction: { print("Retry tapped") }
        )
        .navigationTitle("SpotOn")
    }
}