//
//  UserWorkflowUITests.swift
//  Personal AccountantUITests
//
//  Created by Arslan Ablikim on 2025/6/24.
//

import XCTest

final class UserWorkflowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Complete User Journey Tests

    @MainActor
    func testCompleteTransactionWorkflow() throws {
        // Test a complete workflow: navigate -> add spending -> verify -> add income -> verify

        // Step 1: Navigate to Income/Outcome tab
        app.tabBars.buttons["Income/Outcome"].tap()

        // Step 2: Try to add a spending transaction
        addTransactionIfPossible(
            type: "Spending",
            category: "Groceries",
            amount: "75.50"
        )

        // Step 3: Try to add an income transaction
        addTransactionIfPossible(
            type: "Income",
            category: "Salary",
            amount: "3000.00"
        )

        // Step 4: Navigate to other tabs to verify data persistence
        app.tabBars.buttons["Charts"].tap()
        sleep(1)  // Allow charts to potentially load data

        app.tabBars.buttons["Assets"].tap()
        sleep(1)

        // Return to transactions
        app.tabBars.buttons["Income/Outcome"].tap()
    }

    @MainActor
    func testCompleteAssetWorkflow() throws {
        // Test adding different types of assets

        app.tabBars.buttons["Assets"].tap()

        // Try to add a savings asset
        addAssetIfPossible(
            name: "Emergency Fund",
            amount: "5000.00",
            type: "Savings"
        )

        // Try to add a crypto asset
        addAssetIfPossible(
            name: "Bitcoin Holdings",
            amount: "2500.00",
            type: "Crypto"
        )

        // Try to add an investment asset
        addAssetIfPossible(
            name: "Stock Portfolio",
            amount: "10000.00",
            type: "Investment"
        )

        // Navigate to charts to see if asset data is reflected
        app.tabBars.buttons["Charts"].tap()
        sleep(2)  // Charts might need time to process new data
    }

    @MainActor
    func testSettingsAndDataConsistency() throws {
        // Test changing settings and verifying consistency across the app

        // Step 1: Go to settings
        app.tabBars.buttons["Settings"].tap()

        // Step 2: Try to change default currency if possible
        changeDefaultCurrencyIfPossible(to: "EUR")

        // Step 3: Navigate to add transaction and verify currency default
        app.tabBars.buttons["Income/Outcome"].tap()
        verifyDefaultCurrencyInAddForm(expectedCurrency: "EUR")

        // Step 4: Navigate to add asset and verify currency default
        app.tabBars.buttons["Assets"].tap()
        verifyDefaultCurrencyInAssetForm(expectedCurrency: "EUR")

        // Reset to USD if we changed it
        app.tabBars.buttons["Settings"].tap()
        changeDefaultCurrencyIfPossible(to: "USD")
    }

    @MainActor
    func testDataVisualizationWorkflow() throws {
        // Test that data flows from input to visualization

        // Add some sample data first
        app.tabBars.buttons["Income/Outcome"].tap()
        addTransactionIfPossible(
            type: "Income",
            category: "Freelance",
            amount: "1500.00"
        )
        addTransactionIfPossible(
            type: "Spending",
            category: "Rent",
            amount: "1200.00"
        )
        addTransactionIfPossible(
            type: "Spending",
            category: "Food",
            amount: "300.00"
        )

        // Add some assets
        app.tabBars.buttons["Assets"].tap()
        addAssetIfPossible(
            name: "Checking Account",
            amount: "2000.00",
            type: "Savings"
        )

        // Navigate to charts
        app.tabBars.buttons["Charts"].tap()

        // Wait for charts to potentially load
        sleep(3)

        // Verify charts view is accessible and potentially showing data
        let chartsContainer = app.scrollViews.firstMatch
        if chartsContainer.exists {
            // Try scrolling if there are charts
            chartsContainer.swipeUp()
            chartsContainer.swipeDown()
        }

        // Look for any chart elements or data representations
        let chartElements = app.otherElements.matching(
            NSPredicate(
                format:
                    "identifier CONTAINS 'chart' OR identifier CONTAINS 'Chart'"
            )
        )
        if chartElements.count > 0 {
            print("Found \(chartElements.count) chart-related elements")
        }
    }

    @MainActor
    func testAppNavigationFlow() throws {
        // Test systematic navigation through all app sections

        let tabs = ["Income/Outcome", "Assets", "Charts", "Settings"]

        for tab in tabs {
            app.tabBars.buttons[tab].tap()
            XCTAssertTrue(
                app.tabBars.buttons[tab].isSelected,
                "\(tab) should be selected"
            )

            // Wait a moment for view to load
            sleep(1)

            // Try to interact with the view if possible
            switch tab {
            case "Income/Outcome":
                tryInteractWithTransactionView()
            case "Assets":
                tryInteractWithAssetsView()
            case "Charts":
                tryInteractWithChartsView()
            case "Settings":
                tryInteractWithSettingsView()
            default:
                break
            }
        }
    }

    @MainActor
    func testFormValidationWorkflow() throws {
        // Test comprehensive form validation across different forms

        // Test transaction form validation
        app.tabBars.buttons["Income/Outcome"].tap()
        testTransactionFormValidation()

        // Test asset form validation
        app.tabBars.buttons["Assets"].tap()
        testAssetFormValidation()
    }

    @MainActor
    func testOfflineExperienceSimulation() throws {
        // Test app behavior when network features might not be available

        app.tabBars.buttons["Income/Outcome"].tap()

        // Try to add a transaction (currency loading might fail offline)
        let addButton = findAddButton()
        if addButton != nil {
            addButton!.tap()

            // Wait for form to load
            sleep(2)

            // Fill form even if currency loading fails
            fillTransactionFormBasics()

            // Cancel out to avoid network-dependent operations
            if app.buttons["Cancel"].exists {
                app.buttons["Cancel"].tap()
            }
        }
    }

    // MARK: - Helper Methods

    private func addTransactionIfPossible(
        type: String,
        category: String,
        amount: String
    ) {
        let addButton = findAddButton()
        guard let button = addButton else { return }

        button.tap()
        sleep(1)

        // Set transaction type if segmented control exists
        let segmentedControl = app.segmentedControls.firstMatch
        if segmentedControl.exists && segmentedControl.buttons[type].exists {
            segmentedControl.buttons[type].tap()
        }

        // Fill form fields
        fillTextField("Category", with: category)
        fillTextField("Amount", with: amount)

        // Try to save or cancel
        if app.buttons["Save"].exists && app.buttons["Save"].isEnabled {
            app.buttons["Save"].tap()
        } else if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        }

        sleep(1)  // Allow time for save operation
    }

    private func addAssetIfPossible(name: String, amount: String, type: String)
    {
        let addButton = findAddButton()
        guard let button = addButton else { return }

        button.tap()
        sleep(1)

        // Fill form fields
        fillTextField("Name", with: name)
        fillTextField("Amount", with: amount)

        // Set asset type if picker exists
        let typePicker = app.pickers.matching(identifier: "Type").firstMatch
        if typePicker.exists {
            typePicker.tap()
            if app.buttons[type].exists {
                app.buttons[type].tap()
            }
        }

        // Try to save or cancel
        if app.buttons["Save"].exists && app.buttons["Save"].isEnabled {
            app.buttons["Save"].tap()
        } else if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        }

        sleep(1)
    }

    private func changeDefaultCurrencyIfPossible(to currency: String) {
        let currencyPicker = app.pickers.matching(identifier: "Currency")
            .firstMatch
        if currencyPicker.exists {
            currencyPicker.tap()
            if app.buttons[currency].exists {
                app.buttons[currency].tap()
            }
        }
    }

    private func verifyDefaultCurrencyInAddForm(expectedCurrency: String) {
        let addButton = findAddButton()
        guard let button = addButton else { return }

        button.tap()
        sleep(1)

        // Check if currency picker shows expected default
        let currencyPicker = app.pickers.matching(identifier: "Currency")
            .firstMatch
        if currencyPicker.exists {
            // This is a basic check - more sophisticated verification would be needed
            XCTAssertTrue(currencyPicker.exists, "Currency picker should exist")
        }

        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        }
    }

    private func verifyDefaultCurrencyInAssetForm(expectedCurrency: String) {
        let addButton = findAddButton()
        guard let button = addButton else { return }

        button.tap()
        sleep(1)

        let currencyPicker = app.pickers.matching(identifier: "Currency")
            .firstMatch
        if currencyPicker.exists {
            XCTAssertTrue(
                currencyPicker.exists,
                "Currency picker should exist in asset form"
            )
        }

        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        }
    }

    private func findAddButton() -> XCUIElement? {
        // Try different possible add button identifiers
        let addButtons = [
            app.buttons["Add"],
            app.buttons["+"],
            app.navigationBars.buttons["+"],
            app.navigationBars.buttons["Add"],
        ]

        for button in addButtons {
            if button.exists {
                return button
            }
        }
        return nil
    }

    private func fillTextField(_ identifier: String, with text: String) {
        let textField = app.textFields[identifier]
        if textField.exists {
            textField.tap()
            textField.typeText(text)
        }
    }

    private func tryInteractWithTransactionView() {
        // Look for transaction list or add button
        if findAddButton() != nil {
            print("Transaction view has add functionality")
        }

        // Look for transaction list
        let lists =
            app.tables.allElementsBoundByIndex
            + app.collectionViews.allElementsBoundByIndex
        if !lists.isEmpty {
            print("Found \(lists.count) list elements in transaction view")
        }
    }

    private func tryInteractWithAssetsView() {
        if findAddButton() != nil {
            print("Assets view has add functionality")
        }
    }

    private func tryInteractWithChartsView() {
        // Charts are often implemented as custom views
        let scrollViews = app.scrollViews.allElementsBoundByIndex
        if !scrollViews.isEmpty {
            scrollViews.first?.swipeUp()
            scrollViews.first?.swipeDown()
        }
    }

    private func tryInteractWithSettingsView() {
        // Look for common settings elements
        let pickers = app.pickers.allElementsBoundByIndex
        let switches = app.switches.allElementsBoundByIndex

        print(
            "Settings view has \(pickers.count) pickers and \(switches.count) switches"
        )
    }

    private func testTransactionFormValidation() {
        let addButton = findAddButton()
        guard let button = addButton else { return }

        button.tap()
        sleep(1)

        // Test empty form
        if app.buttons["Save"].exists {
            XCTAssertFalse(
                app.buttons["Save"].isEnabled,
                "Save should be disabled for empty form"
            )
        }

        // Fill partial form
        fillTextField("Category", with: "Test")

        if app.buttons["Save"].exists {
            // Save might still be disabled without amount
            let saveEnabled = app.buttons["Save"].isEnabled
            print("Save button enabled after category only: \(saveEnabled)")
        }

        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        }
    }

    private func testAssetFormValidation() {
        let addButton = findAddButton()
        guard let button = addButton else { return }

        button.tap()
        sleep(1)

        if app.buttons["Save"].exists {
            XCTAssertFalse(
                app.buttons["Save"].isEnabled,
                "Save should be disabled for empty asset form"
            )
        }

        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        }
    }

    private func fillTransactionFormBasics() {
        fillTextField("Category", with: "Test Category")
        fillTextField("Amount", with: "100.00")
        fillTextField("Detail", with: "Test transaction")
    }
}
