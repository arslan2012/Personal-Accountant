import SwiftUI

struct AddSpendingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "USD"
    @State private var category = ""
    @State private var amount = ""
    @State private var currency: String
    @State private var detail = ""
    @State private var date = Date()
    @State private var selectedType: TransactionType
    @State private var supportedCurrencies: [String] = []
    @State private var isLoading = true
    @State private var fetchError: String? = nil
    var onSave: (String, Double, String, String, Date, TransactionType) -> Void

    init(
        type: TransactionType,
        onSave: @escaping (
            String, Double, String, String, Date, TransactionType
        ) -> Void
    ) {
        self._selectedType = State(initialValue: type)
        // currency will be set in .onAppear
        self._currency = State(initialValue: "")
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                Picker("Type", selection: $selectedType) {
                    ForEach(TransactionType.allCases, id: \.self) { t in
                        Text(t.rawValue.capitalized).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                TextField("Category", text: $category)
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                if isLoading {
                    ProgressView("Loading currencies...")
                } else if let error = fetchError {
                    Text("Error: \(error)").foregroundColor(.red)
                } else {
                    Picker("Currency", selection: $currency) {
                        ForEach(supportedCurrencies, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                }
                TextField("Detail", text: $detail)
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            .navigationTitle(selectedType.rawValue.capitalized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amountValue = Double(amount), !category.isEmpty,
                            !currency.isEmpty
                        {
                            onSave(
                                category,
                                amountValue,
                                currency,
                                detail,
                                date,
                                selectedType
                            )
                            dismiss()
                        }
                    }
                    .disabled(
                        category.isEmpty || currency.isEmpty
                            || Double(amount) == nil || isLoading
                    )
                }
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
