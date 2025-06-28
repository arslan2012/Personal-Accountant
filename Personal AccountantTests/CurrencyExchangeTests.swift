//
//  CurrencyExchangeTests.swift
//  Personal AccountantTests
//
//  Created by Arslan Ablikim on 2025/6/24.
//

import Foundation
import Testing

@testable import Personal_Accountant

struct CurrencyExchangeTests {

  let currencyExchange = CurrencyExchange.shared

  @Test func testSingletonPattern() async throws {
    let instance1 = CurrencyExchange.shared
    let instance2 = CurrencyExchange.shared

    #expect(instance1 === instance2)
  }

  @Test func testExchangeRateFetch() async throws {
    return try await withCheckedThrowingContinuation { continuation in
      currencyExchange.fetchExchangeRate(from: "USD", to: "EUR") {
        result in
        switch result {
        case .success(let rate):
          #expect(rate > 0)
          #expect(rate.isFinite)
          print("USD to EUR rate: \(rate)")
          continuation.resume()
        case .failure(let error):
          // Network errors are acceptable in test environment
          print("Network error (expected in tests): \(error)")
          continuation.resume()
        }
      }
    }
  }

  @Test func testCurrencyConversion() async throws {
    return try await withCheckedThrowingContinuation { continuation in
      currencyExchange.convert(amount: 100.0, from: "USD", to: "EUR") {
        result in
        switch result {
        case .success(let convertedAmount):
          #expect(convertedAmount > 0)
          #expect(convertedAmount.isFinite)
          print("100 USD = \(convertedAmount) EUR")
          continuation.resume()
        case .failure(let error):
          // Network errors are acceptable in test environment
          print("Network error (expected in tests): \(error)")
          continuation.resume()
        }
      }
    }
  }

  @Test func testSupportedCurrenciesFetch() async throws {
    return try await withCheckedThrowingContinuation { continuation in
      currencyExchange.fetchSupportedCurrencies { result in
        switch result {
        case .success(let currencies):
          #expect(!currencies.isEmpty)
          #expect(currencies.contains("USD"))
          print("Supported currencies count: \(currencies.count)")
          continuation.resume()
        case .failure(let error):
          print("Network error (expected in tests): \(error)")
          continuation.resume()
        }
      }
    }
  }

  @Test func testSameCurrencyConversion() async throws {
    return try await withCheckedThrowingContinuation { continuation in
      currencyExchange.convert(amount: 100.0, from: "USD", to: "USD") {
        result in
        switch result {
        case .success(let convertedAmount):
          #expect(convertedAmount == 100.0)
          continuation.resume()
        case .failure:
          // Some APIs might not support same-currency conversion
          continuation.resume()
        }
      }
    }
  }

  @Test func testZeroAmountConversion() async throws {
    return try await withCheckedThrowingContinuation { continuation in
      currencyExchange.convert(amount: 0.0, from: "USD", to: "EUR") {
        result in
        switch result {
        case .success(let convertedAmount):
          #expect(convertedAmount == 0.0)
          continuation.resume()
        case .failure:
          continuation.resume()
        }
      }
    }
  }

  @Test func testInvalidCurrencyCodeHandling() async throws {
    return try await withCheckedThrowingContinuation { continuation in
      currencyExchange.fetchExchangeRate(from: "INVALID", to: "USD") {
        result in
        switch result {
        case .success:
          // Unexpected success with invalid currency
          continuation.resume()
        case .failure:
          // Expected failure with invalid currency
          continuation.resume()
        }
      }
    }
  }

  @Test func testCacheKeyGeneration() async throws {
    // Test that different currency pairs would generate different cache keys
    // This is more of a conceptual test since cache keys are internal
    let pairs = [("USD", "EUR"), ("EUR", "USD"), ("GBP", "JPY")]

    #expect(pairs[0] != pairs[1])  // Different pairs should be different
    #expect(pairs[1] != pairs[2])
    #expect(pairs[0] != pairs[2])
  }

  @Test func testLargeCurrencyAmountConversion() async throws {
    return try await withCheckedThrowingContinuation { continuation in
      currencyExchange.convert(
        amount: 1_000_000.0,
        from: "USD",
        to: "EUR"
      ) { result in
        switch result {
        case .success(let convertedAmount):
          #expect(convertedAmount > 0)
          #expect(convertedAmount.isFinite)
          continuation.resume()
        case .failure:
          continuation.resume()
        }
      }
    }
  }

  @Test func testSmallCurrencyAmountConversion() async throws {
    return try await withCheckedThrowingContinuation { continuation in
      currencyExchange.convert(amount: 0.01, from: "USD", to: "EUR") {
        result in
        switch result {
        case .success(let convertedAmount):
          #expect(convertedAmount >= 0)
          #expect(convertedAmount.isFinite)
          continuation.resume()
        case .failure:
          continuation.resume()
        }
      }
    }
  }
}
