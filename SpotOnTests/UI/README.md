# UI Tests for SpotOn Debug Components

This directory contains comprehensive UI tests for the Phase 1 Debug UI components of the SpotOn iOS app.

## Test Files

### 1. DebugDashboardTests.swift
Tests the main debug dashboard interface including:
- Dashboard loading and initial state
- Real-time counter displays (Profiles, Spots, Log Entries, Images)
- CRUD button functionality and navigation
- Counter updates after data creation
- Error handling for missing data
- Accessibility compliance
- Performance metrics

### 2. DataViewerTests.swift
Tests the hierarchical data viewer interface including:
- Data viewer loading and empty states
- Hierarchical display: UserProfile → Spot → LogEntry
- Visual indentation for relationships
- Data refresh functionality
- Data export capabilities
- Data clearing with confirmation
- Search and filtering
- Scrolling performance
- Accessibility compliance

### 3. ImageTestViewTests.swift
Tests the image save/load interface including:
- Image test view loading and empty states
- Photo picker integration
- Camera integration
- Image save functionality
- Image load functionality
- Image information display
- Batch operations
- Image editing features
- Permission handling
- Error handling and validation
- Performance metrics
- Accessibility compliance

## Test Coverage Areas

### Core Functionality
- ✅ Button interactions and navigation
- ✅ Data display accuracy
- ✅ Real-time counter updates
- ✅ Hierarchical relationship visualization
- ✅ Image save/load operations

### Error Handling
- ✅ Missing data scenarios
- ✅ Permission denied states
- ✅ Storage full conditions
- ✅ Network connectivity issues
- ✅ Invalid input validation

### User Experience
- ✅ Accessibility compliance (VoiceOver)
- ✅ Visual hierarchy and indentation
- ✅ Loading states and progress indicators
- ✅ Confirmation dialogs and alerts
- ✅ Performance and responsiveness

### Integration Testing
- ✅ Navigation between debug screens
- ✅ Data persistence across screens
- ✅ Real-time data synchronization
- ✅ Cross-component functionality

## Test Structure

All UI tests follow the Red-Green-Refactor TDD pattern:

1. **RED Phase**: Tests written first, expecting failure (current state)
2. **GREEN Phase**: Implementation to make tests pass
3. **REFACTOR Phase**: Code quality improvements while maintaining passing tests

## Key Accessibility Identifiers

Tests use specific accessibility identifiers for reliable UI element interaction:

### DebugDashboard
- `debugDashboardTitle`
- `profileCountLabel`, `spotCountLabel`, `logEntryCountLabel`, `imageCountLabel`
- `createProfileButton`, `createSpotButton`, `createLogEntryButton`, `testImageButton`, `viewDataButton`

### DataViewer
- `dataViewerTitle`, `dataScrollView`, `refreshDataButton`
- `exportDataButton`, `clearDataButton`, `dataSearchField`
- `profile_[name]`, `spot_[title]`, `logEntry_[id]`

### ImageTestView
- `imageTestTitle`, `selectPhotoButton`, `takePhotoButton`
- `saveImageButton`, `loadImageButton`, `clearImagesButton`
- `imagePreview`, `imagePlaceholderText`

## Running Tests

```bash
# Build and run all tests
xcodebuild -scheme SpotOn -destination 'platform=iOS Simulator,name=iPhone 17' test

# Run specific UI test
xcodebuild test -scheme SpotOn -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SpotOnTests/DebugDashboardTests

# Run with performance metrics
xcodebuild test -scheme SpotOn -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SpotOnTests/UI -enablePerformanceTests
```

## Expected Behavior (RED Phase)

Currently, these tests should **FAIL** because:
1. The UI components don't exist yet (DebugDashboardView, DataViewerView, ImageTestView)
2. Accessibility identifiers haven't been implemented
3. Navigation structure hasn't been built
4. Data models and relationships aren't implemented

This is intentional and follows TDD methodology. The tests serve as specifications for the required functionality.

## Test Environment

- **Target**: iOS Simulator (iPhone 17 recommended)
- **iOS Version**: iOS 17.0+
- **Testing Framework**: XCTest with UI Testing
- **Launch Arguments**: `--uitesting` for test mode detection
- **Test Organization**: Centralized in `SpotOnTests/UI/` directory

## Notes

- Tests use accessibility identifiers instead of UI element labels for reliability
- All navigation tests include back-navigation scenarios
- Performance tests use XCTest metrics for objective measurement
- Error handling tests cover both user errors and system conditions
- Accessibility tests ensure VoiceOver compliance
- Tests are designed to be run in parallel where possible