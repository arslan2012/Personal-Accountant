import SwiftUI

struct AddSpendingView: View {
  @Environment(\.dismiss) private var dismiss
  @AppStorage("defaultCurrency") private var defaultCurrency: String = "USD"
  @State private var category = ""
  @State private var amount = ""
  @State private var currency = ""
  @State private var detail = ""
  @State private var date = Date()
  @State private var selectedType: TransactionType
  @State private var supportedCurrencies: [String] = []
  @State private var isLoading = true
  @State private var fetchError: String? = nil
  @State private var showingCurrencyPicker = false
  var onSave: (String, Double, String, String, Date, TransactionType) -> Void

  private let editingTransaction: Transaction?

  init(
    type: TransactionType,
    editingTransaction: Transaction? = nil,
    onSave: @escaping (
      String, Double, String, String, Date, TransactionType
    ) -> Void
  ) {
    self.editingTransaction = editingTransaction
    self._selectedType = State(initialValue: type)
    self.onSave = onSave

    // Set initial values based on whether we're editing or creating new
    if let transaction = editingTransaction {
      self._category = State(initialValue: transaction.category)
      self._amount = State(initialValue: String(transaction.amount))
      self._currency = State(initialValue: transaction.currency)
      self._detail = State(initialValue: transaction.detail)
      self._date = State(initialValue: transaction.date)
      self._selectedType = State(initialValue: transaction.type)
    }
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
          HStack {
            Text("Currency")
            Spacer()
            Button(action: {
              showingCurrencyPicker = true
            }) {
              HStack {
                Text(
                  currency.isEmpty
                    ? "Select Currency" : currency
                )
                .foregroundColor(
                  currency.isEmpty ? .secondary : .primary
                )
                Image(systemName: "chevron.right")
                  .foregroundColor(.secondary)
                  .font(.caption)
              }
            }
            .buttonStyle(PlainButtonStyle())
          }
        }
        TextField("Detail", text: $detail)
        DatePicker("Date", selection: $date, displayedComponents: .date)
      }
      .navigationTitle(
        editingTransaction != nil
          ? "Edit Transaction" : selectedType.rawValue.capitalized
      )
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(editingTransaction != nil ? "Update" : "Save") {
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
