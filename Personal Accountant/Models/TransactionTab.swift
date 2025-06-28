import Foundation

enum TransactionTab: String, CaseIterable, Identifiable {
  case all, spending, income
  var id: String { rawValue }
  var label: String {
    switch self {
    case .all: return "All"
    case .spending: return "Spending"
    case .income: return "Income"
    }
  }
}
