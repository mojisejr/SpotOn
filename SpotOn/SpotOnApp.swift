//
//  SpotOnApp.swift
//  SpotOn
//
//  Created by nonthasak laoluerat on 27/11/2568 BE.
//

import SwiftUI
import SwiftData

@main
struct SpotOnApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Spot.self,
            LogEntry.self,
            Item.self, // Keep the existing Item model for compatibility
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            DebugDashboardView()
        }
        .modelContainer(sharedModelContainer)
    }
}
