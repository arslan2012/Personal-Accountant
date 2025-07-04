//
//  Item.swift
//  Personal Accountant
//
//  Created by Arslan Ablikim on 2025/6/24.
//

import Foundation
import OpenAI
import SwiftData

enum TransactionType: String, Codable, CaseIterable, JSONSchemaEnumConvertible {
  case spending
  case income

  var caseNames: [String] { Self.allCases.map { $0.rawValue } }
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

// MARK: - OpenAI API Response Model
struct TransactionInfo: JSONSchemaConvertible {
  let category: String
  let amount: Double
  let currency: String
  let detail: String
  let date: String  // ISO8601 string format for API
  let type: TransactionType

  static let example: Self = {
    .init(
      category: "Food & Dining",
      amount: 25.50,
      currency: "USD",
      detail: "Lunch at restaurant",
      date: "2024-01-15T12:30:00Z",
      type: .spending
    )
  }()
}

// MARK: - API Response wrapper for multiple transactions
struct TransactionListInfo: JSONSchemaConvertible {
  let transactions: [TransactionInfo]

  static let example: Self = {
    .init(
      transactions: [
        TransactionInfo.example,
        .init(
          category: "Transportation",
          amount: 15.00,
          currency: "USD",
          detail: "Uber ride",
          date: "2024-01-15T14:00:00Z",
          type: .spending
        ),
      ]
    )
  }()
}
