//
//  Personal_AccountantApp.swift
//  Personal Accountant
//
//  Created by Arslan Ablikim on 2025/6/24.
//

import SwiftData
import SwiftUI

@main
struct Personal_AccountantApp: App {
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      Transaction.self,
      Asset.self,
    ])
    let modelConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false
    )

    do {
      return try ModelContainer(
        for: schema,
        configurations: [modelConfiguration]
      )
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(sharedModelContainer)
  }
}
