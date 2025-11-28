//
//  EmptyStateView.swift
//  SpotOn
//
//  Created by Non on 11/28/25.
//

import SwiftUI

/// Empty state view component displayed when no profiles exist
/// Features medical theme with clear messaging and accessibility support
struct EmptyStateView: View {
    // MARK: - Properties

    /// Action to perform when user taps the create profile button
    let onCreateProfile: () -> Void

    // MARK: - Medical Theme Colors

    private let medicalBlue = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
    private let backgroundColor = Color(red: 0.95, green: 0.95, blue: 0.97) // #F2F2F7
    private let textColor = Color.primary
    private let subtitleColor = Color.secondary

    // MARK: - Body

    var body: some View {
        VStack(spacing: 32) {
            // Illustration/Icon Section
            VStack(spacing: 16) {
                // Profile icon with medical theme
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(medicalBlue.opacity(0.3), lineWidth: 2)
                        )

                    // Person icon using SF Symbols
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(medicalBlue)
                }
                .accessibilityHidden(true)

                // Title and subtitle
                VStack(spacing: 8) {
                    Text("No Profiles Yet")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(textColor)
                        .accessibilityIdentifier("homeViewTitle")
                        .accessibilityAddTraits(.isHeader)

                    Text("Create your first profile to start tracking medical spots and monitoring skin health")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(subtitleColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Create Profile Button
            Button(action: onCreateProfile) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .medium))

                    Text("Create Profile")
                        .font(.system(size: 18, weight: .semibold, design: .default))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .fill(medicalBlue)
                        .shadow(color: medicalBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .accessibilityIdentifier("createProfileButton")
            .accessibilityLabel("Create your first profile")
            .accessibilityHint("Start tracking medical spots by creating a user profile")
            .buttonStyle(ScaleButtonStyle())

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 32)
        .padding(.top, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor.ignoresSafeArea())
        .accessibilityIdentifier("emptyStateView")
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Custom Button Style

/// Custom button style with scale animation for better user feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    EmptyStateView(onCreateProfile: {
        print("Create profile tapped")
    })
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    EmptyStateView(onCreateProfile: {
        print("Create profile tapped")
    })
    .preferredColorScheme(.dark)
}