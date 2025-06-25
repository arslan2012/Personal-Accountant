import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "USD"
    @State private var tempCurrency: String = ""
    @State private var supportedCurrencies: [String] = []
    @State private var isLoading = true
    @State private var fetchError: String? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Default Currency")) {
                    if isLoading {
                        ProgressView("Loading currencies...")
                    } else if let error = fetchError {
                        Text("Error: \(error)").foregroundColor(.red)
                    } else {
                        Picker("Currency", selection: $defaultCurrency) {
                            ForEach(supportedCurrencies, id: \.self) { code in
                                Text(code).tag(code)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                isLoading = true
                fetchError = nil
                CurrencyExchange.fetchSupportedCurrencies { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let codes):
                            self.supportedCurrencies = codes
                            if !codes.contains(defaultCurrency) {
                                defaultCurrency = codes.first ?? "USD"
                            }
                            isLoading = false
                        case .failure(let error):
                            fetchError = error.localizedDescription
                            isLoading = false
                        }
                    }
                }
            }
        }
    }
} 