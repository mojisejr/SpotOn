//
//  LogEntryCardView.swift
//  SpotOn
//
//  Created by Non on 11/29/25.
//

import SwiftUI

/// Individual log entry card displaying comprehensive medical data
/// Features medical theme, symptom indicators, and accessibility support
struct LogEntryCardView: View {
    // MARK: - Properties

    /// The log entry to display
    let logEntry: LogEntry

    // MARK: - Medical Theme Colors

    private let medicalBlue = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
    private let cardBackgroundColor = Color.white
    private let textColor = Color.primary
    private let subtitleColor = Color.secondary

    // MARK: - Computed Properties

    /// Formatted relative time string
    private var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: logEntry.timestamp, relativeTo: Date())
    }

    /// Formatted full date string for accessibility
    private var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: logEntry.timestamp)
    }

    /// Pain score color
    private var painScoreColor: Color {
        switch logEntry.painScore {
        case 0:
            return .green
        case 1...3:
            return .yellow
        case 4...6:
            return .orange
        default:
            return .red
        }
    }

    /// Pain score description
    private var painScoreDescription: String {
        switch logEntry.painScore {
        case 0:
            return "No pain"
        case 1...2:
            return "Mild"
        case 3...4:
            return "Moderate"
        case 5...6:
            return "Moderate to severe"
        case 7...8:
            return "Severe"
        default:
            return "Very severe"
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with timestamp and pain score
            headerSection

            // Medical note
            if !logEntry.note.isEmpty {
                noteSection
            }

            // Medical data indicators
            medicalDataSection

            // Bottom row with image filename and additional info
            bottomSection
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("logEntryCardView")
    }

    // MARK: - View Components

    /// Header section with timestamp and pain score
    private var headerSection: some View {
        HStack {
            // Timestamp
            VStack(alignment: .leading, spacing: 4) {
                Text(relativeTimeString)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(textColor)
                    .accessibilityLabel(fullDateString)

                Text("Logged \(logEntry.timestamp, style: .time) on \(logEntry.timestamp, style: .date)")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(subtitleColor)
                    .accessibilityHidden(true) // Already announced in relative time
            }

            Spacer()

            // Pain score indicator
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(painScoreColor)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(logEntry.painScore)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(painScoreColor)

                    Text(painScoreDescription)
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(painScoreColor)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Pain score \(logEntry.painScore), \(painScoreDescription)")
            .accessibilityAddTraits(.updatesFrequently)
        }
        .accessibilityIdentifier("timestampLabel")
    }

    /// Medical note section
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(subtitleColor)
                .accessibilityHidden(true) // Decorative label

            Text(logEntry.note)
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(textColor)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
                .accessibilityIdentifier("noteLabel")
        }
    }

    /// Medical data section with symptom indicators
    private var medicalDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Symptoms row
            HStack(spacing: 12) {
                // Bleeding indicator
                SymptomIndicatorView(
                    symptom: "Bleeding",
                    isPresent: logEntry.hasBleeding,
                    icon: "drop.fill",
                    color: .red
                )
                .accessibilityIdentifier("bleedingIndicator")

                // Itching indicator
                SymptomIndicatorView(
                    symptom: "Itching",
                    isPresent: logEntry.hasItching,
                    icon: "hand.point.up.left.fill",
                    color: .orange
                )
                .accessibilityIdentifier("itchingIndicator")

                // Swelling indicator
                SymptomIndicatorView(
                    symptom: "Swelling",
                    isPresent: logEntry.isSwollen,
                    icon: "arrow.up.left.and.arrow.down.right.fill",
                    color: .blue
                )
                .accessibilityIdentifier("swollenIndicator")

                Spacer()
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("symptomIndicators")

            // Estimated size
            if let estimatedSize = logEntry.estimatedSize {
                HStack {
                    Image(systemName: "ruler.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(medicalBlue)

                    Text("Estimated size: \(String(format: "%.1f", estimatedSize)) mm")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(textColor)

                    Spacer()
                }
                .accessibilityLabel("Estimated size \(String(format: "%.1f", estimatedSize)) millimeters")
                .accessibilityIdentifier("estimatedSizeLabel")
            }
        }
    }

    /// Bottom section with image filename
    private var bottomSection: some View {
        HStack {
            // Image filename indicator
            if !logEntry.imageFilename.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(medicalBlue)

                    Text(logEntry.imageFilename)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(subtitleColor)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .accessibilityLabel("Photo: \(logEntry.imageFilename)")
                .accessibilityIdentifier("imageThumbnail")
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)

                    Text("No photo")
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundColor(.gray)
                }
                .accessibilityLabel("No photo included")
            }

            Spacer()
        }
    }
}

// MARK: - Symptom Indicator View

/// Small component for displaying symptom indicators with consistent styling
struct SymptomIndicatorView: View {
    let symptom: String
    let isPresent: Bool
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isPresent ? color : .gray.opacity(0.5))

            Text(symptom)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(isPresent ? color : .gray.opacity(0.5))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isPresent ? color.opacity(0.1) : Color.gray.opacity(0.1))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isPresent ? "\(symptom): Present" : "\(symptom): Not present")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview("Comprehensive Medical Data") {
    LogEntryCardView(
        logEntry: LogEntry(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
            imageFilename: "MEDICAL_COMPREHENSIVE.jpg",
            note: "Significant changes observed today. The area appears more inflamed than yesterday, with increased redness and slight swelling. Applied cold compress and monitoring closely. Consider doctor visit if condition worsens.",
            painScore: 7,
            hasBleeding: true,
            hasItching: true,
            isSwollen: true,
            estimatedSize: 15.5,
            spot: nil
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Minimal Data") {
    LogEntryCardView(
        logEntry: LogEntry(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            imageFilename: "",
            note: "",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: nil
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("High Pain Score") {
    LogEntryCardView(
        logEntry: LogEntry(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .hour, value: -6, to: Date())!,
            imageFilename: "HIGH_PAIN.jpg",
            note: "Severe pain experienced, immediate medical attention required",
            painScore: 10,
            hasBleeding: true,
            hasItching: false,
            isSwollen: true,
            estimatedSize: 25.0,
            spot: nil
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Single Symptom") {
    LogEntryCardView(
        logEntry: LogEntry(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .hour, value: -12, to: Date())!,
            imageFilename: "ITCHING_ONLY.jpg",
            note: "Only experiencing itching, no other symptoms present",
            painScore: 1,
            hasBleeding: false,
            hasItching: true,
            isSwollen: false,
            estimatedSize: 8.2,
            spot: nil
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Long Note") {
    LogEntryCardView(
        logEntry: LogEntry(
            id: UUID(),
            timestamp: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            imageFilename: "LONG_NOTE.jpg",
            note: String(repeating: "This is a very long medical note that contains detailed observations about the condition. ", count: 15),
            painScore: 3,
            hasBleeding: false,
            hasItching: true,
            isSwollen: false,
            estimatedSize: 6.7,
            spot: nil
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}