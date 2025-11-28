//
//  ContentViewTests.swift
//  SpotOnTests
//
//  Created by non on 28/11/2025.
//

import XCTest
import SwiftData
@testable import SpotOn

final class ContentViewTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        // Create in-memory model container for testing
        let schema = Schema([Item.self])
        modelContainer = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        modelContext = modelContainer.mainContext
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }

    func testAddItem() throws {
        // Given
        let item = Item(timestamp: Date())

        // When
        modelContext.insert(item)
        try modelContext.save()

        // Then
        let fetchDescriptor = FetchDescriptor<Item>()
        let items = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.timestamp, item.timestamp)
    }

    func testDeleteItem() throws {
        // Given
        let item = Item(timestamp: Date())
        modelContext.insert(item)
        try modelContext.save()

        // When
        modelContext.delete(item)
        try modelContext.save()

        // Then
        let fetchDescriptor = FetchDescriptor<Item>()
        let items = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(items.count, 0)
    }
}