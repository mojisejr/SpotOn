//
//  ContentView.swift
//  SpotOn
//
//  Created by Non on 11/28/25.
//

import SwiftUI
import SwiftData

/// Main content view that presents the HomeView
/// This is the root view of the SpotOn application
struct ContentView: View {
    /// SwiftData model context
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HomeView()
    }
}

