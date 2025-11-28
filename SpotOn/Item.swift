//
//  Item.swift
//  SpotOn
//
//  Created by Non on 11/28/25.
//

import Foundation
import SwiftData

/// Legacy Item model - kept for compatibility during migration
/// This model is no longer used in the current SpotOn implementation
@Model
final class Item {
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
