# SpotOn Development Environment

## Environment Specification

### Current Development Environment (Updated: Nov 28, 2025)

**Xcode Version**: 26.1.1 (Build 17B100)
**Swift Version**: 6.2.1 (swiftlang-6.2.1.4.8 clang-1700.4.4.1)
**iOS Simulator Runtime**: 26.1 (com.apple.CoreSimulator.SimRuntime.iOS-26-1)
**Target iOS**: 17.0+ (minimum deployment target)

### Available iOS Simulators

**Recommended Simulators** (all running iOS 26.1):
- **iPhone 17** (83AE7B11-5419-49CF-A92F-D5F4891C4B89) - Primary choice ✅
- iPhone 17 Pro (B8367F4F-1D70-4B1E-A4FF-992959E8BDDF)
- iPhone 17 Pro Max (2B12275A-B77C-4A60-AA70-2326967904BF)
- iPhone 16e (322899F5-F527-4757-91F3-2943CDF1EF37)
- iPhone Air (BF7AAF64-EE42-4F25-B233-E3CC66802321)

**Note**: iPhone 15 is NOT available in this environment.

### Development Commands

**Build Commands** (use with iPhone 17 for primary testing):
```bash
# Build for simulator
xcodebuild -scheme SpotOn -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run tests
xcodebuild -scheme SpotOn -destination 'platform=iOS Simulator,name=iPhone 17' test

# Clean build
xcodebuild -scheme SpotOn -destination 'platform=iOS Simulator,name=iPhone 17' clean

# Alternative simulators (if needed)
xcodebuild -scheme SpotOn -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild -scheme SpotOn -destination 'platform=iOS Simulator,name=iPhone 16e' build
```

### Environment Verification Commands

```bash
# Check Xcode version
xcrun xcodebuild -version

# Check available simulators
xcrun simctl list devices available | grep "iPhone"

# Check Swift version
swift --version

# Check iOS runtimes
xcrun simctl list runtimes | grep "iOS"
```

### Project Stack Information

**Language**: Swift 6.2.1
**Framework**: SwiftUI (iOS 17.0+)
**Architecture**: MVVM
**Database**: SwiftData (local-first)
**Camera**: AVFoundation
**Storage**: Local documents directory

### File Locations Updated

The following files have been updated to reflect this environment:

1. **AGENTS.md** - Core stack and development commands updated
2. **CLAUDE.md** - Technical architecture and commands updated
3. **.claude/commands/impl.md** - Build validation commands updated
4. **ENVIRONMENT.md** - This environment specification file (new)

### Quick Reference

**Primary Simulator**: iPhone 17
**Build Command**: `xcodebuild -scheme SpotOn -destination 'platform=iOS Simulator,name=iPhone 17' build`
**Test Command**: `xcodebuild -scheme SpotOn -destination 'platform=iOS Simulator,name=iPhone 17' test`
**Runtime**: iOS 26.1
**Xcode**: 26.1.1

---
*This file serves as the single source of truth for the SpotOn development environment configuration.*