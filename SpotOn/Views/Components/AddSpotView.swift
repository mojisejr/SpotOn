//
//  AddSpotView.swift
//  SpotOn
//
//  Created by Non on 11/28/25.
//

import SwiftUI
import SwiftData

/// Modal view for creating new medical tracking spots
/// Features form validation, medical theme, and SwiftData integration
struct AddSpotView: View {
    // MARK: - Properties

    /// Controls sheet presentation
    @Binding var isPresented: Bool

    /// User profile for the new spot
    let userProfile: UserProfile?

    // MARK: - Form State

    /// Spot title input
    @State private var spotTitle: String = ""

    /// Selected body part
    @State private var selectedBodyPart: String = ""

    /// Optional notes
    @State private var notes: String = ""

    /// Form validation state
    @State private var isFormValid: Bool = false

    /// Loading state during save
    @State private var isSaving: Bool = false

    /// Error message display
    @State private var errorMessage: String?
    @State private var showingError: Bool = false

    // MARK: - SwiftData Context

    @Environment(\.modelContext) private var modelContext

    // MARK: - Medical Theme Colors

    private let medicalBlue = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
    private let successGreen = Color.green
    private let errorRed = Color.red
    private let backgroundColor = Color(red: 0.95, green: 0.95, blue: 0.97) // #F2F2F7
    private let cardBackgroundColor = Color.white
    private let textColor = Color.primary
    private let subtitleColor = Color.secondary
    private let borderColor = Color.gray.opacity(0.3)

    // MARK: - Form Validation Limits

    private let maxTitleLength: Int = 100
    private let maxNotesLength: Int = 500

    // MARK: - Computed Properties

    /// Check if form is valid for submission
    private var formIsValid: Bool {
        let titleValid = !spotTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let bodyPartValid = !selectedBodyPart.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let titleLengthValid = spotTitle.count <= maxTitleLength
        let notesLengthValid = notes.count <= maxNotesLength
        let hasUserProfile = userProfile != nil

        return titleValid && bodyPartValid && titleLengthValid && notesLengthValid && hasUserProfile
    }

    /// Current user profile for validation
    private var currentUserProfile: UserProfile? {
        userProfile
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                // Form sections
                mainFormSection

                // Validation section
                if !formIsValid && (spotTitle.isEmpty || selectedBodyPart.isEmpty) {
                    validationSection
                }

                // Error section
                if showingError {
                    errorSection
                }
            }
            .navigationTitle("Add New Spot")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(isSaving)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismissForm()
                    }
                    .disabled(isSaving)
                    .accessibilityLabel("Cancel spot creation")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveSpot) {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!formIsValid || isSaving)
                    .accessibilityLabel(formIsValid ? "Save new spot" : "Form incomplete")
                    .accessibilityHint(formIsValid ? "Tap to create new spot" : "Please fill in required fields")
                }
            }
            .onAppear {
                validateForm()
            }
            .onChange(of: spotTitle) { _, _ in
                validateForm()
            }
            .onChange(of: selectedBodyPart) { _, _ in
                validateForm()
            }
            .onChange(of: notes) { _, _ in
                validateForm()
            }
        }
        .accessibilityIdentifier("addSpotView")
    }

    // MARK: - Form Sections

    /// Main form content section
    private var mainFormSection: some View {
        VStack(spacing: 0) {
            // Profile information
            profileSection

            // Spot title
            titleSection

            // Body part selection
            bodyPartSection

            // Optional notes
            notesSection
        }
    }

    /// Profile information section
    private var profileSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Creating for")
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(subtitleColor)

                    Text(currentUserProfile?.name ?? "No Profile Selected")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(textColor)
                }

                Spacer()

                // Profile avatar
                ZStack {
                    Circle()
                        .fill(Color(hex: currentUserProfile?.avatarColor ?? "#007AFF") ?? medicalBlue)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .strokeBorder(cardBackgroundColor, lineWidth: 1)
                        )

                    Text(String((currentUserProfile?.name.prefix(1) ?? "P").uppercased()))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 8)
            .opacity(0.8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Creating spot for \(currentUserProfile?.name ?? "unknown profile")")
    }

    /// Spot title input section
    private var titleSection: some View {
        Section(header: sectionHeader("Spot Title", subtitle: "Required")) {
            VStack(alignment: .leading, spacing: 8) {
                TextField("e.g., Left Arm Mole", text: $spotTitle)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(cardBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(
                                        spotTitle.count > maxTitleLength ? errorRed : borderColor,
                                        lineWidth: 1
                                    )
                            )
                    )
                    .accessibilityLabel("Spot title")
                    .accessibilityHint("Enter a descriptive name for the spot")
                    .accessibilityIdentifier("spotTitleField")

                // Character count
                Text("\(spotTitle.count)/\(maxTitleLength)")
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(spotTitle.count > maxTitleLength ? errorRed : subtitleColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    /// Body part selection section
    private var bodyPartSection: some View {
        Section(header: sectionHeader("Body Part", subtitle: "Required")) {
            BodyPartView(
                selectedBodyPart: $selectedBodyPart,
                onSelectionChanged: { bodyPart in
                    selectedBodyPart = bodyPart
                    validateForm()
                }
            )
        }
    }

    /// Notes input section
    private var notesSection: some View {
        Section(header: sectionHeader("Notes", subtitle: "Optional")) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    if notes.isEmpty {
                        Text("Add any additional notes...")
                            .foregroundColor(subtitleColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $notes)
                        .font(.system(size: 16, design: .default))
                        .padding(8)
                        .background(Color.clear)
                        .frame(minHeight: 80)
                        .accessibilityLabel("Notes")
                        .accessibilityHint("Optional additional information about the spot")
                        .accessibilityIdentifier("notesField")
                }
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(cardBackgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(borderColor, lineWidth: 1)
                        )
                )

                // Character count
                Text("\(notes.count)/\(maxNotesLength)")
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(notes.count > maxNotesLength ? errorRed : subtitleColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    /// Form validation feedback section
    private var validationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))

                    Text("Please complete required fields")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(textColor)
                }

                if spotTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("• Spot title is required")
                        .font(.system(size: 13, weight: .regular, design: .default))
                        .foregroundColor(subtitleColor)
                        .padding(.leading, 24)
                }

                if selectedBodyPart.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("• Body part selection is required")
                        .font(.system(size: 13, weight: .regular, design: .default))
                        .foregroundColor(subtitleColor)
                        .padding(.leading, 24)
                }
            }
            .padding(.vertical, 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Form validation messages")
    }

    /// Error display section
    private var errorSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(errorRed)
                        .font(.system(size: 16))

                    Text("Error")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(errorRed)
                }

                Text(errorMessage ?? "An unknown error occurred")
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundColor(textColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(errorRed.opacity(0.1))
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error message")
    }

    // MARK: - Helper Views

    /// Standardized section header
    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(textColor)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundColor(subtitleColor)
        }
    }

    // MARK: - Form Actions

    /// Validate form and update state
    private func validateForm() {
        isFormValid = formIsValid

        // Clear error when form becomes valid
        if isFormValid {
            errorMessage = nil
            showingError = false
        }
    }

    /// Save the new spot to database
    private func saveSpot() {
        // Check for specific validation errors
        if let validationError = getFormValidationError() {
            showError(validationError)
            return
        }

        guard let userProfile = currentUserProfile else {
            showError("No user profile selected. Please select a profile first.")
            return
        }

        isSaving = true
        errorMessage = nil
        showingError = false

        Task {
            do {
                // Create new spot
                let newSpot = Spot(
                    id: UUID(),
                    title: spotTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                    bodyPart: selectedBodyPart.trimmingCharacters(in: .whitespacesAndNewlines),
                    isActive: true,
                    createdAt: Date(),
                    userProfile: userProfile
                )

                // Save to database
                modelContext.insert(newSpot)
                try modelContext.save()

                // Dismiss form on success
                await MainActor.run {
                    isSaving = false
                    isPresented = false
                }

            } catch {
                await MainActor.run {
                    isSaving = false
                    showError("Failed to save spot: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Show error message with user-friendly formatting
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }

    /// Validate form and provide specific error messages
    private func getFormValidationError() -> String? {
        if spotTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Please enter a spot title"
        }

        if spotTitle.count > maxTitleLength {
            return "Spot title must be \(maxTitleLength) characters or less"
        }

        if selectedBodyPart.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Please select a body part"
        }

        if notes.count > maxNotesLength {
            return "Notes must be \(maxNotesLength) characters or less"
        }

        if currentUserProfile == nil {
            return "No user profile selected. Please select a profile first."
        }

        return nil
    }

    /// Dismiss form without saving
    private func dismissForm() {
        if isSaving {
            return // Don't allow dismissal during save
        }
        isPresented = false
    }
}

// MARK: - Preview

