import SwiftUI

struct TransactionReviewView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var editableTransactions: [EditableTransactionData]
  @State private var showingConfirmation = false

  let originalTransactions: [TransactionData]
  let onSave: ([TransactionData]) -> Void
  let onCancel: (() -> Void)?

  init(
    transactions: [TransactionData], onSave: @escaping ([TransactionData]) -> Void,
    onCancel: (() -> Void)? = nil
  ) {
    self.originalTransactions = transactions
    self.onSave = onSave
    self.onCancel = onCancel
    self._editableTransactions = State(
      initialValue: transactions.map { EditableTransactionData(from: $0) })
  }

  var body: some View {
    NavigationView {
      VStack {
        headerView
        contentView
      }
      .navigationTitle("Review Transactions")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            onCancel?()
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            showingConfirmation = true
          }
          .fontWeight(.semibold)
          .disabled(editableTransactions.isEmpty)
        }
      }
      .confirmationDialog(
        "Save Transactions?",
        isPresented: $showingConfirmation,
        titleVisibility: .visible
      ) {
        Button(
          "Save \(editableTransactions.count) Transaction\(editableTransactions.count > 1 ? "s" : "")"
        ) {
          let finalTransactions = editableTransactions.map { $0.toTransactionData() }
          onSave(finalTransactions)
          dismiss()
        }

        Button("Cancel", role: .cancel) {}
      } message: {
        Text("Are you sure you want to save these transactions to your account?")
      }
    }
  }

  @ViewBuilder
  private var headerView: some View {
    if editableTransactions.count > 1 {
      VStack(spacing: 8) {
        Image(systemName: "doc.text.magnifyingglass")
          .font(.system(size: 40))
          .foregroundColor(.blue)

        Text("Review Extracted Transactions")
          .font(.title2)
          .fontWeight(.semibold)

        Text(
          "We found \(editableTransactions.count) transactions. Please review and edit as needed."
        )
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
      }
      .padding()
    }
  }

  @ViewBuilder
  private var contentView: some View {
    if editableTransactions.isEmpty {
      emptyStateView
    } else {
      transactionFormView
    }
  }

  private var emptyStateView: some View {
    VStack(spacing: 16) {
      Image(systemName: "trash")
        .font(.system(size: 48))
        .foregroundColor(.gray)

      Text("No transactions to review")
        .font(.headline)
        .foregroundColor(.secondary)

      Text("All transactions have been removed. You can cancel to go back.")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }

  private var transactionFormView: some View {
    Form {
      ForEach(editableTransactions.indices, id: \.self) { index in
        Section(
          header: editableTransactions.count > 1
            ? Text("Transaction \(index + 1)") : Text("Transaction Details")
        ) {
          TransactionEditRow(
            transaction: $editableTransactions[index],
            showDeleteButton: editableTransactions.count > 1,
            onDelete: editableTransactions.count > 1
              ? {
                deleteTransaction(at: IndexSet(integer: index))
              } : nil
          )
        }
      }
      .onDelete(perform: editableTransactions.count > 1 ? deleteTransaction : nil)
    }
    .scrollDismissesKeyboard(.interactively)
  }

  // MARK: - Helper Functions
  private func deleteTransaction(at offsets: IndexSet) {
    editableTransactions.remove(atOffsets: offsets)
  }
}

// MARK: - Editable Transaction Data
struct EditableTransactionData {
  var category: String
  var amount: String
  var currency: String
  var detail: String
  var date: Date
  var type: TransactionType

  init(from transactionData: TransactionData) {
    self.category = transactionData.category
    self.amount = String(format: "%.2f", transactionData.amount)
    self.currency = transactionData.currency
    self.detail = transactionData.detail
    self.date = transactionData.date
    self.type = transactionData.type
  }

  func toTransactionData() -> TransactionData {
    return TransactionData(
      category: category,
      amount: Double(amount) ?? 0.0,
      currency: currency,
      detail: detail,
      date: date,
      type: type
    )
  }
}

// MARK: - Transaction Edit Row
struct TransactionEditRow: View {
  @Binding var transaction: EditableTransactionData
  @FocusState private var focusedField: Field?

  let showDeleteButton: Bool
  let onDelete: (() -> Void)?

  init(
    transaction: Binding<EditableTransactionData>,
    showDeleteButton: Bool = false,
    onDelete: (() -> Void)? = nil
  ) {
    self._transaction = transaction
    self.showDeleteButton = showDeleteButton
    self.onDelete = onDelete
  }

  enum Field {
    case category, amount, currency, detail
  }

  var body: some View {
    VStack(spacing: 16) {
      // Category
      HStack {
        Text("Category")
          .frame(width: 80, alignment: .leading)
        TextField("Enter category", text: $transaction.category)
          .focused($focusedField, equals: .category)
          .textFieldStyle(RoundedBorderTextFieldStyle())
      }

      // Amount and Currency
      HStack {
        Text("Amount")
          .frame(width: 80, alignment: .leading)
        TextField("0.00", text: $transaction.amount)
          .keyboardType(.decimalPad)
          .focused($focusedField, equals: .amount)
          .textFieldStyle(RoundedBorderTextFieldStyle())

        TextField("USD", text: $transaction.currency)
          .frame(width: 60)
          .focused($focusedField, equals: .currency)
          .textFieldStyle(RoundedBorderTextFieldStyle())
      }

      // Detail
      HStack {
        Text("Detail")
          .frame(width: 80, alignment: .leading)
        TextField("Enter details", text: $transaction.detail)
          .focused($focusedField, equals: .detail)
          .textFieldStyle(RoundedBorderTextFieldStyle())
      }

      // Date
      HStack {
        Text("Date")
          .frame(width: 80, alignment: .leading)
        DatePicker(
          "",
          selection: $transaction.date,
          displayedComponents: [.date]
        )
        .labelsHidden()
        Spacer()
      }

      // Type
      HStack {
        Text("Type")
          .frame(width: 80, alignment: .leading)
        Picker("Transaction Type", selection: $transaction.type) {
          ForEach(TransactionType.allCases, id: \.self) { type in
            Text(type.rawValue.capitalized)
              .tag(type)
          }
        }
        .pickerStyle(SegmentedPickerStyle())
      }

      // Delete Button
      if showDeleteButton {
        Button(action: {
          onDelete?()
        }) {
          HStack {
            Image(systemName: "trash")
              .foregroundColor(.red)
            Text("Remove Transaction")
              .foregroundColor(.red)
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.red.opacity(0.1))
          .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, 8)
      }
    }
    .padding(.vertical, 8)
  }
}

#Preview {
  TransactionReviewView(
    transactions: [
      TransactionData(
        category: "Food & Dining",
        amount: 25.50,
        currency: "USD",
        detail: "Lunch at restaurant",
        date: Date(),
        type: .spending
      ),
      TransactionData(
        category: "Transportation",
        amount: 15.00,
        currency: "USD",
        detail: "Uber ride",
        date: Date(),
        type: .spending
      ),
    ],
    onSave: { _ in },
    onCancel: {}
  )
}
