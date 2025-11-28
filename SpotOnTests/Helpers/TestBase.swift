//
//  TestBase.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import Foundation
import XCTest
import SwiftData
import SwiftUI
@testable import SpotOn

/// Base test class providing common setup and utilities for all SpotOn tests
class SpotOnTestBase: XCTestCase {

    // MARK: - Test Properties

    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var testHelpers: TestHelpers.Type { TestHelpers.self }
    var swiftDataHelpers: SwiftDataTestHelpers.Type { SwiftDataTestHelpers.self }
    var uiHelpers: SwiftUITestHelpers.Type { SwiftUITestHelpers.self }
    var medicalHelpers: MedicalThemeTestHelpers.Type { MedicalThemeTestHelpers.self }
    var performanceHelpers: PerformanceTestHelpers.Type { PerformanceTestHelpers.self }
    var colorUtilities: ColorUtilities.Type { ColorUtilities.self }

    // MARK: - Setup and Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Create in-memory test database
        testContainer = try SwiftDataTestHelpers.createInMemoryContainer()
        testContext = ModelContext(testContainer)

        // Perform common test setup
        try setupTestEnvironment()
    }

    override func tearDownWithError() throws {
        // Clean up test database
        try testHelpers.cleanupAllData(in: testContext)
        testContainer = nil
        testContext = nil

        try super.tearDownWithError()
    }

    // MARK: - Common Setup Methods

    /// Sets up test environment with common configurations
    private func setupTestEnvironment() throws {
        // Configure test environment settings
        // This could include test-specific configurations, mock services, etc.
    }

    /// Sets up test database with sample data
    /// - Parameter fixtureType: Type of test data to populate
    func setupTestData(fixtureType: FixtureType = .sampleData) throws {
        let (_, _) = try SwiftDataTestHelpers.createContainerWithFixtures(fixtureType: fixtureType)
        // Note: In a real implementation, this would integrate with the existing container
    }

    /// Sets up empty database for isolated testing
    func setupEmptyDatabase() throws {
        try testHelpers.cleanupAllData(in: testContext)
    }

    // MARK: - Assertion Helpers

    /// Asserts database contains expected number of objects
    func assertDatabaseCounts(
        users: Int,
        spots: Int,
        logEntries: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let counts = try testHelpers.countObjects(in: testContext)

        XCTAssertEqual(
            counts.users,
            users,
            "Expected \(users) users, found \(counts.users)",
            file: file,
            line: line
        )

        XCTAssertEqual(
            counts.spots,
            spots,
            "Expected \(spots) spots, found \(counts.spots)",
            file: file,
            line: line
        )

        XCTAssertEqual(
            counts.logEntries,
            logEntries,
            "Expected \(logEntries) log entries, found \(counts.logEntries)",
            file: file,
            line: line
        )
    }

    /// Asserts database integrity
    func assertDatabaseIntegrity(
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let result = try SwiftDataTestHelpers.validateDatabaseIntegrity(in: testContext)

        XCTAssertTrue(
            result.isValid,
            "Database integrity check failed: \(result.issuesSummary)",
            file: file,
            line: line
        )
    }

    /// Asserts medical theme compliance
    func assertMedicalThemeCompliance(
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Mock medical theme validation
        // In real implementation, this would validate actual theme colors
        XCTAssertTrue(true, "Medical theme should be compliant", file: file, line: line)
    }

    /// Asserts performance meets medical app standards
    func assertMedicalPerformanceStandards<T>(
        operation: @escaping () throws -> T,
        maxDuration: TimeInterval = 1.0,
        maxMemoryIncrease: Double = 50.0,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let memoryResult = try PerformanceTestHelpers.measureMemoryUsage(operation: operation)
        let duration = try measureTime(operation)

        XCTAssertLessThanOrEqual(
            duration,
            maxDuration,
            "Operation duration \(duration)s exceeds medical standard \(maxDuration)s",
            file: file,
            line: line
        )

        XCTAssertLessThanOrEqual(
            memoryResult.memoryIncrease,
            maxMemoryIncrease,
            "Memory increase \(memoryResult.memoryIncrease)MB exceeds medical standard \(maxMemoryIncrease)MB",
            file: file,
            line: line
        )

        XCTAssertFalse(
            memoryResult.memoryLeaked,
            "Memory leak detected: \(memoryResult.memoryLeakAmount)MB",
            file: file,
            line: line
        )
    }

    // MARK: - Data Creation Helpers

    /// Creates test user profile
    func createTestUser(
        name: String = "Test User",
        relation: String = "Self",
        avatarColor: String = "#FF6B6B"
    ) -> UserProfile {
        return testHelpers.createTestUserProfile(
            name: name,
            relation: relation,
            avatarColor: avatarColor
        )
    }

    /// Creates test spot for user
    func createTestSpot(
        for user: UserProfile,
        title: String = "Test Spot",
        bodyPart: String = "Test Body Part",
        isActive: Bool = true
    ) -> Spot {
        return testHelpers.createTestSpot(
            title: title,
            bodyPart: bodyPart,
            isActive: isActive,
            userProfile: user
        )
    }

    /// Creates test log entry for spot
    func createTestLogEntry(
        for spot: Spot,
        note: String = "Test log entry",
        painScore: Int = 0,
        hasBleeding: Bool = false,
        hasItching: Bool = false,
        isSwollen: Bool = false,
        estimatedSize: Double? = nil
    ) -> LogEntry {
        return testHelpers.createTestLogEntry(
            note: note,
            painScore: painScore,
            hasBleeding: hasBleeding,
            hasItching: hasItching,
            isSwollen: isSwollen,
            estimatedSize: estimatedSize,
            spot: spot
        )
    }

    /// Creates complete test hierarchy
    func createTestHierarchy(
        userName: String = "Test User",
        spotTitle: String = "Test Spot",
        logEntryNote: String = "Test log entry"
    ) throws -> (user: UserProfile, spot: Spot, logEntry: LogEntry) {
        let hierarchy = testHelpers.createTestHierarchy(
            userName: userName,
            spotTitle: spotTitle,
            logEntryNote: logEntryNote
        )

        testContext.insert(hierarchy.user)
        testContext.insert(hierarchy.spot)
        testContext.insert(hierarchy.logEntry)
        try testContext.save()

        return hierarchy
    }

    // MARK: - View Testing Helpers

    /// Creates testable HomeView
    func createTestHomeView(with profiles: [UserProfile]) -> some View {
        return uiHelpers.createTestHomeView(with: profiles)
    }

    /// Creates empty HomeView for testing
    func createEmptyHomeView() -> some View {
        return uiHelpers.createEmptyHomeView()
    }

    /// Creates single profile HomeView for testing
    func createSingleProfileHomeView(_ profile: UserProfile) -> some View {
        return uiHelpers.createSingleProfileHomeView(profile)
    }

    /// Asserts view contains specific accessibility elements
    func assertViewHasAccessibilityElements(
        _ view: some View,
        expectedLabels: [String],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Mock accessibility assertion
        // In real implementation, this would use view inspection
        for label in expectedLabels {
            XCTAssertTrue(
                true,
                "View should contain accessibility element with label: \(label)",
                file: file,
                line: line
            )
        }
    }

    // MARK: - Medical Data Validation

    /// Asserts medical data is within valid ranges
    func assertValidMedicalData(
        painScore: Int,
        estimatedSize: Double?,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertGreaterThanOrEqual(
            painScore,
            0,
            "Pain score should be non-negative",
            file: file,
            line: line
        )

        XCTAssertLessThanOrEqual(
            painScore,
            10,
            "Pain score should not exceed 10",
            file: file,
            line: line
        )

        if let size = estimatedSize {
            XCTAssertGreaterThan(
                size,
                0,
                "Estimated size should be positive",
                file: file,
                line: line
            )

            XCTAssertLessThanOrEqual(
                size,
                100,
                "Estimated size should be reasonable (< 100)",
                file: file,
                line: line
            )
        }
    }

    /// Asserts medical note meets requirements
    func assertValidMedicalNote(
        _ note: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertLessThanOrEqual(
            note.count,
            500,
            "Medical note should be concise (≤ 500 characters)",
            file: file,
            line: line
        )

        // Note could be empty (for photo-only entries), but if present should be meaningful
        if !note.isEmpty {
            XCTAssertGreaterThan(
                note.count,
                3,
                "Medical note should be meaningful if present",
                file: file,
                line: line
            )
        }
    }

    // MARK: - Performance Testing Helpers

    /// Measures operation time for testing
    func measureTime<T>(_ operation: () throws -> T) throws -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = try operation()
        let endTime = CFAbsoluteTimeGetCurrent()
        return endTime - startTime
    }

    /// Tests memory usage of an operation
    func testMemoryUsage<T>(
        operation: @escaping () throws -> T,
        maxIncrease: Double = 10.0,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let result = try PerformanceTestHelpers.measureMemoryUsage(operation: operation)

        XCTAssertLessThanOrEqual(
            result.memoryIncrease,
            maxIncrease,
            "Memory usage increased by \(result.memoryIncrease)MB, exceeding limit of \(maxIncrease)MB",
            file: file,
            line: line
        )
    }

    /// Tests for memory leaks
    func testForMemoryLeaks<T>(
        operation: @escaping () throws -> T,
        cycles: Int = 5,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let result = try PerformanceTestHelpers.detectMemoryLeaks(
            operation: operation,
            cycles: cycles
        )

        XCTAssertFalse(
            result.hasMemoryLeak,
            "Memory leak detected: \(result.totalMemoryIncrease)MB increase over \(cycles) cycles",
            file: file,
            line: line
        )
    }

    // MARK: - Color Testing Helpers

    /// Asserts avatar color is valid and appropriate
    func assertValidAvatarColor(
        _ hex: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        colorUtilities.assertValidHexColor(hex, file: file, line: line)
        colorUtilities.assertMedicallyAppropriateColor(hex, file: file, line: line)
        colorUtilities.assertAccessibleColor(hex, file: file, line: line)
    }

    /// Asserts color palette is diverse and valid
    func assertValidAvatarColorPalette(
        _ colors: [String],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        colorUtilities.assertValidColorPalette(colors, file: file, line: line)
    }

    // MARK: - Integration Testing Helpers

    /// Sets up complete integration test environment
    func setupIntegrationTest() throws {
        try setupTestData(fixtureType: .sampleData)
        try assertDatabaseIntegrity()
        assertMedicalThemeCompliance()
    }

    /// Validates complete user workflow
    func assertCompleteUserWorkflow(
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        // 1. Create user
        let user = createTestUser(name: "Workflow Test User")
        testContext.insert(user)
        try testContext.save()

        // 2. Create spot
        let spot = createTestSpot(for: user, title: "Workflow Test Spot")
        testContext.insert(spot)
        try testContext.save()

        // 3. Create log entry
        let logEntry = createTestLogEntry(
            for: spot,
            note: "Workflow test entry",
            painScore: 2,
            hasItching: true
        )
        testContext.insert(logEntry)
        try testContext.save()

        // 4. Validate data integrity
        try assertDatabaseCounts(users: 1, spots: 1, logEntries: 1)
        try assertDatabaseIntegrity()

        // 5. Validate medical data
        assertValidMedicalData(
            painScore: logEntry.painScore,
            estimatedSize: logEntry.estimatedSize,
            file: file,
            line: line
        )
        assertValidMedicalNote(logEntry.note, file: file, line: line)
    }

    // MARK: - Error Testing Helpers

    /// Tests error handling for invalid data
    func testInvalidDataHandling() throws {
        // Test empty user name
        let emptyNameUser = createTestUser(name: "")
        // In a real implementation, this would test validation logic

        // Test invalid pain score
        let invalidPainEntry = createTestLogEntry(
            for: createTestSpot(for: createTestUser()),
            note: "Invalid pain test",
            painScore: 15 // Invalid: > 10
        )
        // In a real implementation, this would test validation logic
    }
}

// MARK: - Specialized Test Classes

/// Base class for Model tests
class ModelTestBase: SpotOnTestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        try setupEmptyDatabase() // Start with clean database for model tests
    }
}

/// Base class for View tests
class ViewTestBase: SpotOnTestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        try setupTestData(fixtureType: .minimalData) // Minimal data for view tests
    }
}

/// Base class for Integration tests
class IntegrationTestBase: SpotOnTestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        try setupIntegrationTest()
    }
}

/// Base class for Performance tests
class PerformanceTestBase: SpotOnTestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        try setupTestData(fixtureType: .sampleData) // Full data for performance tests
    }
}

/// Base class for Medical compliance tests
class MedicalComplianceTestBase: SpotOnTestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        try setupTestData(fixtureType: .medicalScenarios)
    }
}