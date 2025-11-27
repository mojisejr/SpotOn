//
//  Item.swift
//  SpotOn
//
//  Created by nonthasak laoluerat on 27/11/2568 BE.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
