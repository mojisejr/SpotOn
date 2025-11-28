//
//  DataViewerView.swift
//  SpotOn
//
//  Created by Non on 11/28/25.
//

import SwiftUI
import SwiftData
import Combine

struct DataViewerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var userProfiles: [UserProfile]
    @StateObject private var imageManager = ImageManager()

    @State private var searchText = ""
    @State private var showingClearConfirmation = false
    @State private var showingExportOptions = false
    @State private var exportData = ""

    var filteredProfiles: [UserProfile] {
        if searchText.isEmpty {
            return userProfiles
        } else {
            return userProfiles.filter { profile in
                profile.name.localizedCaseInsensitiveContains(searchText) ||
                profile.relation.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Statistics Header
                VStack(spacing: 8) {
                    Text("Database Statistics")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)

                    HStack(spacing: 16) {
                        StatisticView(
                            label: "Profiles:",
                            value: "\(userProfiles.count)",
                            identifier: "totalProfilesLabel"
                        )

                        StatisticView(
                            label: "Spots:",
                            value: "\(userProfiles.flatMap { $0.spots }.count)",
                            identifier: "totalSpotsLabel"
                        )

                        StatisticView(
                            label: "Log Entries:",
                            value: "\(userProfiles.flatMap { $0.spots }.flatMap { $0.logEntries }.count)",
                            identifier: "totalLogEntriesLabel"
                        )

                        StatisticView(
                            label: "Images:",
                            value: "\(imageManager.getAllSavedImages().count)",
                            identifier: "totalImagesLabel"
                        )
                    }
                    .padding(.horizontal)
                }
                .background(Color(.systemGray6))
                .padding(.bottom, 8)

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search profiles, spots, or log entries...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .accessibilityIdentifier("dataSearchField")
                }
                .padding(.horizontal)

                // Data Content
                if filteredProfiles.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "tray")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)

                        Text("No data found")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Create some profiles, spots, or log entries to see them here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("emptyStateMessage")

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredProfiles, id: \.id) { profile in
                                ProfileDataView(profile: profile)
                            }
                        }
                        .padding()
                    }
                    .accessibilityIdentifier("dataScrollView")
                }
            }
            .navigationTitle("Data Viewer")
            .accessibilityIdentifier("dataViewerTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        refreshData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityIdentifier("refreshDataButton")

                    Button(action: {
                        prepareExportData()
                        showingExportOptions = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("exportDataButton")

                    Button(action: {
                        showingClearConfirmation = true
                    }) {
                        Image(systemName: "trash")
                    }
                    .accessibilityIdentifier("clearDataButton")
                }
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportDataView(data: exportData)
        }
        .alert("Clear All Data", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All Data", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will permanently delete all profiles, spots, log entries, and images. This action cannot be undone.")
        }
        .accessibilityIdentifier("dataContainer")
    }

    private func refreshData() {
        // Force refresh by triggering objectWillChange on ImageManager
        imageManager.objectWillChange.send()
    }

    private func prepareExportData() {
        var exportText = "SpotOn Database Export\n"
        exportText += "Generated: \(Date())\n\n"

        for profile in userProfiles {
            exportText += "Profile: \(profile.name)\n"
            exportText += "Relation: \(profile.relation)\n"
            exportText += "Created: \(profile.createdAt)\n"

            for spot in profile.spots.sorted(by: { $0.createdAt < $1.createdAt }) {
                exportText += "  Spot: \(spot.title)\n"
                exportText += "  Body Part: \(spot.bodyPart)\n"
                exportText += "  Active: \(spot.isActive ? "Yes" : "No")\n"
                exportText += "  Created: \(spot.createdAt)\n"

                for logEntry in spot.logEntries.sorted(by: { $0.timestamp < $1.timestamp }) {
                    exportText += "    Log Entry: \(logEntry.timestamp)\n"
                    exportText += "    Note: \(logEntry.note)\n"
                    exportText += "    Pain Score: \(logEntry.painScore)/10\n"
                    exportText += "    Bleeding: \(logEntry.hasBleeding ? "Yes" : "No")\n"
                    exportText += "    Itching: \(logEntry.hasItching ? "Yes" : "No")\n"
                    exportText += "    Swollen: \(logEntry.isSwollen ? "Yes" : "No")\n"
                    if !logEntry.imageFilename.isEmpty {
                        exportText += "    Image: \(logEntry.imageFilename)\n"
                    }
                    exportText += "\n"
                }
                exportText += "\n"
            }
            exportText += "\n" + String(repeating: "-", count: 50) + "\n\n"
        }

        exportData = exportText
    }

    private func clearAllData() {
        do {
            // Delete all SwiftData objects
            try modelContext.delete(model: UserProfile.self)
            try modelContext.delete(model: Spot.self)
            try modelContext.delete(model: LogEntry.self)

            // Delete all images
            try imageManager.deleteAllImages()

            // Save the context
            try modelContext.save()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
}

// MARK: - Profile Data View

struct ProfileDataView: View {
    let profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Profile Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Circle()
                        .fill(Color(profile.avatarColor))
                        .frame(width: 12, height: 12)

                    Text(profile.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("profileName")

                    Spacer()

                    Text(profile.relation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                        .accessibilityIdentifier("profileRelation")
                }

                Text("Created: \(profile.createdAt, format: .dateTime.month().day().year())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("profileDate")
            }
            .padding()
            .background(Color(.systemGray6))
            .accessibilityIdentifier("profile_\(profile.name)")

            // Spots
            if profile.spots.isEmpty {
                HStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 20)

                    Text("No spots")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
                .padding(.horizontal)
            } else {
                ForEach(profile.spots.sorted(by: { $0.createdAt < $1.createdAt }), id: \.id) { spot in
                    SpotDataView(spot: spot)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.vertical, 4)
    }
}

// MARK: - Spot Data View

struct SpotDataView: View {
    let spot: Spot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Spot Header
            HStack {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 20)

                Circle()
                    .fill(spot.isActive ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)

                Text(spot.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .accessibilityIdentifier("spotTitle")

                Spacer()

                Text(spot.bodyPart)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("spotBodyPart")

                Text(spot.isActive ? "Active" : "Inactive")
                    .font(.caption2)
                    .foregroundColor(spot.isActive ? .green : .gray)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(spot.isActive ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(3)
                    .accessibilityIdentifier("spotStatus")
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)

            // Log Entries
            if spot.logEntries.isEmpty {
                HStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 40)

                    Text("No log entries")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }
            } else {
                ForEach(spot.logEntries.sorted(by: { $0.timestamp < $1.timestamp }), id: \.id) { logEntry in
                    LogEntryDataView(logEntry: logEntry, entryIndex: spot.logEntries.sorted(by: { $0.timestamp < $1.timestamp }).firstIndex(of: logEntry)! + 1)
                }
            }
        }
    }
}

// MARK: - Log Entry Data View

struct LogEntryDataView: View {
    let logEntry: LogEntry
    let entryIndex: Int

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Rectangle()
                .fill(Color.clear)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Entry \(entryIndex)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)

                    Spacer()

                    Text(logEntry.timestamp, format: .dateTime.month().day().hour().minute())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("logEntryDate")
                }

                if !logEntry.note.isEmpty {
                    Text("Note: \(logEntry.note)")
                        .font(.caption2)
                        .foregroundColor(.primary)
                        .accessibilityIdentifier("logEntryNote")
                }

                HStack(spacing: 12) {
                    Text("Pain: \(logEntry.painScore)/10")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .accessibilityIdentifier("logEntryPainScore")

                    let symptoms = [
                        (logEntry.hasBleeding, "Bleeding"),
                        (logEntry.hasItching, "Itching"),
                        (logEntry.isSwollen, "Swollen")
                    ].filter { $0.0 }.map { $0.1 }

                    if !symptoms.isEmpty {
                        Text("Symptoms: \(symptoms.joined(separator: ", "))")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .accessibilityIdentifier("logEntrySymptoms")
                    }
                }

                if !logEntry.imageFilename.isEmpty {
                    Text("Image: \(logEntry.imageFilename)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal, 12)
        .accessibilityIdentifier("logEntry_\(entryIndex)")
    }
}

// MARK: - Statistic View

struct StatisticView: View {
    let label: String
    let value: String
    let identifier: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)")
        .accessibilityIdentifier(identifier)
    }
}

// MARK: - Export Data View

struct ExportDataView: View {
    let data: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text(data)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: data) {
                        Text("Share")
                    }
                }
            }
        }
    }
}

#Preview {
    DataViewerView()
        .modelContainer(for: [UserProfile.self, Spot.self, LogEntry.self], inMemory: true)
}