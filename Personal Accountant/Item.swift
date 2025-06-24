//
//  Item.swift
//  Personal Accountant
//
//  Created by Arslan Ablikim on 2025/6/24.
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
