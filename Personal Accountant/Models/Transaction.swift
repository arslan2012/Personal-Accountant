//
//  Item.swift
//  Personal Accountant
//
//  Created by Arslan Ablikim on 2025/6/24.
//

import Foundation
import SwiftData

enum TransactionType: String, Codable, CaseIterable {
  case spending
  case income
}

@Model
final class Transaction {
  var category: String
  var amount: Double
  var currency: String
  var detail: String
  var date: Date
  var type: TransactionType

  init(
    category: String,
    amount: Double,
    currency: String,
    detail: String,
    date: Date,
    type: TransactionType
  ) {
    self.category = category
    self.amount = amount
    self.currency = currency
    self.detail = detail
    self.date = date
    self.type = type
  }
}
