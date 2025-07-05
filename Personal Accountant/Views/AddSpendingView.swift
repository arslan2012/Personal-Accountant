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
  @State private var showingImageUpload = false

  var onSave: (String, Double, String, String, Date, TransactionType) -> Void
  var onBulkSave: ([TransactionData]) -> Void = { _ in }

  private let editingTransaction: Transaction?

  init(
    type: TransactionType,
    editingTransaction: Transaction? = nil,
    onSave: @escaping (
      String, Double, String, String, Date, TransactionType
    ) -> Void,
    onBulkSave: @escaping ([TransactionData]) -> Void = { _ in }
  ) {
    self.editingTransaction = editingTransaction
    self._selectedType = State(initialValue: type)
    self.onSave = onSave
    self.onBulkSave = onBulkSave

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
    NavigationStack {
      Form {
        // Only show image upload button for new transactions
        if editingTransaction == nil {
          Section {
            Button(action: {
              showingImageUpload = true
            }) {
              HStack {
                Image(systemName: "camera.viewfinder")
                  .font(.title3)
                  .foregroundColor(.blue)
                Text("Upload Receipt")
                  .font(.headline)
                  .foregroundColor(.blue)
                Spacer()
                Image(systemName: "chevron.right")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
              .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())

            Text("Take a photo or select an image to automatically extract transaction details")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }

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
      .sheet(isPresented: $showingImageUpload) {
        ImageUploadView(
          onConfirmTransactionsAddition: { transactionDataList in
            if transactionDataList.count == 1 {
              // Single transaction - populate form fields with extracted data
              let transactionData = transactionDataList[0]
              category = transactionData.category
              amount = String(transactionData.amount)
              currency = transactionData.currency
              detail = transactionData.detail
              date = transactionData.date
              selectedType = transactionData.type
            } else {
              // Multiple transactions - pass TransactionData directly
              onBulkSave(transactionDataList)
              dismiss()
            }
          }
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
