//
//  Personal_AccountantTests.swift
//  Personal AccountantTests
//
//  Created by Arslan Ablikim on 2025/6/24.
//

import Foundation
import Testing

@testable import Personal_Accountant

// MARK: - Model Tests
struct TransactionTests {

  @Test func testTransactionInitialization() async throws {
    let transaction = Transaction(
      category: "Food",
      amount: 25.50,
      currency: "USD",
      detail: "Lunch at restaurant",
      date: Date(),
      type: .spending
    )

    #expect(transaction.category == "Food")
    #expect(transaction.amount == 25.50)
    #expect(transaction.currency == "USD")
    #expect(transaction.detail == "Lunch at restaurant")
    #expect(transaction.type == .spending)
  }

  @Test func testTransactionTypeEnum() async throws {
    #expect(TransactionType.allCases.count == 2)
    #expect(TransactionType.allCases.contains(.spending))
    #expect(TransactionType.allCases.contains(.income))
    #expect(TransactionType.spending.rawValue == "spending")
    #expect(TransactionType.income.rawValue == "income")
  }

  @Test func testTransactionWithIncomeType() async throws {
    let incomeTransaction = Transaction(
      category: "Salary",
      amount: 5000.00,
      currency: "USD",
      detail: "Monthly salary",
      date: Date(),
      type: .income
    )

    #expect(incomeTransaction.type == .income)
    #expect(incomeTransaction.amount > 0)
  }
}

struct AssetTests {

  @Test func testAssetInitialization() async throws {
    let asset = Asset(
      name: "Emergency Fund",
      amount: 10000.0,
      currency: "USD",
      type: .savings,
      detail: "6 months emergency fund"
    )

    #expect(asset.name == "Emergency Fund")
    #expect(asset.amount == 10000.0)
    #expect(asset.currency == "USD")
    #expect(asset.type == .savings)
    #expect(asset.detail == "6 months emergency fund")
  }

  @Test func testAssetWithoutDetail() async throws {
    let asset = Asset(
      name: "Bitcoin",
      amount: 0.5,
      currency: "BTC",
      type: .crypto
    )

    #expect(asset.name == "Bitcoin")
    #expect(asset.amount == 0.5)
    #expect(asset.type == .crypto)
    #expect(asset.detail == nil)
  }

  @Test func testAssetTypeEnum() async throws {
    #expect(AssetType.allCases.count == 4)
    #expect(AssetType.allCases.contains(.savings))
    #expect(AssetType.allCases.contains(.crypto))
    #expect(AssetType.allCases.contains(.investment))
    #expect(AssetType.allCases.contains(.other))

    #expect(AssetType.savings.rawValue == "savings")
    #expect(AssetType.crypto.rawValue == "crypto")
    #expect(AssetType.investment.rawValue == "investment")
    #expect(AssetType.other.rawValue == "other")
  }
}

// MARK: - Validation Tests
struct ValidationTests {

  @Test func testValidTransactionAmounts() async throws {
    // Test positive amounts
    #expect(validateAmount("100.50") == 100.50)
    #expect(validateAmount("0.01") == 0.01)
    #expect(validateAmount("1000") == 1000.0)

    // Test invalid amounts
    #expect(validateAmount("") == nil)
    #expect(validateAmount("abc") == nil)
    #expect(validateAmount("-50") == nil)  // Negative amounts might be invalid for certain use cases
  }

  @Test func testValidCategoryNames() async throws {
    #expect(validateCategory("Food") == true)
    #expect(validateCategory("Transportation") == true)
    #expect(validateCategory("") == false)
    #expect(validateCategory("   ") == false)
  }

  @Test func testValidAssetNames() async throws {
    #expect(validateAssetName("Savings Account") == true)
    #expect(validateAssetName("401k") == true)
    #expect(validateAssetName("") == false)
    #expect(validateAssetName("   ") == false)
  }
}

// MARK: - Date Utilities Tests
struct DateUtilityTests {

  @Test func testDateFormatting() async throws {
    let date = Date(timeIntervalSince1970: 1_672_531_200)  // Jan 1, 2023
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeZone = TimeZone(identifier: "UTC")

    let formattedDate = formatter.string(from: date)
    #expect(!formattedDate.isEmpty)
  }

  @Test func testDateComparisons() async throws {
    let now = Date()
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
    let yesterday = Calendar.current.date(
      byAdding: .day,
      value: -1,
      to: now
    )!

    #expect(now < tomorrow)
    #expect(now > yesterday)
    #expect(yesterday < tomorrow)
  }
}

// MARK: - Helper Functions
private func validateAmount(_ input: String) -> Double? {
  guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
    return nil
  }
  let amount = Double(input)
  return (amount != nil && amount! >= 0) ? amount : nil
}

private func validateCategory(_ input: String) -> Bool {
  return !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}

private func validateAssetName(_ input: String) -> Bool {
  return !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}
