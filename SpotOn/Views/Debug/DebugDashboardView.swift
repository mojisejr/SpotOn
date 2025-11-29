//
//  DebugDashboardView.swift
//  SpotOn
//
//  Created by Non on 11/28/25.
//

import SwiftUI
import SwiftData

struct DebugDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var spots: [Spot]
    @Query private var logEntries: [LogEntry]
    @StateObject private var imageManager = ImageManager()

    @State private var showingProfileCreation = false
    @State private var showingSpotCreation = false
    @State private var showingLogEntryCreation = false
    @State private var showingImageViewer = false
    @State private var showingDataViewer = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("SpotOn Debug Dashboard")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .accessibilityIdentifier("debugDashboardTitle")

                        Text("Developer Testing Interface")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Real-time Counters Section
                    VStack(spacing: 16) {
                        Text("Database Statistics")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            CounterCard(
                                title: "Profiles",
                                count: userProfiles.count,
                                color: .blue,
                                identifier: "profileCountLabel"
                            )

                            CounterCard(
                                title: "Spots",
                                count: spots.count,
                                color: .green,
                                identifier: "spotCountLabel"
                            )

                            CounterCard(
                                title: "Log Entries",
                                count: logEntries.count,
                                color: .orange,
                                identifier: "logEntryCountLabel"
                            )

                            CounterCard(
                                title: "Images",
                                count: imageManager.getAllSavedImages().count,
                                color: .purple,
                                identifier: "imageCountLabel"
                            )
                        }
                        .padding(.horizontal)
                    }

                    // Actions Section
                    VStack(spacing: 16) {
                        Text("CRUD Operations")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            ActionButton(
                                title: "CREATE USER PROFILE",
                                icon: "person.badge.plus",
                                color: .blue,
                                identifier: "createProfileButton"
                            ) {
                                if userProfiles.isEmpty {
                                    showingProfileCreation = true
                                } else {
                                    showingProfileCreation = true
                                }
                            }

                            ActionButton(
                                title: "CREATE SPOT",
                                icon: "circle.fill",
                                color: .green,
                                identifier: "createSpotButton"
                            ) {
                                if userProfiles.isEmpty {
                                    alertMessage = "Please create a user profile first before creating spots."
                                    showAlert = true
                                } else {
                                    showingSpotCreation = true
                                }
                            }

                            ActionButton(
                                title: "CREATE LOG ENTRY",
                                icon: "square.and.pencil",
                                color: .orange,
                                identifier: "createLogEntryButton"
                            ) {
                                if spots.isEmpty {
                                    alertMessage = "Please create a spot first before creating log entries."
                                    showAlert = true
                                } else {
                                    showingLogEntryCreation = true
                                }
                            }

                            ActionButton(
                                title: "TEST IMAGE SAVE/LOAD",
                                icon: "photo",
                                color: .purple,
                                identifier: "testImageButton"
                            ) {
                                showingImageViewer = true
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Navigation Section
                    VStack(spacing: 12) {
                        ActionButton(
                            title: "VIEW DATABASE",
                            icon: "list.bullet",
                            color: .gray,
                            identifier: "viewDataButton"
                        ) {
                            showingDataViewer = true
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingProfileCreation) {
            ProfileCreationView()
        }
        .sheet(isPresented: $showingSpotCreation) {
            SpotCreationView()
        }
        .sheet(isPresented: $showingLogEntryCreation) {
            LogEntryCreationView()
        }
        .sheet(isPresented: $showingImageViewer) {
            ImageTestView()
        }
        .sheet(isPresented: $showingDataViewer) {
            DataViewerView()
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

// MARK: - Counter Card Component

struct CounterCard: View {
    let title: String
    let count: Int
    let color: Color
    let identifier: String

    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(count)")
        .accessibilityIdentifier(identifier)
    }
}

// MARK: - Action Button Component

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(color)
            .cornerRadius(10)
        }
        .accessibilityLabel(title)
        .accessibilityIdentifier(identifier)
    }
}


// MARK: - Spot Creation View

struct SpotCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var profiles: [UserProfile]

    @State private var title = ""
    @State private var selectedBodyPart = "Arm"
    @State private var selectedProfile: UserProfile?

    let bodyParts = ["Head", "Neck", "Chest", "Back", "Arm", "Hand", "Leg", "Foot", "Other"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Spot Information")) {
                    TextField("Title", text: $title)
                        .accessibilityIdentifier("spotTitleTextField")

                    Picker("Body Part", selection: $selectedBodyPart) {
                        ForEach(bodyParts, id: \.self) { part in
                            Text(part).tag(part)
                        }
                    }
                    .accessibilityIdentifier("spotBodyPartPicker")

                    if !profiles.isEmpty {
                        Picker("Profile", selection: $selectedProfile) {
                            ForEach(profiles, id: \.id) { profile in
                                Text(profile.name).tag(profile as UserProfile?)
                            }
                        }
                        .accessibilityIdentifier("spotProfilePicker")
                    }
                }
            }
            .navigationTitle("Create Spot")
            .accessibilityIdentifier("spotCreationTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let spot = Spot(
                            id: UUID(),
                            title: title,
                            bodyPart: selectedBodyPart,
                            isActive: true,
                            createdAt: Date(),
                            userProfile: selectedProfile
                        )
                        modelContext.insert(spot)
                        dismiss()
                    }
                    .disabled(title.isEmpty || profiles.isEmpty)
                    .accessibilityIdentifier("saveSpotButton")
                }
            }
            .onAppear {
                if profiles.isEmpty {
                    // Show error and dismiss
                    dismiss()
                }
                selectedProfile = profiles.first
            }
        }
    }
}

// MARK: - Log Entry Creation View

struct LogEntryCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var spots: [Spot]

    @State private var selectedSpot: Spot?
    @State private var note = ""
    @State private var painScore = 0
    @State private var hasBleeding = false
    @State private var hasItching = false
    @State private var isSwollen = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Log Entry Information")) {
                    if !spots.isEmpty {
                        Picker("Spot", selection: $selectedSpot) {
                            ForEach(spots, id: \.id) { spot in
                                Text(spot.title).tag(spot as Spot?)
                            }
                        }
                        .accessibilityIdentifier("logEntrySpotPicker")
                    }

                    VStack(alignment: .leading) {
                        Text("Note")
                        TextEditor(text: $note)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .accessibilityIdentifier("logEntryNoteTextView")

                    VStack(alignment: .leading) {
                        Text("Pain Score: \(painScore)/10")
                        Slider(value: Binding(
                            get: { Double(painScore) },
                            set: { painScore = Int($0) }
                        ), in: 0...10, step: 1)
                            .accessibilityIdentifier("logEntryPainScoreSlider")
                    }
                }

                Section(header: Text("Symptoms")) {
                    Toggle("Bleeding", isOn: $hasBleeding)
                        .accessibilityIdentifier("logEntryBleedingToggle")

                    Toggle("Itching", isOn: $hasItching)
                        .accessibilityIdentifier("logEntryItchingToggle")

                    Toggle("Swollen", isOn: $isSwollen)
                        .accessibilityIdentifier("logEntrySwollenToggle")
                }
            }
            .navigationTitle("Create Log Entry")
            .accessibilityIdentifier("logEntryCreationTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let logEntry = LogEntry(
                            id: UUID(),
                            timestamp: Date(),
                            imageFilename: "",
                            note: note,
                            painScore: painScore,
                            hasBleeding: hasBleeding,
                            hasItching: hasItching,
                            isSwollen: isSwollen,
                            estimatedSize: nil,
                            spot: selectedSpot
                        )
                        modelContext.insert(logEntry)
                        dismiss()
                    }
                    .disabled(selectedSpot == nil || spots.isEmpty)
                    .accessibilityIdentifier("saveLogEntryButton")
                }
            }
            .onAppear {
                if spots.isEmpty {
                    // Show error and dismiss
                    dismiss()
                }
                selectedSpot = spots.first
            }
        }
    }
}

#Preview {
    DebugDashboardView()
        .modelContainer(for: [UserProfile.self, Spot.self, LogEntry.self], inMemory: true)
}