//
//  AddLogEntryView.swift
//  SpotOn
//
//  Created by Non on 11/29/25.
//

import SwiftUI
import SwiftData

struct AddLogEntryView: View {
    let spot: Spot
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var painScore: Int = 1
    @State private var hasBleeding: Bool = false
    @State private var hasItching: Bool = false
    @State private var isSwollen: Bool = false
    @State private var medicalNote: String = ""
    @State private var estimatedSize: String = ""
    @State private var isSaving: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    // Form validation
    private var isFormValid: Bool {
        !medicalNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Parse estimated size
    private var parsedEstimatedSize: Double? {
        let cleanedSize = estimatedSize.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedSize.isEmpty else { return nil }

        // Extract number and convert to mm
        let numberString = cleanedSize.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let number = Double(numberString) else { return nil }

        // Convert to mm if it seems to be in cm (number > 10 likely means cm)
        return number > 10 ? number * 10 : number
    }

    var body: some View {
        NavigationView {
            Form {
                painAssessmentSection
                symptomsSection
                sizeMeasurementSection
                medicalNoteSection
            }
            .navigationTitle("Add Log Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .disabled(isSaving)
            .overlay(savingOverlay)
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Add log entry form")
    }

    // MARK: - View Components

    private var painAssessmentSection: some View {
        Section {
            PainScoreSlider(painScore: $painScore)
        } header: {
            Text("Pain Assessment")
                .font(.headline)
        }
    }

    private var symptomsSection: some View {
        Section {
            SymptomChecklist(
                hasBleeding: $hasBleeding,
                hasItching: $hasItching,
                isSwollen: $isSwollen
            )
        } header: {
            Text("Current Symptoms")
                .font(.headline)
        }
    }

    private var sizeMeasurementSection: some View {
        Section {
            HStack {
                TextField("e.g., 5mm or 1.5cm", text: $estimatedSize)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)

                if let size = parsedEstimatedSize {
                    Text("\(String(format: "%.1f", size)) mm")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Estimated Size")
                .font(.headline)
        } footer: {
            Text("Optional: Measure the size of the spot")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var medicalNoteSection: some View {
        Section {
            TextField("Describe your observations, changes, concerns...", text: $medicalNote, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        } header: {
            Text("Medical Note")
                .font(.headline)
        } footer: {
            Text("Required: Please provide details about your observations")
                .font(.caption)
                .foregroundColor(isFormValid ? .secondary : .red)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
            .accessibilityLabel("Cancel adding log entry")
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save") {
                saveLogEntry()
            }
            .disabled(!isFormValid || isSaving)
            .fontWeight(.semibold)
            .accessibilityLabel("Save log entry")
            .accessibilityHint(!isFormValid ? "Medical note is required" : "")
        }
    }

    private var savingOverlay: some View {
        Group {
            if isSaving {
                ProgressView("Saving...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.8))
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Save Logic

    private func saveLogEntry() {
        guard isFormValid else {
            alertMessage = "Please fill in the medical note field"
            showAlert = true
            return
        }

        isSaving = true

        // Create new LogEntry
        let logEntry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            imageFilename: "", // No image in this phase
            note: medicalNote.trimmingCharacters(in: .whitespacesAndNewlines),
            painScore: painScore,
            hasBleeding: hasBleeding,
            hasItching: hasItching,
            isSwollen: isSwollen,
            estimatedSize: parsedEstimatedSize,
            spot: spot
        )

        do {
            // Save to SwiftData
            modelContext.insert(logEntry)
            try modelContext.save()

            // Dismiss the view
            dismiss()
        } catch {
            // Handle save error
            alertMessage = "Failed to save log entry: \(error.localizedDescription)"
            showAlert = true
        }

        isSaving = false
    }
}

// MARK: - Preview

#Preview {
    // Create a mock spot for preview
    let mockSpot = Spot(
        id: UUID(),
        title: "Test Mole",
        bodyPart: "Arm",
        isActive: true,
        createdAt: Date(),
        userProfile: nil
    )

    return AddLogEntryView(spot: mockSpot)
        .modelContainer(for: [LogEntry.self, Spot.self, UserProfile.self], inMemory: true)
}