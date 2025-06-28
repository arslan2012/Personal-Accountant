import SwiftUI

struct AddAssetView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "USD"
    @State private var name = ""
    @State private var amount = ""
    @State private var currency: String
    @State private var type: AssetType = .savings
    @State private var detail = ""
    @State private var supportedCurrencies: [String] = []
    @State private var isLoading = true
    @State private var fetchError: String? = nil
    @State private var showingCurrencyPicker = false
    var onSave: (String, Double, String, AssetType, String?) -> Void

    init(onSave: @escaping (String, Double, String, AssetType, String?) -> Void)
    {
        self._currency = State(initialValue: "")
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $name)
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                if isLoading {
                    ProgressView("Loading currencies...")
                } else if let error = fetchError {
                    Text("Error: \(error)").foregroundColor(.red)
                } else {
                    HStack {
                        Text("Currency")
                        Spacer()
                        Button(action: {
                            showingCurrencyPicker = true
                        }) {
                            HStack {
                                Text(currency.isEmpty ? "Select Currency" : currency)
                                    .foregroundColor(currency.isEmpty ? .secondary : .primary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                Picker("Type", selection: $type) {
                    ForEach(AssetType.allCases, id: \.self) { t in
                        Text(t.rawValue.capitalized).tag(t)
                    }
                }
                TextField("Detail (optional)", text: $detail)
            }
            .navigationTitle("Add Asset")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amountValue = Double(amount), !name.isEmpty,
                            !currency.isEmpty
                        {
                            onSave(
                                name,
                                amountValue,
                                currency,
                                type,
                                detail.isEmpty ? nil : detail
                            )
                            dismiss()
                        }
                    }
                    .disabled(
                        name.isEmpty || currency.isEmpty
                            || Double(amount) == nil || isLoading
                    )
                }
            }
            .sheet(isPresented: $showingCurrencyPicker) {
                CurrencyPickerView(
                    selectedCurrency: $currency,
                    supportedCurrencies: supportedCurrencies
                )
            }
            .onAppear {
                if currency.isEmpty {
                    currency = defaultCurrency
                }
                isLoading = true
                fetchError = nil
                CurrencyExchange.shared.fetchSupportedCurrencies { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let codes):
                            self.supportedCurrencies = codes
                            if !codes.contains(currency) {
                                currency = codes.first ?? "USD"
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
