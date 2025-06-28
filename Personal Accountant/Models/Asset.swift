import Foundation
import SwiftData

enum AssetType: String, Codable, CaseIterable {
  case savings
  case crypto
  case investment
  case other
}

@Model
final class Asset {
  var name: String
  var amount: Double
  var currency: String
  var type: AssetType
  var detail: String?

  init(
    name: String,
    amount: Double,
    currency: String,
    type: AssetType,
    detail: String? = nil
  ) {
    self.name = name
    self.amount = amount
    self.currency = currency
    self.type = type
    self.detail = detail
  }
}
