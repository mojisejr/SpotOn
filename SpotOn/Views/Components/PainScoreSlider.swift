//
//  PainScoreSlider.swift
//  SpotOn
//
//  Created by Non on 11/29/25.
//

import SwiftUI

struct PainScoreSlider: View {
    @Binding var painScore: Int
    let range: ClosedRange<Int> = 1...10

    // Pain level descriptions
    private let painLevels: [Int: String] = [
        1: "Minimal",
        2: "Very Mild",
        3: "Mild",
        4: "Moderate",
        5: "Moderate",
        6: "Moderately Severe",
        7: "Severe",
        8: "Severe",
        9: "Very Severe",
        10: "Worst Possible"
    ]

    // Pain colors for visual feedback
    private func painColor(for score: Int) -> Color {
        switch score {
        case 1...3:
            return Color.green
        case 4...6:
            return Color.orange
        case 7...8:
            return Color.red
        case 9...10:
            return Color.red.opacity(0.8)
        default:
            return Color.gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pain Score")
                    .font(.headline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(painScore)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(painColor(for: painScore))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(painColor(for: painScore).opacity(0.1))
                    )
            }

            Text(painLevels[painScore] ?? "Unknown")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Slider(
                value: Binding(
                    get: { Double(painScore) },
                    set: { painScore = Int(round($0)) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .accentColor(painColor(for: painScore))
            .accessibilityLabel("Pain score slider")
            .accessibilityValue("\(painScore) out of \(range.upperBound)")

            HStack {
                ForEach(Array(range), id: \.self) { score in
                    Text("\(score)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        PainScoreSlider(painScore: .constant(1))
        PainScoreSlider(painScore: .constant(5))
        PainScoreSlider(painScore: .constant(10))
    }
    .padding()
}