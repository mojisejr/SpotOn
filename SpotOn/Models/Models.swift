//
//  Models.swift
//  SpotOn
//
//  Created by Non on 11/28/25.
//

import Foundation
import SwiftData

// MARK: - User Profile Model

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var relation: String
    var avatarColor: String
    var createdAt: Date

    // Reverse relationship for cascade delete
    @Relationship(deleteRule: .cascade, inverse: \Spot.userProfile)
    var spots: [Spot] = []

    init(
        id: UUID,
        name: String,
        relation: String,
        avatarColor: String,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.relation = relation
        self.avatarColor = avatarColor
        self.createdAt = createdAt
    }
}

// MARK: - Spot Model

@Model
final class Spot: Identifiable {
    var id: UUID
    var title: String
    var bodyPart: String
    var isActive: Bool
    var createdAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade)
    var userProfile: UserProfile?

    @Relationship(deleteRule: .cascade, inverse: \LogEntry.spot)
    var logEntries: [LogEntry] = []

    init(
        id: UUID,
        title: String,
        bodyPart: String,
        isActive: Bool,
        createdAt: Date,
        userProfile: UserProfile?
    ) {
        self.id = id
        self.title = title
        self.bodyPart = bodyPart
        self.isActive = isActive
        self.createdAt = createdAt
        self.userProfile = userProfile
    }
}

// MARK: - Log Entry Model

@Model
final class LogEntry {
    var id: UUID
    var timestamp: Date
    var imageFilename: String
    var note: String
    var painScore: Int
    var hasBleeding: Bool
    var hasItching: Bool
    var isSwollen: Bool
    var estimatedSize: Double?

    // Relationship
    @Relationship(deleteRule: .nullify)
    var spot: Spot?

    init(
        id: UUID,
        timestamp: Date,
        imageFilename: String,
        note: String,
        painScore: Int,
        hasBleeding: Bool,
        hasItching: Bool,
        isSwollen: Bool,
        estimatedSize: Double?,
        spot: Spot?
    ) {
        self.id = id
        self.timestamp = timestamp
        self.imageFilename = imageFilename
        self.note = note
        self.painScore = painScore
        self.hasBleeding = hasBleeding
        self.hasItching = hasItching
        self.isSwollen = isSwollen
        self.estimatedSize = estimatedSize
        self.spot = spot
    }
}