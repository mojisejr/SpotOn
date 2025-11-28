//
//  TestFixtures.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import Foundation
@testable import SpotOn

/// Contains predefined test data fixtures for consistent testing
struct TestFixtures {

    // MARK: - User Profile Fixtures

    struct UserProfiles {
        static let johnDoe = UserProfile(
            id: UUID(uuidString: "12345678-1234-5678-9ABC-123456789001")!,
            name: "John Doe",
            relation: "Self",
            avatarColor: "#FF6B6B",
            createdAt: Date(timeIntervalSince1970: 1640995200) // Jan 1, 2022
        )

        static let janeDoe = UserProfile(
            id: UUID(uuidString: "12345678-1234-5678-9ABC-123456789002")!,
            name: "Jane Doe",
            relation: "Spouse",
            avatarColor: "#4ECDC4",
            createdAt: Date(timeIntervalSince1970: 1640995200) // Jan 1, 2022
        )

        static let bobbyDoe = UserProfile(
            id: UUID(uuidString: "12345678-1234-5678-9ABC-123456789003")!,
            name: "Bobby Doe",
            relation: "Child",
            avatarColor: "#45B7D1",
            createdAt: Date(timeIntervalSince1970: 1640995200) // Jan 1, 2022
        )

        static let emptyName = UserProfile(
            id: UUID(uuidString: "12345678-1234-5678-9ABC-123456789004")!,
            name: "",
            relation: "Self",
            avatarColor: "#96CEB4",
            createdAt: Date(timeIntervalSince1970: 1640995200)
        )

        static let emptyRelation = UserProfile(
            id: UUID(uuidString: "12345678-1234-5678-9ABC-123456789005")!,
            name: "Test User",
            relation: "",
            avatarColor: "#FFEAA7",
            createdAt: Date(timeIntervalSince1970: 1640995200)
        )

        static let allUserProfiles = [johnDoe, janeDoe, bobbyDoe, emptyName, emptyRelation]
    }

    // MARK: - Spot Fixtures

    struct Spots {
        static let moleOnArm = Spot(
            id: UUID(uuidString: "87654321-4321-8765-CBA9-876543210001")!,
            title: "Mole on Left Arm",
            bodyPart: "Left Arm",
            isActive: true,
            createdAt: Date(timeIntervalSince1970: 1640995200),
            userProfile: UserProfiles.johnDoe
        )

        static let rashOnChest = Spot(
            id: UUID(uuidString: "87654321-4321-8765-CBA9-876543210002")!,
            title: "Red Rash on Chest",
            bodyPart: "Chest",
            isActive: true,
            createdAt: Date(timeIntervalSince1970: 1640995200),
            userProfile: UserProfiles.johnDoe
        )

        static let scarOnKnee = Spot(
            id: UUID(uuidString: "87654321-4321-8765-CBA9-876543210003")!,
            title: "Old Scar on Knee",
            bodyPart: "Right Knee",
            isActive: false,
            createdAt: Date(timeIntervalSince1970: 1640995200),
            userProfile: UserProfiles.janeDoe
        )

        static let birthmarkOnBack = Spot(
            id: UUID(uuidString: "87654321-4321-8765-CBA9-876543210004")!,
            title: "Birthmark on Back",
            bodyPart: "Upper Back",
            isActive: true,
            createdAt: Date(timeIntervalSince1970: 1640995200),
            userProfile: UserProfiles.bobbyDoe
        )

        static let acneOnFace = Spot(
            id: UUID(uuidString: "87654321-4321-8765-CBA9-876543210005")!,
            title: "Acne Breakout",
            bodyPart: "Face",
            isActive: true,
            createdAt: Date(timeIntervalSince1970: 1640995200),
            userProfile: UserProfiles.bobbyDoe
        )

        static let emptyTitle = Spot(
            id: UUID(uuidString: "87654321-4321-8765-CBA9-876543210006")!,
            title: "",
            bodyPart: "Arm",
            isActive: true,
            createdAt: Date(timeIntervalSince1970: 1640995200),
            userProfile: UserProfiles.johnDoe
        )

        static let emptyBodyPart = Spot(
            id: UUID(uuidString: "87654321-4321-8765-CBA9-876543210007")!,
            title: "Test Spot",
            bodyPart: "",
            isActive: true,
            createdAt: Date(timeIntervalSince1970: 1640995200),
            userProfile: UserProfiles.johnDoe
        )

        static let allSpots = [moleOnArm, rashOnChest, scarOnKnee, birthmarkOnBack, acneOnFace, emptyTitle, emptyBodyPart]

        static let activeSpots = [moleOnArm, rashOnChest, birthmarkOnBack, acneOnFace, emptyTitle, emptyBodyPart]
        static let inactiveSpots = [scarOnKnee]
    }

    // MARK: - Log Entry Fixtures

    struct LogEntries {
        static let normalMoleEntry = LogEntry(
            id: UUID(uuidString: "ABCDEF12-ABCD-EFGH-IJKL-ABCDEF123456")!,
            timestamp: Date(timeIntervalSince1970: 1640995200),
            imageFilename: "MOLE_NORMAL_001.jpg",
            note: "Mole looks normal today, no changes observed",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: 5.0,
            spot: Spots.moleOnArm
        )

        static let irritatedRashEntry = LogEntry(
            id: UUID(uuidString: "ABCDEF12-ABCD-EFGH-IJKL-ABCDEF123457")!,
            timestamp: Date(timeIntervalSince1970: 1641081600), // Jan 2, 2022
            imageFilename: "RASH_IRRITATED_001.jpg",
            note: "Rash appears more irritated, slight redness",
            painScore: 2,
            hasBleeding: false,
            hasItching: true,
            isSwollen: false,
            estimatedSize: 8.5,
            spot: Spots.rashOnChest
        )

        static let bleedingWoundEntry = LogEntry(
            id: UUID(uuidString: "ABCDEF12-ABCD-EFGH-IJKL-ABCDEF123458")!,
            timestamp: Date(timeIntervalSince1970: 1641168000), // Jan 3, 2022
            imageFilename: "WOUND_BLEEDING_001.jpg",
            note: "Minor bleeding observed, applied pressure and bandage",
            painScore: 4,
            hasBleeding: true,
            hasItching: false,
            isSwollen: true,
            estimatedSize: 12.0,
            spot: Spots.scarOnKnee
        )

        static let swollenSpotEntry = LogEntry(
            id: UUID(uuidString: "ABCDEF12-ABCD-EFGH-IJKL-ABCDEF123459")!,
            timestamp: Date(timeIntervalSince1970: 1641254400), // Jan 4, 2022
            imageFilename: "SPOT_SWOLLEN_001.jpg",
            note: "Area around birthmark is swollen, monitoring closely",
            painScore: 3,
            hasBleeding: false,
            hasItching: false,
            isSwollen: true,
            estimatedSize: 15.5,
            spot: Spots.birthmarkOnBack
        )

        static let highPainEntry = LogEntry(
            id: UUID(uuidString: "ABCDEF12-ABCD-EFGH-IJKL-ABCDEF123460")!,
            timestamp: Date(timeIntervalSince1970: 1641340800), // Jan 5, 2022
            imageFilename: "HIGH_PAIN_001.jpg",
            note: "Significant pain, doctor visit recommended",
            painScore: 8,
            hasBleeding: true,
            hasItching: true,
            isSwollen: true,
            estimatedSize: 20.0,
            spot: Spots.acneOnFace
        )

        static let emptyNoteEntry = LogEntry(
            id: UUID(uuidString: "ABCDEF12-ABCD-EFGH-IJKL-ABCDEF123461")!,
            timestamp: Date(timeIntervalSince1970: 1641427200), // Jan 6, 2022
            imageFilename: "EMPTY_NOTE_001.jpg",
            note: "",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: Spots.moleOnArm
        )

        static let noSymptomsEntry = LogEntry(
            id: UUID(uuidString: "ABCDEF12-ABCD-EFGH-IJKL-ABCDEF123462")!,
            timestamp: Date(timeIntervalSince1970: 1641513600), // Jan 7, 2022
            imageFilename: "NO_SYMPTOMS_001.jpg",
            note: "All symptoms resolved, area looks healthy",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: 2.5,
            spot: Spots.moleOnArm
        )

        static let allLogEntries = [
            normalMoleEntry, irritatedRashEntry, bleedingWoundEntry,
            swollenSpotEntry, highPainEntry, emptyNoteEntry, noSymptomsEntry
        ]

        static let painfulEntries = [irritatedRashEntry, bleedingWoundEntry, swollenSpotEntry, highPainEntry]
        static let bleedingEntries = [bleedingWoundEntry, highPainEntry]
        static let itchingEntries = [irritatedRashEntry, highPainEntry]
        static let swollenEntries = [bleedingWoundEntry, swollenSpotEntry, highPainEntry]
        static let highPainEntries = [highPainEntry] // pain >= 7
    }

    // MARK: - Complete Hierarchies

    struct Hierarchies {
        /// Complete hierarchy: John -> Mole -> Multiple log entries
        static let johnMoleHierarchy: (user: UserProfile, spot: Spot, entries: [LogEntry]) = (
            user: UserProfiles.johnDoe,
            spot: Spots.moleOnArm,
            entries: [LogEntries.normalMoleEntry, LogEntries.emptyNoteEntry, LogEntries.noSymptomsEntry]
        )

        /// Complete hierarchy: Jane -> Scar -> Medical log entry
        static let janeScarHierarchy: (user: UserProfile, spot: Spot, entry: LogEntry) = (
            user: UserProfiles.janeDoe,
            spot: Spots.scarOnKnee,
            entry: LogEntries.bleedingWoundEntry
        )

        /// Complete hierarchy: Bobby -> Birthmark -> Multiple symptom entries
        static let bobbyBirthmarkHierarchy: (user: UserProfile, spot: Spot, entries: [LogEntry]) = (
            user: UserProfiles.bobbyDoe,
            spot: Spots.birthmarkOnBack,
            entries: [LogEntries.swollenSpotEntry]
        )

        /// Complete hierarchy: Bobby -> Acne -> High pain entry
        static let bobbyAcneHierarchy: (user: UserProfile, spot: Spot, entry: LogEntry) = (
            user: UserProfiles.bobbyDoe,
            spot: Spots.acneOnFace,
            entry: LogEntries.highPainEntry
        )
    }

    // MARK: - Edge Cases and Test Scenarios

    struct EdgeCases {
        static let userProfileWithEmptyName = UserProfiles.emptyName
        static let userProfileWithEmptyRelation = UserProfiles.emptyRelation
        static let spotWithEmptyTitle = Spots.emptyTitle
        static let spotWithEmptyBodyPart = Spots.emptyBodyPart
        static let logEntryWithEmptyNote = LogEntries.emptyNoteEntry

        static let negativePainEntry = LogEntry(
            id: UUID(uuidString: "EDGE001-ABCD-EFGH-IJKL-EDGE0010001")!,
            timestamp: Date(),
            imageFilename: "NEGATIVE_PAIN.jpg",
            note: "Test entry with negative pain score",
            painScore: -1,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: Spots.moleOnArm
        )

        static let extremePainEntry = LogEntry(
            id: UUID(uuidString: "EDGE001-ABCD-EFGH-IJKL-EDGE0010002")!,
            timestamp: Date(),
            imageFilename: "EXTREME_PAIN.jpg",
            note: "Test entry with extreme pain score",
            painScore: 15,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: Spots.moleOnArm
        )

        static let zeroSizeEntry = LogEntry(
            id: UUID(uuidString: "EDGE001-ABCD-EFGH-IJKL-EDGE0010003")!,
            timestamp: Date(),
            imageFilename: "ZERO_SIZE.jpg",
            note: "Test entry with zero estimated size",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: 0.0,
            spot: Spots.moleOnArm
        )

        static let veryLargeSizeEntry = LogEntry(
            id: UUID(uuidString: "EDGE001-ABCD-EFGH-IJKL-EDGE0010004")!,
            timestamp: Date(),
            imageFilename: "LARGE_SIZE.jpg",
            note: "Test entry with very large estimated size",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: 999.9,
            spot: Spots.moleOnArm
        )

        static let longNoteEntry = LogEntry(
            id: UUID(uuidString: "EDGE001-ABCD-EFGH-IJKL-EDGE0010005")!,
            timestamp: Date(),
            imageFilename: "LONG_NOTE.jpg",
            note: String(repeating: "This is a very long note that exceeds normal limits. ", count: 20),
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: Spots.moleOnArm
        )

        static let allEdgeCases = [
            negativePainEntry, extremePainEntry, zeroSizeEntry,
            veryLargeSizeEntry, longNoteEntry
        ]
    }

    // MARK: - Date-Based Scenarios

    struct DateScenarios {
        static let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        static let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        static let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        static let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
        static let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        static let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        static let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        static let oldLogEntry = LogEntry(
            id: UUID(uuidString: "DATE001-ABCD-EFGH-IJKL-DATE0010001")!,
            timestamp: oneYearAgo,
            imageFilename: "OLD_ENTRY.jpg",
            note: "Very old log entry",
            painScore: 1,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: Spots.moleOnArm
        )

        static let recentLogEntry = LogEntry(
            id: UUID(uuidString: "DATE001-ABCD-EFGH-IJKL-DATE0010002")!,
            timestamp: oneDayAgo,
            imageFilename: "RECENT_ENTRY.jpg",
            note: "Very recent log entry",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: Spots.moleOnArm
        )

        static let futureLogEntry = LogEntry(
            id: UUID(uuidString: "DATE001-ABCD-EFGH-IJKL-DATE0010003")!,
            timestamp: futureDate,
            imageFilename: "FUTURE_ENTRY.jpg",
            note: "Future dated log entry",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: Spots.moleOnArm
        )
    }

    // MARK: - Medical Data Scenarios

    struct MedicalScenarios {
        static let noSymptoms = LogEntries.noSymptomsEntry
        static let minorSymptoms = LogEntries.irritatedRashEntry
        static let moderateSymptoms = LogEntries.swollenSpotEntry
        static let severeSymptoms = LogEntries.highPainEntry

        static let allSymptomLevels = [noSymptoms, minorSymptoms, moderateSymptoms, severeSymptoms]

        static let painOnly = LogEntry(
            id: UUID(uuidString: "MED001-ABCD-EFGH-IJKL-MED0010001")!,
            timestamp: Date(),
            imageFilename: "PAIN_ONLY.jpg",
            note: "Pain without other symptoms",
            painScore: 6,
            hasBleeding: false,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: Spots.moleOnArm
        )

        static let bleedingOnly = LogEntry(
            id: UUID(uuidString: "MED001-ABCD-EFGH-IJKL-MED0010002")!,
            timestamp: Date(),
            imageFilename: "BLEEDING_ONLY.jpg",
            note: "Bleeding without pain",
            painScore: 0,
            hasBleeding: true,
            hasItching: false,
            isSwollen: false,
            estimatedSize: nil,
            spot: Spots.moleOnArm
        )

        static let itchingOnly = LogEntry(
            id: UUID(uuidString: "MED001-ABCD-EFGH-IJKL-MED0010003")!,
            timestamp: Date(),
            imageFilename: "ITCHING_ONLY.jpg",
            note: "Itching without pain",
            painScore: 0,
            hasBleeding: false,
            hasItching: true,
            isSwollen: false,
            estimatedSize: nil,
            spot: Spots.moleOnArm
        )

        static let swellingOnly = LogEntry(
            id: UUID(uuidString: "MED001-ABCD-EFGH-IJKL-MED0010004")!,
            timestamp: Date(),
            imageFilename: "SWELLING_ONLY.jpg",
            note: "Swelling without pain",
            painScore: 0,
            hasBleeding: false,
            hasItching: false,
            isSwollen: true,
            estimatedSize: nil,
            spot: Spots.moleOnArm
        )

        static let singleSymptoms = [painOnly, bleedingOnly, itchingOnly, swellingOnly]
    }
}