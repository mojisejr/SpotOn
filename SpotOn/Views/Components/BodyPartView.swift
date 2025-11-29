//
//  BodyPartView.swift
//  SpotOn
//
//  Created by Non on 11/28/25.
//

import SwiftUI

/// Component for selecting body parts where spots are located
/// Features categorized options and medical theme styling
struct BodyPartView: View {
    // MARK: - Properties

    /// Currently selected body part
    @Binding var selectedBodyPart: String

    /// Callback when body part selection changes
    let onSelectionChanged: (String) -> Void

    // MARK: - Medical Theme Colors

    private let medicalBlue = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
    private let backgroundColor = Color(red: 0.95, green: 0.95, blue: 0.97) // #F2F2F7
    private let textColor = Color.primary
    private let subtitleColor = Color.secondary

    // MARK: - Body Part Data

    /// Categorized body parts for better organization
    private let bodyPartCategories: [String: [String]] = [
        "Upper Body": ["Head", "Neck", "Chest", "Back", "Abdomen"],
        "Arms": ["Left Arm", "Right Arm", "Left Hand", "Right Hand"],
        "Legs": ["Left Leg", "Right Leg", "Left Foot", "Right Foot"],
        "Other": ["Other"]
    ]

    /// Flat list of all body parts for validation
    private var allBodyParts: [String] {
        bodyPartCategories.values.flatMap { $0 }
    }

    // MARK: - Computed Properties

    /// Detect if device is iPad for responsive design
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    /// Grid columns for body part selection
    private var gridColumns: [GridItem] {
        if isIPad {
            return Array(repeating: GridItem(.flexible()), count: 3)
        } else {
            return Array(repeating: GridItem(.flexible()), count: 2)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection

            // Body part selection
            bodyPartSelectionSection
        }
        .padding(16)
        .background(backgroundColor)
        .accessibilityIdentifier("bodyPartView")
    }

    // MARK: - View Components

    /// Header section with title and description
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Body Part")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(textColor)
                .accessibilityAddTraits(.isHeader)

            Text("Select where the spot is located")
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundColor(subtitleColor)
        }
    }

    /// Body part selection grid
    private var bodyPartSelectionSection: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(Array(bodyPartCategories.keys.sorted()), id: \.self) { category in
                    categorySection(category)
                }
            }
        }
    }

    /// Individual category section
    private func categorySection(_ category: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category header
            Text(category)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(textColor)
                .accessibilityAddTraits(.isHeader)

            // Body part grid for this category
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(bodyPartCategories[category] ?? [], id: \.self) { bodyPart in
                    bodyPartButton(bodyPart)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(category) body parts")
    }

    /// Individual body part button
    private func bodyPartButton(_ bodyPart: String) -> some View {
        Button(action: {
            selectedBodyPart = bodyPart
            onSelectionChanged(bodyPart)
        }) {
            Text(bodyPart)
                .font(.system(size: isIPad ? 16 : 14, weight: .medium, design: .rounded))
                .foregroundColor(isSelected(bodyPart) ? .white : textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected(bodyPart) ? medicalBlue : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(
                                    isSelected(bodyPart) ? medicalBlue : Color.gray.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )
        }
        .accessibilityLabel(bodyPart)
        .accessibilityHint(isSelected(bodyPart) ? "\(bodyPart) selected" : "Tap to select \(bodyPart)")
        .accessibilityAddTraits(isSelected(bodyPart) ? .isSelected : [])
        .accessibilityIdentifier("bodyPartButton_\(bodyPart.replacingOccurrences(of: " ", with: "_"))")
        .animation(.easeInOut(duration: 0.2), value: isSelected(bodyPart))
    }

    // MARK: - Helper Methods

    /// Check if a body part is currently selected
    private func isSelected(_ bodyPart: String) -> Bool {
        return selectedBodyPart == bodyPart
    }

    /// Validate body part selection
    private func isValidBodyPart(_ bodyPart: String) -> Bool {
        return allBodyParts.contains(bodyPart)
    }

    /// Get normalized body part (handles invalid selections)
    private func normalizedBodyPart(_ bodyPart: String) -> String {
        if isValidBodyPart(bodyPart) {
            return bodyPart
        } else {
            return "Other" // Default to "Other" for invalid selections
        }
    }
}


// MARK: - Preview

