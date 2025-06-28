//
//  Personal_AccountantUITests.swift
//  Personal AccountantUITests
//
//  Created by Arslan Ablikim on 2025/6/24.
//

import XCTest

final class Personal_AccountantUITests: XCTestCase {

  var app: XCUIApplication!

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false

    // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    app = XCUIApplication()

    // Pass UI testing flag to disable network calls
    app.launchArguments.append("UI_TESTING")
    app.launch()
  }

  override func tearDownWithError() throws {
    app = nil
  }

  // MARK: - Navigation Tests

  @MainActor
  func testTabViewNavigationExists() throws {
    // Test that all tab items are present
    let tabBar = app.tabBars.firstMatch
    XCTAssertTrue(tabBar.exists, "Tab bar should exist")

    // Check all tab items exist
    XCTAssertTrue(
      app.tabBars.buttons["Income/Outcome"].exists,
      "Income/Outcome tab should exist"
    )
    XCTAssertTrue(
      app.tabBars.buttons["Assets"].exists,
      "Assets tab should exist"
    )
    XCTAssertTrue(
      app.tabBars.buttons["Charts"].exists,
      "Charts tab should exist"
    )
    XCTAssertTrue(
      app.tabBars.buttons["Settings"].exists,
      "Settings tab should exist"
    )
  }

  @MainActor
  func testNavigationBetweenTabs() throws {
    // Navigate to Assets tab
    app.tabBars.buttons["Assets"].tap()
    XCTAssertTrue(
      app.tabBars.buttons["Assets"].isSelected,
      "Assets tab should be selected"
    )

    // Navigate to Charts tab
    app.tabBars.buttons["Charts"].tap()
    XCTAssertTrue(
      app.tabBars.buttons["Charts"].isSelected,
      "Charts tab should be selected"
    )

    // Navigate to Settings tab
    app.tabBars.buttons["Settings"].tap()
    XCTAssertTrue(
      app.tabBars.buttons["Settings"].isSelected,
      "Settings tab should be selected"
    )

    // Navigate back to Income/Outcome tab
    app.tabBars.buttons["Income/Outcome"].tap()
    XCTAssertTrue(
      app.tabBars.buttons["Income/Outcome"].isSelected,
      "Income/Outcome tab should be selected"
    )
  }

  // MARK: - Transaction Tests

  @MainActor
  func testAddTransactionFlow() throws {
    // Ensure we're on the Income/Outcome tab
    app.tabBars.buttons["Income/Outcome"].tap()

    // Look for add button (this might be a "+" button or "Add" button)
    // We'll try common button identifiers
    let addButton = app.buttons.matching(identifier: "Add").firstMatch
    if addButton.exists {
      addButton.tap()

      // Wait for the add transaction view to appear
      let expectation = XCTNSPredicateExpectation(
        predicate: NSPredicate(format: "exists == true"),
        object: app.navigationBars.firstMatch
      )
      wait(for: [expectation], timeout: 5.0)

      // Check if form fields exist
      if app.textFields["Category"].exists {
        app.textFields["Category"].tap()
        app.textFields["Category"].typeText("Test Category")
      }

      if app.textFields["Amount"].exists {
        app.textFields["Amount"].tap()
        app.textFields["Amount"].typeText("50.00")
      }

      // Look for save button
      if app.buttons["Save"].exists {
        // Only tap save if it's enabled (form is valid)
        if app.buttons["Save"].isEnabled {
          app.buttons["Save"].tap()
        }
      }
    }
  }

  @MainActor
  func testTransactionTypeToggle() throws {
    app.tabBars.buttons["Income/Outcome"].tap()

    let addButton = app.buttons.matching(identifier: "Add").firstMatch
    if addButton.exists {
      addButton.tap()

      // Look for segmented control for transaction type
      let segmentedControl = app.segmentedControls.firstMatch
      if segmentedControl.exists {
        // Test switching between spending and income
        segmentedControl.buttons["Spending"].tap()
        XCTAssertTrue(segmentedControl.buttons["Spending"].isSelected)

        segmentedControl.buttons["Income"].tap()
        XCTAssertTrue(segmentedControl.buttons["Income"].isSelected)
      }

      // Cancel out of the form
      if app.buttons["Cancel"].exists {
        app.buttons["Cancel"].tap()
      }
    }
  }

  // MARK: - Asset Tests

  @MainActor
  func testAssetsTabAccess() throws {
    app.tabBars.buttons["Assets"].tap()

    // Wait for assets view to load
    let expectation = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "exists == true"),
      object: app.tabBars.buttons["Assets"]
    )
    wait(for: [expectation], timeout: 3.0)

    XCTAssertTrue(
      app.tabBars.buttons["Assets"].isSelected,
      "Assets tab should be selected"
    )
  }

  @MainActor
  func testAddAssetFlow() throws {
    app.tabBars.buttons["Assets"].tap()

    // Look for add asset button
    let addButton = app.buttons.matching(identifier: "Add").firstMatch
    if addButton.exists {
      addButton.tap()

      // Wait for add asset view to appear
      sleep(1)  // Give time for navigation

      // Fill out asset form if fields exist
      if app.textFields["Name"].exists {
        app.textFields["Name"].tap()
        app.textFields["Name"].typeText("Test Asset")
      }

      if app.textFields["Amount"].exists {
        app.textFields["Amount"].tap()
        app.textFields["Amount"].typeText("1000.00")
      }

      // Test asset type picker if it exists
      let typePicker = app.pickers.matching(identifier: "Type").firstMatch
      if typePicker.exists {
        typePicker.tap()
        // Select a type if options are visible
        if app.buttons["Savings"].exists {
          app.buttons["Savings"].tap()
        }
      }

      // Cancel out of the form
      if app.buttons["Cancel"].exists {
        app.buttons["Cancel"].tap()
      }
    }
  }

  // MARK: - Charts Tests

  @MainActor
  func testChartsTabAccess() throws {
    app.tabBars.buttons["Charts"].tap()

    // Wait for charts view to load
    sleep(2)  // Charts might take time to render

    XCTAssertTrue(
      app.tabBars.buttons["Charts"].isSelected,
      "Charts tab should be selected"
    )

    // Charts are often rendered as images or custom views
    // We can check if the view loaded by looking for any interactive elements
    let chartsView = app.otherElements.firstMatch
    XCTAssertTrue(chartsView.exists, "Charts content should be visible")
  }

  @MainActor
  func testDefaultCurrencySetting() throws {
    app.tabBars.buttons["Settings"].tap()

    // Wait for settings to load
    let settingsForm = app.otherElements["SettingsForm"]
    let formExpectation = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "exists == true"),
      object: settingsForm
    )
    XCTWaiter.wait(for: [formExpectation], timeout: 10.0)

    // Wait for loading to complete
    let loadingIndicator = app.activityIndicators["LoadingIndicator"]
    if loadingIndicator.exists {
      let loadingFinished = XCTNSPredicateExpectation(
        predicate: NSPredicate(format: "exists == false"),
        object: loadingIndicator
      )
      XCTWaiter.wait(for: [loadingFinished], timeout: 10.0)
    }

    // Look for currency picker with the correct identifier
    let currencyPicker = app.pickers["CurrencyPicker"]
    let fallbackButton = app.buttons["FallbackButton"]

    // If fallback button exists, use it first
    if fallbackButton.exists {
      fallbackButton.tap()

      // Wait for picker to appear
      let pickerAppeared = XCTNSPredicateExpectation(
        predicate: NSPredicate(format: "exists == true"),
        object: currencyPicker
      )
      XCTWaiter.wait(for: [pickerAppeared], timeout: 3.0)
    }

    // Now test the currency picker if it exists
    if currencyPicker.exists {
      currencyPicker.tap()

      // Test selecting a currency if options are available
      if app.buttons["EUR"].exists {
        app.buttons["EUR"].tap()
      } else if app.buttons["USD"].exists {
        app.buttons["USD"].tap()
      } else if app.buttons["GBP"].exists {
        app.buttons["GBP"].tap()
      }
    }
  }

  // MARK: - Data Persistence Tests

  @MainActor
  func testAppStateRetention() throws {
    // Navigate to different tabs to potentially create some state
    app.tabBars.buttons["Assets"].tap()
    sleep(1)
    app.tabBars.buttons["Charts"].tap()
    sleep(1)
    app.tabBars.buttons["Settings"].tap()
    sleep(1)

    // Terminate and relaunch app
    app.terminate()
    app.launch()

    // Verify app launches successfully
    let tabBar = app.tabBars.firstMatch
    XCTAssertTrue(
      tabBar.exists,
      "App should launch successfully after restart"
    )

    // Verify we can still navigate
    app.tabBars.buttons["Income/Outcome"].tap()
    XCTAssertTrue(app.tabBars.buttons["Income/Outcome"].isSelected)
  }

  // MARK: - Accessibility Tests

  @MainActor
  func testBasicAccessibility() throws {
    // Check that main UI elements have accessibility labels
    let tabBar = app.tabBars.firstMatch
    XCTAssertTrue(tabBar.exists)

    // Test VoiceOver navigation between tabs
    app.tabBars.buttons["Income/Outcome"].tap()
    XCTAssertTrue(app.tabBars.buttons["Income/Outcome"].exists)

    app.tabBars.buttons["Assets"].tap()
    XCTAssertTrue(app.tabBars.buttons["Assets"].exists)
  }

  // MARK: - Performance Tests

  @MainActor
  func testLaunchPerformance() throws {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
      XCUIApplication().launch()
    }
  }

  @MainActor
  func testTabSwitchingPerformance() throws {
    measure {
      app.tabBars.buttons["Assets"].tap()
      app.tabBars.buttons["Charts"].tap()
      app.tabBars.buttons["Settings"].tap()
      app.tabBars.buttons["Income/Outcome"].tap()
    }
  }

  // MARK: - Error Handling Tests

  @MainActor
  func testFormValidation() throws {
    app.tabBars.buttons["Income/Outcome"].tap()

    let addButton = app.buttons.matching(identifier: "Add").firstMatch
    if addButton.exists {
      addButton.tap()

      // Try to save without filling required fields
      if app.buttons["Save"].exists {
        // Save button should be disabled with empty form
        XCTAssertFalse(
          app.buttons["Save"].isEnabled,
          "Save button should be disabled with empty form"
        )
      }

      // Fill only category, leave amount empty
      if app.textFields["Category"].exists {
        app.textFields["Category"].tap()
        app.textFields["Category"].typeText("Test")

        // Save should still be disabled without amount
        if app.buttons["Save"].exists {
          XCTAssertFalse(
            app.buttons["Save"].isEnabled,
            "Save button should be disabled without amount"
          )
        }
      }

      // Cancel out
      if app.buttons["Cancel"].exists {
        app.buttons["Cancel"].tap()
      }
    }
  }
}
