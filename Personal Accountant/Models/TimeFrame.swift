import Foundation

enum TimeFrame: String, CaseIterable {
  case threeMonths = "3M"
  case sixMonths = "6M"
  case oneYear = "1Y"

  var months: Int {
    switch self {
    case .threeMonths: return 3
    case .sixMonths: return 6
    case .oneYear: return 12
    }
  }

  var label: String {
    switch self {
    case .threeMonths: return "3 Months"
    case .sixMonths: return "6 Months"
    case .oneYear: return "1 Year"
    }
  }
}
