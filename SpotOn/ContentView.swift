//
//  ContentView.swift
//  SpotOn
//
//  Created by nonthasak laoluerat on 27/11/2568 BE.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    @State private var showAlert = false

    // Medical theme color (#007AFF)
    private let medicalBlue = Color(red: 0.0, green: 0.48, blue: 1.0)

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()

                // Hero Title
                Text("simple! click me!")
                    .font(.system(size: geometry.size.width * 0.08, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Spacer()

                // SpotOn Button
                Button(action: {
                    showAlert = true
                }) {
                    Text("SpotOn")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(minWidth: 200, minHeight: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(medicalBlue)
                                .shadow(color: medicalBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.1), value: showAlert)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
        .alert("SpotOn", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("SpotOn OK! let's implement the real app")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
