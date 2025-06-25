//
//  ContentView.swift
//  Personal Accountant
//
//  Created by Arslan Ablikim on 2025/6/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            IncomeOutcomeView()
                .tabItem {
                    Label("Income/Outcome", systemImage: "list.bullet.rectangle")
                }
                .tag(0)
            AssetsView()
                .tabItem {
                    Label("Assets", systemImage: "banknote")
                }
                .tag(1)
            ChartsView()
                .tabItem {
                    Label("Charts", systemImage: "chart.pie.fill")
                }
                .tag(2)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, Asset.self])
}
