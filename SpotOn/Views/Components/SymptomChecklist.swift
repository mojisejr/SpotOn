//
//  SymptomChecklist.swift
//  SpotOn
//
//  Created by Non on 11/29/25.
//

import SwiftUI

struct SymptomChecklist: View {
    @Binding var hasBleeding: Bool
    @Binding var hasItching: Bool
    @Binding var isSwollen: Bool

    var symptomCount: Int {
        [hasBleeding, hasItching, isSwollen].filter { $0 }.count
    }

    struct SymptomItem: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let color: Color
        @Binding var isSelected: Bool

        var systemImage: String {
            isSelected ? icon + ".fill" : icon
        }
    }

    private var symptoms: [SymptomItem] {
        [
            SymptomItem(
                title: "Bleeding",
                icon: "drop.fill",
                color: .red,
                isSelected: $hasBleeding
            ),
            SymptomItem(
                title: "Itching",
                icon: "hand.point.up.left",
                color: .orange,
                isSelected: $hasItching
            ),
            SymptomItem(
                title: "Swelling",
                icon: "circle.fill",
                color: .blue,
                isSelected: $isSwollen
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Symptoms")
                    .font(.headline)
                    .fontWeight(.medium)

                if symptomCount > 0 {
                    Text("\(symptomCount) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(symptoms) { symptom in
                    SymptomCheckbox(item: symptom)
                        .accessibilityLabel("\(symptom.title) symptom")
                        .accessibilityAddTraits(symptom.isSelected ? .isSelected : [])
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct SymptomCheckbox: View {
    let item: SymptomChecklist.SymptomItem

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                item.isSelected.toggle()
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: item.systemImage)
                    .font(.title2)
                    .foregroundColor(item.isSelected ? item.color : .secondary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(item.isSelected ? item.color.opacity(0.1) : Color.secondary.opacity(0.05))
                            .overlay(
                                Circle()
                                    .stroke(item.isSelected ? item.color.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    )

                Text(item.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(item.isSelected ? .primary : .secondary)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.isSelected ? item.color.opacity(0.05) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(item.isSelected ? item.color.opacity(0.2) : Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(item.isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: item.isSelected)
    }
}

// MARK: - Preview Helpers

extension SymptomChecklist {
    static func previewData() -> (hasBleeding: Bool, hasItching: Bool, isSwollen: Bool) {
        return (hasBleeding: false, hasItching: true, isSwollen: false)
    }
}

#Preview {
    VStack(spacing: 20) {
        SymptomChecklist(
            hasBleeding: .constant(false),
            hasItching: .constant(false),
            isSwollen: .constant(false)
        )

        Divider()

        SymptomChecklist(
            hasBleeding: .constant(false),
            hasItching: .constant(true),
            isSwollen: .constant(false)
        )
    }
    .padding()
}