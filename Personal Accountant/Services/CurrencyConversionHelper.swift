import Combine
import Foundation

class CurrencyConversionHelper: ObservableObject {
  static let shared = CurrencyConversionHelper()

  private init() {}

  /// Converts a list of transactions to a total in the specified currency
  func calculateTransactionTotal(
    transactions: [Transaction],
    toCurrency: String,
    selectedTab: TransactionTab,
    completion: @escaping (Result<Double, Error>) -> Void
  ) {
    let group = DispatchGroup()
    var sum: Double = 0
    var errorOccurred = false
    var firstError: Error? = nil

    for tx in transactions {
      group.enter()
      let sign = (selectedTab == .all && tx.type == .spending) ? -1.0 : 1.0

      CurrencyExchange.shared.convert(
        amount: tx.amount,
        from: tx.currency,
        to: toCurrency
      ) { result in
        switch result {
        case .success(let converted):
          sum += converted * sign
        case .failure(let error):
          errorOccurred = true
          if firstError == nil {
            firstError = error
          }
          print(
            "[CurrencyConversion] Error converting \(tx.amount) \(tx.currency) to \(toCurrency): \(error)"
          )
        }
        group.leave()
      }
    }

    group.notify(queue: .main) {
      if errorOccurred {
        completion(.failure(firstError ?? NSError(domain: "ConversionError", code: 0)))
      } else {
        completion(.success(sum))
      }
    }
  }

  /// Converts a list of assets to a total in the specified currency
  func calculateAssetTotal(
    assets: [Asset],
    toCurrency: String,
    completion: @escaping (Result<Double, Error>) -> Void
  ) {
    let group = DispatchGroup()
    var sum: Double = 0
    var errorOccurred = false
    var firstError: Error? = nil

    for asset in assets {
      group.enter()

      CurrencyExchange.shared.convert(
        amount: asset.amount,
        from: asset.currency,
        to: toCurrency
      ) { result in
        switch result {
        case .success(let converted):
          sum += converted
        case .failure(let error):
          errorOccurred = true
          if firstError == nil {
            firstError = error
          }
          print(
            "[CurrencyConversion] Error converting \(asset.amount) \(asset.currency) to \(toCurrency): \(error)"
          )
        }
        group.leave()
      }
    }

    group.notify(queue: .main) {
      if errorOccurred {
        completion(.failure(firstError ?? NSError(domain: "ConversionError", code: 0)))
      } else {
        completion(.success(sum))
      }
    }
  }
}
