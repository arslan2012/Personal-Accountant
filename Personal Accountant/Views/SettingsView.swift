import SwiftUI

struct SettingsView: View {
  @AppStorage("defaultCurrency") private var defaultCurrency: String = "USD"
  @State private var tempCurrency: String = ""
  @State private var supportedCurrencies: [String] = []
  @State private var isLoading = true
  @State private var fetchError: String? = nil
  @State private var showingCurrencyPicker = false

  // Fallback currencies for when network fails
  private let fallbackCurrencies = [
    "USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "INR", "KRW",
  ]

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Default Currency")) {
          if isLoading {
            ProgressView("Loading currencies...")
              .accessibilityIdentifier("LoadingIndicator")
          } else if let error = fetchError {
            VStack(alignment: .leading) {
              Text("Error: \(error)")
                .foregroundColor(.red)
                .accessibilityIdentifier("ErrorMessage")

              Button("Use Fallback Currencies") {
                self.supportedCurrencies = fallbackCurrencies
                self.fetchError = nil
              }
              .accessibilityIdentifier("FallbackButton")
            }
          } else {
            HStack {
              Text("Default Currency")
              Spacer()
              Button(action: {
                showingCurrencyPicker = true
              }) {
                HStack {
                  Text(defaultCurrency)
                    .foregroundColor(.primary)
                  Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
                }
              }
              .buttonStyle(PlainButtonStyle())
            }
            .accessibilityIdentifier("CurrencyPicker")
          }
        }

        Section(header: Text("About")) {
          HStack {
            Text("App Version")
            Spacer()
            Text("1.0.0")
              .foregroundColor(.secondary)
          }
          .accessibilityIdentifier("AppVersion")
        }
      }
      .accessibilityIdentifier("SettingsForm")
      .sheet(isPresented: $showingCurrencyPicker) {
        CurrencyPickerView(
          selectedCurrency: $defaultCurrency,
          supportedCurrencies: supportedCurrencies
        )
      }
      .onAppear {
        loadCurrencies()
      }
    }
  }

  private func loadCurrencies() {
    isLoading = true
    fetchError = nil

    // Set a timeout for the network call
    let timeoutWorkItem = DispatchWorkItem {
      DispatchQueue.main.async {
        if self.isLoading {
          self.supportedCurrencies = fallbackCurrencies
          self.isLoading = false
          if !fallbackCurrencies.contains(defaultCurrency) {
            defaultCurrency = "USD"
          }
        }
      }
    }

    // Execute timeout after 5 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: timeoutWorkItem)

    CurrencyExchange.shared.fetchSupportedCurrencies { result in
      DispatchQueue.main.async {
        // Cancel the timeout since we got a response
        timeoutWorkItem.cancel()

        switch result {
        case .success(let codes):
          self.supportedCurrencies = codes
          if !codes.contains(defaultCurrency) {
            defaultCurrency = codes.first ?? "USD"
          }
          isLoading = false
        case .failure(let error):
          // Use fallback currencies instead of showing error
          self.supportedCurrencies = fallbackCurrencies
          if !fallbackCurrencies.contains(defaultCurrency) {
            defaultCurrency = "USD"
          }
          isLoading = false
          fetchError = error.localizedDescription
        }
      }
    }
  }
}
