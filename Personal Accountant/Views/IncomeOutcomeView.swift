import Combine
import SwiftData
import SwiftUI

struct IncomeOutcomeView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var transactions: [Transaction]

  @AppStorage("defaultCurrency") private var defaultCurrency: String = "USD"
  @State private var showingAddSheet = false
  @State private var selectedTab: TransactionTab = .all
  @State private var selectedMonth: Date = Date()
  @State private var convertedTotal: Double? = nil
  @State private var isLoadingTotal = false
  @State private var conversionCancellable: AnyCancellable? = nil
  @State private var conversionErrorMessage: String? = nil
  @State private var editingTransaction: Transaction? = nil

  var filteredTransactions: [Transaction] {
    let calendar = Calendar.current
    let selectedComponents = calendar.dateComponents([.year, .month], from: selectedMonth)

    let monthFilteredTransactions = transactions.filter { transaction in
      let transactionComponents = calendar.dateComponents([.year, .month], from: transaction.date)
      return transactionComponents.year == selectedComponents.year
        && transactionComponents.month == selectedComponents.month
    }

    switch selectedTab {
    case .all:
      return monthFilteredTransactions.sorted { $0.date > $1.date }
    case .spending:
      return monthFilteredTransactions.filter { $0.type == .spending }.sorted {
        $0.date > $1.date
      }
    case .income:
      return monthFilteredTransactions.filter { $0.type == .income }.sorted {
        $0.date > $1.date
      }
    }
  }

  // Calculate the total in the user's preferred currency
  func calculateConvertedTotal() {
    isLoadingTotal = true
    let txs = filteredTransactions
    let preferred = defaultCurrency
    let group = DispatchGroup()
    var sum: Double = 0
    var errorOccurred = false
    var firstError: String? = nil
    for tx in txs {
      group.enter()
      let sign =
        (selectedTab == .all && tx.type == .spending) ? -1.0 : 1.0
      CurrencyExchange.shared.convert(
        amount: tx.amount,
        from: tx.currency,
        to: preferred
      ) { result in
        switch result {
        case .success(let converted):
          sum += converted * sign
        case .failure(let error):
          errorOccurred = true
          if firstError == nil {
            firstError =
              "Failed to convert \(tx.amount) \(tx.currency) to \(preferred): \(error.localizedDescription)"
          }
          print(
            "[CurrencyConversion] Error converting \(tx.amount) \(tx.currency) to \(preferred): \(error)"
          )
        }
        group.leave()
      }
    }
    group.notify(queue: .main) {
      self.convertedTotal = errorOccurred ? nil : sum
      self.isLoadingTotal = false
      if let firstError = firstError {
        self.conversionErrorMessage = firstError
      } else {
        self.conversionErrorMessage = nil
      }
    }
  }

  // Recalculate when transactions, tab, currency, or month changes
  private func recalculateOnChange() {
    convertedTotal = nil
    calculateConvertedTotal()
  }

  func accentColor(for tab: TransactionTab) -> Color {
    switch tab {
    case .spending: return .red
    case .income: return .green
    case .all: return .blue
    }
  }

  func icon(for type: TransactionType) -> String {
    switch type {
    case .spending: return "minus.circle.fill"
    case .income: return "plus.circle.fill"
    }
  }

  // MARK: - Gesture Handling
  private func handleSwipeGesture(_ value: DragGesture.Value) {
    let horizontalDrag = value.translation.width
    let verticalDrag = abs(value.translation.height)

    // Only trigger if horizontal drag is significantly larger than vertical
    guard abs(horizontalDrag) > verticalDrag * 2 else { return }

    withAnimation(.easeInOut(duration: 0.3)) {
      if horizontalDrag > 0 {
        navigateToPreviousMonth()
      } else {
        navigateToNextMonth()
      }
    }
  }

  private func navigateToPreviousMonth() {
    selectedMonth =
      Calendar.current.date(
        byAdding: .month,
        value: -1,
        to: selectedMonth
      ) ?? selectedMonth
  }

  private func navigateToNextMonth() {
    selectedMonth =
      Calendar.current.date(
        byAdding: .month,
        value: 1,
        to: selectedMonth
      ) ?? selectedMonth
  }

  var body: some View {
    NavigationView {
      VStack(alignment: .leading, spacing: 12) {
        Picker("Type", selection: $selectedTab) {
          ForEach(TransactionTab.allCases) { tab in
            Text(tab.label).tag(tab)
          }
        }
        .pickerStyle(.segmented)
        .padding([.horizontal, .top])

        Group {
          if isLoadingTotal {
            headerViewWithDatePicker(
              title: selectedTab == .all
                ? "Net Total"
                : (selectedTab == .spending
                  ? "Total Spending" : "Total Income"),
              amount: 0,
              color: accentColor(for: selectedTab)
            )
            .redacted(reason: .placeholder)
          } else if let total = convertedTotal {
            headerViewWithDatePicker(
              title: selectedTab == .all
                ? "Net Total"
                : (selectedTab == .spending
                  ? "Total Spending" : "Total Income"),
              amount: total,
              color: accentColor(for: selectedTab),
              currency: defaultCurrency
            )
          } else {
            headerViewWithDatePicker(
              title: "Could not convert all currencies",
              amount: 0,
              color: .gray,
              currency: defaultCurrency
            )
            if let msg = conversionErrorMessage {
              Text(msg).font(.caption).foregroundColor(.red)
                .padding(.horizontal)
            }
          }
        }

        TransactionListView(
          transactions: filteredTransactions,
          selectedTab: selectedTab,
          accentColor: accentColor,
          icon: icon,
          onDelete: { transaction in
            withAnimation {
              modelContext.delete(transaction)
            }
          },
          onEdit: { transaction in
            editingTransaction = transaction
          }
        )
      }
      .gesture(
        DragGesture(minimumDistance: 50)
          .onEnded(handleSwipeGesture)
      )
      .navigationTitle("Income/Outcome")
      .toolbar {
        ToolbarItem {
          Button(action: { showingAddSheet = true }) {
            Label("Add", systemImage: "plus")
          }
        }
      }
      .background(Color(.systemGroupedBackground))
      .onAppear(perform: recalculateOnAppear)
      .onChange(of: transactions) { recalculateOnChange() }
      .onChange(of: selectedTab) { recalculateOnChange() }
      .onChange(of: selectedMonth) { recalculateOnChange() }
      .onChange(of: defaultCurrency) { recalculateOnChange() }
    }
    .accentColor(accentColor(for: selectedTab))
    .sheet(isPresented: $showingAddSheet) {
      AddSpendingView(type: .spending) {
        category,
        amount,
        currency,
        detail,
        date,
        type in
        addTransaction(
          category: category,
          amount: amount,
          currency: currency,
          detail: detail,
          date: date,
          type: type
        )
      }
    }
    .sheet(
      isPresented: Binding<Bool>(
        get: { editingTransaction != nil },
        set: { if !$0 { editingTransaction = nil } }
      )
    ) {
      if let transaction = editingTransaction {
        AddSpendingView(
          type: transaction.type,
          editingTransaction: transaction
        ) { category, amount, currency, detail, date, type in
          editTransaction(
            transaction: transaction,
            category: category,
            amount: amount,
            currency: currency,
            detail: detail,
            date: date,
            type: type
          )
        }
      }
    }
  }

  private func addTransaction(
    category: String,
    amount: Double,
    currency: String,
    detail: String,
    date: Date,
    type: TransactionType
  ) {
    withAnimation {
      let newTransaction = Transaction(
        category: category,
        amount: amount,
        currency: currency,
        detail: detail,
        date: date,
        type: type
      )
      modelContext.insert(newTransaction)
    }
  }

  // MARK: - Styled Views
  func headerViewWithDatePicker(
    title: String,
    amount: Double,
    color: Color,
    currency: String? = nil
  ) -> some View {
    HStack {
      MonthPicker(selectedMonth: $selectedMonth)
        .padding(.horizontal)

      Spacer()

      VStack(alignment: .trailing, spacing: 4) {
        Text(title)
          .font(.title2)
          .bold()
        if let currency = currency {
          Text("\(amount, specifier: "%.2f") \(currency)")
            .font(.title2)
            .bold()
            .foregroundColor(color)
        } else {
          Text("$\(amount, specifier: "%.2f")")
            .font(.title2)
            .bold()
            .foregroundColor(color)
        }
      }
    }
    .padding()
    .background(color.opacity(0.1))
    .cornerRadius(12)
    .padding(.horizontal)
  }

  func headerView(
    title: String,
    amount: Double,
    color: Color,
    currency: String? = nil
  ) -> some View {
    HStack {
      Text(title)
        .font(.title2)
        .bold()
      Spacer()
      if let currency = currency {
        Text("\(amount, specifier: "%.2f") \(currency)")
          .font(.title2)
          .bold()
          .foregroundColor(color)
      } else {
        Text("$\(amount, specifier: "%.2f")")
          .font(.title2)
          .bold()
          .foregroundColor(color)
      }
    }
    .padding()
    .background(color.opacity(0.1))
    .cornerRadius(12)
    .padding(.horizontal)
  }

  func transactionList(transactions: [Transaction]) -> some View {
    // No longer used, but keep for reference
    EmptyView()
  }

  // Call this on appear
  private func recalculateOnAppear() {
    recalculateOnChange()
  }

  private func editTransaction(
    transaction: Transaction,
    category: String,
    amount: Double,
    currency: String,
    detail: String,
    date: Date,
    type: TransactionType
  ) {
    withAnimation {
      transaction.category = category
      transaction.amount = amount
      transaction.currency = currency
      transaction.detail = detail
      transaction.date = date
      transaction.type = type
    }
  }
}
