# Personal Accountant Test Suite

This document describes the comprehensive test suite that has been added to the Personal Accountant iOS app.

## Overview

The test suite covers both unit tests and UI tests to ensure the reliability and functionality of the Personal Accountant app. The app is built with SwiftUI and SwiftData, and includes features for tracking financial transactions, managing assets, currency conversion, and data visualization.

## Unit Tests

### 1. Model Tests (`Personal_AccountantTests.swift`)

#### TransactionTests

- **testTransactionInitialization**: Verifies Transaction model initialization with all properties
- **testTransactionTypeEnum**: Tests the TransactionType enum (spending/income) and its properties
- **testTransactionWithIncomeType**: Validates income-specific transaction creation

#### AssetTests

- **testAssetInitialization**: Tests Asset model creation with all properties including optional detail
- **testAssetWithoutDetail**: Verifies asset creation without optional detail field
- **testAssetTypeEnum**: Validates AssetType enum (savings, crypto, investment, other)

#### ValidationTests

- **testValidTransactionAmounts**: Tests amount validation logic for positive numbers, decimals, and invalid inputs
- **testValidCategoryNames**: Validates category name requirements (non-empty, trimmed whitespace)
- **testValidAssetNames**: Tests asset name validation requirements

#### DateUtilityTests

- **testDateFormatting**: Verifies date formatting functionality
- **testDateComparisons**: Tests date comparison logic for chronological ordering

### 2. Currency Exchange Tests (`CurrencyExchangeTests.swift`)

#### Core Functionality

- **testSingletonPattern**: Verifies CurrencyExchange uses singleton pattern correctly
- **testExchangeRateFetch**: Tests fetching exchange rates between currencies (USD to EUR)
- **testCurrencyConversion**: Validates currency amount conversion functionality
- **testSupportedCurrenciesFetch**: Tests fetching list of supported currencies

#### Edge Cases

- **testSameCurrencyConversion**: Tests conversion when source and target currencies are the same
- **testZeroAmountConversion**: Validates behavior with zero amount conversions
- **testInvalidCurrencyCodeHandling**: Tests error handling for invalid currency codes
- **testLargeCurrencyAmountConversion**: Tests conversion with large amounts (1,000,000)
- **testSmallCurrencyAmountConversion**: Tests conversion with small amounts (0.01)

#### Data Validation

- **testCacheKeyGeneration**: Tests that different currency pairs generate different cache keys

## UI Tests

### 1. Core Navigation Tests (`Personal_AccountantUITests.swift`)

#### Navigation Testing

- **testTabViewNavigationExists**: Verifies all tab items are present (Income/Outcome, Assets, Charts, Settings)
- **testNavigationBetweenTabs**: Tests navigation between all app tabs

#### Transaction Management

- **testAddTransactionFlow**: Tests the complete flow for adding new transactions
- **testTransactionTypeToggle**: Validates switching between spending and income transaction types

#### Asset Management

- **testAssetsTabAccess**: Tests navigation to and loading of the Assets tab
- **testAddAssetFlow**: Tests the complete flow for adding new assets

#### Data Visualization

- **testChartsTabAccess**: Validates Charts tab accessibility and content loading

#### Settings

- **testDefaultCurrencySetting**: Validates currency setting functionality

#### Data Persistence

- **testAppStateRetention**: Tests app state persistence across app restarts

#### Accessibility & Performance

- **testBasicAccessibility**: Validates basic accessibility features
- **testLaunchPerformance**: Measures app launch performance
- **testTabSwitchingPerformance**: Measures navigation performance

#### Error Handling

- **testFormValidation**: Tests form validation in transaction/asset creation

### 2. User Workflow Tests (`UserWorkflowUITests.swift`)

#### Complete User Journeys

- **testCompleteTransactionWorkflow**: Tests end-to-end transaction creation workflow
- **testCompleteAssetWorkflow**: Tests end-to-end asset management workflow
- **testSettingsAndDataConsistency**: Tests settings changes and data consistency
- **testDataVisualizationWorkflow**: Tests data flow from input to visualization

#### Navigation Flow

- **testAppNavigationFlow**: Systematic testing of all app sections
- **testFormValidationWorkflow**: Comprehensive form validation testing

#### Edge Cases

- **testOfflineExperienceSimulation**: Tests app behavior when network features are unavailable

## Testing Framework

The tests use two different frameworks:

- **Swift Testing Framework**: For unit tests (uses `@Test` and `#expect`)
- **XCTest Framework**: For UI tests (uses `XCTAssert` and `XCUIApplication`)

## Test Coverage

The test suite covers:

- ✅ **Model Layer**: Transaction and Asset model validation
- ✅ **Business Logic**: Currency conversion, validation functions
- ✅ **User Interface**: Navigation, form interactions, tab switching
- ✅ **Data Persistence**: App state retention
- ✅ **Error Handling**: Invalid inputs, network failures
- ✅ **Performance**: Launch times, navigation speed
- ✅ **Accessibility**: Basic accessibility compliance

## Network-Dependent Tests

Some tests rely on network connectivity for currency exchange features. These tests are designed to be resilient:

- They handle network failures gracefully
- They don't fail the test suite if external APIs are unavailable
- They provide meaningful logging for debugging

## Running the Tests

### Unit Tests Only

```bash
xcodebuild test -scheme "Personal Accountant" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:Personal_AccountantTests
```

### UI Tests Only

```bash
xcodebuild test -scheme "Personal Accountant" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:Personal_AccountantUITests
```

### All Tests

```bash
xcodebuild test -scheme "Personal Accountant" -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Test Structure

The tests are organized into logical groups:

- **Model Tests**: Core data model validation
- **Service Tests**: External service integration (currency exchange)
- **UI Tests**: User interface and interaction testing
- **Integration Tests**: End-to-end workflow validation

This comprehensive test suite ensures the Personal Accountant app maintains high quality and reliability across all its features.
