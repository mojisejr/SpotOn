# SpotOn Test Infrastructure

This directory contains comprehensive test utilities and helpers for the SpotOn Visual Medical Journal iOS app. The testing infrastructure follows Test-Driven Development (TDD) principles and provides specialized tools for medical app compliance testing.

## Directory Structure

```
SpotOnTests/Helpers/
├── TestBase.swift              # Base test class with common setup and assertions
├── TestHelpers.swift           # Basic test data factory and assertion helpers
├── SwiftDataTestHelpers.swift  # SwiftData in-memory database utilities
├── SwiftUITestHelpers.swift   # SwiftUI view testing and accessibility helpers
├── MedicalThemeTestHelpers.swift # Medical theme compliance validation
├── PerformanceTestHelpers.swift # Memory and performance benchmarking
├── ColorUtilities.swift        # Avatar color validation and accessibility
└── README.md                   # This documentation file
```

## Core Components

### 1. TestBase.swift
Base test class providing common setup, teardown, and assertion methods for all SpotOn tests.

**Usage:**
```swift
class HomeViewTests: ViewTestBase {
    func testProfileSelection() throws {
        // Test setup automatically handled by base class
        let user = createTestUser(name: "Test User")
        let homeView = createTestHomeView(with: [user])

        assertViewHasAccessibilityElements(homeView, expectedLabels: ["Test User, Self"])
    }
}
```

**Specialized Base Classes:**
- `ModelTestBase` - For SwiftData model tests
- `ViewTestBase` - For SwiftUI view tests
- `IntegrationTestBase` - For end-to-end integration tests
- `PerformanceTestBase` - For performance and memory tests
- `MedicalComplianceTestBase` - For medical compliance validation

### 2. TestHelpers.swift
Core test data factory and assertion helpers for creating and validating SwiftData models.

**Key Features:**
- Test data creation with sensible defaults
- Database setup with various fixture types
- Assertion helpers for model equality
- Cleanup utilities for test isolation

**Usage:**
```swift
func testUserProfileCreation() throws {
    let user = TestHelpers.createTestUserProfile(name: "John Doe", relation: "Self")

    // Test user properties
    XCTAssertEqual(user.name, "John Doe")
    XCTAssertEqual(user.relation, "Self")

    // Save and validate
    testContext.insert(user)
    try testContext.save()
}
```

### 3. SwiftDataTestHelpers.swift
Comprehensive SwiftData testing utilities for in-memory database isolation and data management.

**Key Features:**
- In-memory ModelContainer creation
- Predefined test fixtures (empty, sample, medical scenarios, edge cases)
- Database integrity validation
- Query helpers and relationship validation
- Memory cleanup and reset utilities

**Usage:**
```swift
func testDatabaseOperations() throws {
    // Create isolated test database
    let (container, context) = try SwiftDataTestHelpers.createContainerWithFixtures(
        fixtureType: .medicalScenarios
    )

    // Validate database integrity
    let result = try SwiftDataTestHelpers.validateDatabaseIntegrity(in: context)
    XCTAssertTrue(result.isValid)

    // Test queries
    let highPainEntries = try SwiftDataTestHelpers.fetchHighPainEntries(
        above: 5, from: context
    )
    XCTAssertGreaterThan(highPainEntries.count, 0)
}
```

### 4. SwiftUITestHelpers.swift
SwiftUI view testing utilities with focus on accessibility and medical app compliance.

**Key Features:**
- Mock HomeView for profile selection testing
- Accessibility validation helpers
- Dark mode and Dynamic Type testing
- Performance testing for view rendering
- Medical app specific UI validation

**Usage:**
```swift
func testHomeViewAccessibility() throws {
    let profiles = [
        createTestUser(name: "John Doe", relation: "Self"),
        createTestUser(name: "Jane Doe", relation: "Spouse")
    ]

    let homeView = createTestHomeView(with: profiles)
    assertViewHasAccessibilityElements(homeView, expectedLabels: [
        "John Doe, Self", "Jane Doe, Spouse"
    ])
    assertMedicalViewLayout(homeView)
}
```

### 5. MedicalThemeTestHelpers.swift
Medical theme compliance validation for ensuring the app meets medical app standards.

**Key Features:**
- Color accessibility validation (WCAG compliance)
- Medical color appropriateness checking
- Typography validation for medical readability
- Medical icon validation
- Data visualization accessibility
- Comprehensive accessibility testing

**Usage:**
```swift
func testMedicalThemeCompliance() throws {
    let colorScheme = MedicalColorScheme(
        primary: .blue,
        secondary: .gray,
        background: .white,
        accent: .blue,
        warning: .orange,
        error: .red,
        success: .green
    )

    let result = MedicalThemeTestHelpers.validateMedicalColorScheme(colorScheme)
    XCTAssertTrue(result.isAccessible, "Color scheme should meet medical standards")

    // Validate avatar colors
    let avatarColors = ["#FF6B6B", "#4ECDC4", "#45B7D1"]
    let avatarResult = MedicalThemeTestHelpers.validateAvatarColors(avatarColors)
    XCTAssertTrue(avatarResult.overallValid, "Avatar colors should be accessible")
}
```

### 6. PerformanceTestHelpers.swift
Memory and performance benchmarking utilities for ensuring medical app performance standards.

**Key Features:**
- Memory usage measurement and leak detection
- Database performance testing
- UI rendering performance
- Image processing performance
- Scroll performance testing
- Medical app performance thresholds

**Usage:**
```swift
func testMedicalPerformanceStandards() throws {
    // Test memory usage of image processing
    try assertMedicalPerformanceStandards(
        operation: {
            // Process medical image
            return processMedicalImage(imageData)
        },
        maxDuration: 3.0,  // 3 seconds
        maxMemoryIncrease: 100.0  // 100MB
    )

    // Test database performance
    let dbResult = PerformanceTestHelpers.testDatabasePerformance(context: testContext)
    XCTAssertLessThan(dbResult.averageInsertTime, 0.001) // 1ms per insert
}
```

### 7. ColorUtilities.swift
Specialized color utilities for avatar color validation and accessibility in medical contexts.

**Key Features:**
- Hex color validation and normalization
- Medical color appropriateness checking
- WCAG accessibility compliance testing
- Color blindness compatibility
- Color palette diversity validation
- Avatar color generation for testing

**Usage:**
```swift
func testAvatarColorValidation() throws {
    let validColor = "#FF6B6B"
    let invalidColor = "invalid"

    // Test valid color
    assertValidAvatarColor(validColor)

    // Test color palette
    let colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7"]
    assertValidAvatarColorPalette(colors)

    // Test color accessibility
    let result = ColorUtilities.validateMedicalAvatarColor(validColor)
    XCTAssertGreaterThanOrEqual(result.accessibilityScore, 70)
    XCTAssertTrue(result.isMedicallyAppropriate)
}
```

## Test Data Fixtures

The test infrastructure includes predefined test data fixtures in `/Fixtures/TestFixtures.swift`:

### User Profile Fixtures
- `UserProfiles.johnDoe` - Standard adult user
- `UserProfiles.janeDoe` - Spouse profile
- `UserProfiles.bobbyDoe` - Child profile
- `UserProfiles.emptyName` - Edge case with empty name
- `UserProfiles.emptyRelation` - Edge case with empty relation

### Spot Fixtures
- `Spots.moleOnArm` - Active mole tracking
- `Spots.rashOnChest` - Active rash monitoring
- `Spots.scarOnKnee` - Inactive scar tracking
- `Spots.birthmarkOnBack` - Birthmark monitoring
- `Spots.acneOnFace` - Active acne treatment

### Log Entry Fixtures
- `LogEntries.normalMoleEntry` - Normal observation
- `LogEntries.irritatedRashEntry` - Irritated condition
- `LogEntries.bleedingWoundEntry` - Medical emergency
- `LogEntries.swollenSpotEntry` - Swelling condition
- `LogEntries.highPainEntry` - High pain scenario

### Medical Scenarios
- `MedicalScenarios.noSymptoms` - Healthy condition
- `MedicalScenarios.minorSymptoms` - Minor medical issues
- `MedicalScenarios.moderateSymptoms` - Moderate medical concerns
- `MedicalScenarios.severeSymptoms` - Severe medical conditions

## Testing Best Practices

### 1. Test Organization
- Use appropriate base classes for different test types
- Group related tests in nested classes
- Use descriptive test method names following `test[Functionality]_[Scenario]` pattern

### 2. Test Data Management
- Use factory methods for creating test data
- Clean up test data in tearDown
- Use in-memory databases for test isolation
- Leverage predefined fixtures for consistency

### 3. Medical App Considerations
- Always test accessibility compliance
- Validate medical data ranges and formats
- Test performance under medical app standards
- Ensure color choices are medically appropriate

### 4. Performance Testing
- Set memory limits for operations
- Test with realistic data sizes
- Validate against medical app performance standards
- Test both light and dark modes

### 5. Error Handling
- Test edge cases and invalid data
- Validate error messages are user-friendly
- Ensure graceful degradation
- Test medical data validation

## Medical App Standards

### Color Requirements
- WCAG AA compliance (4.5:1 contrast ratio minimum)
- Medical color appropriateness (avoid confusion with medical indicators)
- Color blindness compatibility
- Sufficient saturation and brightness for visibility

### Performance Requirements
- App launch time < 2 seconds
- Database operations < 100ms
- Image processing < 3 seconds
- Memory usage < 50MB for standard operations
- 60 FPS for smooth scrolling

### Accessibility Requirements
- VoiceOver compatibility
- Dynamic Type support
- Sufficient touch targets (44x44 points minimum)
- Clear accessibility labels and hints
- Support for reduced motion

### Data Validation
- Pain scores: 0-10 range
- Temperature: 35.0-42.0°C range
- Heart rate: 40-200 BPM range
- Medical notes: 500 characters maximum
- Image sizes: Optimized for medical use

## Running Tests

### Unit Tests
```bash
xcodebuild test -scheme SpotOn -destination 'platform=iOS Simulator,name=iPhone 17'
```

### Performance Tests
Performance tests automatically measure:
- Memory usage
- Operation duration
- Database performance
- UI rendering performance

### Accessibility Tests
Accessibility tests validate:
- VoiceOver compatibility
- Color contrast ratios
- Dynamic Type support
- Touch target sizes
- Screen reader navigation

### Integration Tests
Integration tests cover:
- Complete user workflows
- Database operations
- UI interactions
- Data persistence
- Error handling

## Contributing

When adding new test utilities:

1. **Follow Naming Conventions**: Use clear, descriptive names following established patterns
2. **Document Thoroughly**: Include comprehensive documentation with usage examples
3. **Test Your Tests**: Ensure utilities themselves are well-tested
4. **Medical Compliance**: Consider medical app requirements in all utilities
5. **Performance Awareness**: Ensure utilities don't negatively impact test performance

## Troubleshooting

### Common Issues

**Test Database Not Found**
- Ensure `SwiftDataTestHelpers.createInMemoryContainer()` is called in setUp
- Check that all models are included in the container configuration

**Memory Leaks in Tests**
- Use `PerformanceTestHelpers.detectMemoryLeaks()` to identify issues
- Ensure proper cleanup in tearDown
- Check for retain cycles in test code

**Accessibility Test Failures**
- Verify accessibility labels are properly set
- Check color contrast ratios meet WCAG standards
- Ensure Dynamic Type support is implemented

**Performance Test Failures**
- Review operation implementations for efficiency
- Check for unnecessary object creation
- Verify database queries are optimized

### Debugging Tips

1. **Enable Debug Logging**: Add print statements to trace test execution
2. **Use Breakpoints**: Set breakpoints in test methods to debug state
3. **Inspect Database**: Use `SwiftDataTestHelpers.validateDatabaseIntegrity()` to check data
4. **Profile Memory**: Use Instruments to identify memory issues
5. **Check Accessibility**: Use Accessibility Inspector to validate UI

This comprehensive test infrastructure ensures that SpotOn meets medical app standards while providing a robust foundation for development and testing.