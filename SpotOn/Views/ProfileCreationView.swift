import SwiftUI
import SwiftData

struct ProfileCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var selectedRelation = "Self"

    let relations = ["Self", "Spouse", "Child", "Parent", "Sibling", "Other"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Name", text: $name)
                        .accessibilityIdentifier("profileNameTextField")

                    Picker("Relation", selection: $selectedRelation) {
                        ForEach(relations, id: \.self) { relation in
                            Text(relation).tag(relation)
                        }
                    }
                    .accessibilityIdentifier("profileRelationPicker")
                }
            }
            .navigationTitle("Create Profile")
            .accessibilityIdentifier("profileCreationTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let profile = UserProfile(
                            id: UUID(),
                            name: name,
                            relation: selectedRelation,
                            avatarColor: "blue",
                            createdAt: Date()
                        )
                        modelContext.insert(profile)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .accessibilityIdentifier("saveProfileButton")
                }
            }
        }
    }
}

#Preview {
    ProfileCreationView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}