import Combine
import SwiftData
import SwiftUI

// MARK: - Sort Option Enum
enum SortOption: String, CaseIterable, Identifiable {
  case date = "Date"
  case amount = "Amount"

  var id: String { self.rawValue }
  var label: String { self.rawValue }
}

// MARK: - Sort Order Enum
enum SortOrder: String, CaseIterable, Identifiable {
  case ascending = "ASC"
  case descending = "DESC"

  var id: String { self.rawValue }
  var systemImageName: String {
    switch self {
    case .ascending: return "chevron.up"
    case .descending: return "chevron.down"
    }
  }
}

struct IncomeOutcomeView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var transactions: [Transaction]
  @AppStorage("defaultCurrency") private var defaultCurrency: String = "USD"

  // MARK: - UI State
  @State private var showingAddSheet = false
  @State private var editingTransaction: Transaction? = nil
  @State private var selectedTab: TransactionTab = .all
  @State private var selectedMonth: Date = Date()
  @State private var sortOption: SortOption = .date
  @State private var sortOrder: SortOrder = .descending

  // MARK: - Conversion State
  @State private var convertedTotal: Double? = nil
  @State private var isLoadingTotal = false
  @State private var conversionCancellable: AnyCancellable? = nil
  @State private var conversionErrorMessage: String? = nil

  // MARK: - Gesture State
  @State private var dragOffset: CGFloat = 0
  @State private var isDragging: Bool = false

  // MARK: - Constants
  private static let monthFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    return formatter
  }()

  private enum Constants {
    static let maxSwipeOffset: CGFloat = 120
    static let swipeResistance: CGFloat = 0.3
    static let minSwipeDistance: CGFloat = 60
    static let minimumDragDistance: CGFloat = 20
  }

  // MARK: - Computed Properties
  var filteredTransactions: [Transaction] {
    getTransactions(for: selectedMonth)
  }

  var previousMonthTransactions: [Transaction] {
    guard let prevMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth)
    else { return [] }
    return getTransactions(for: prevMonth)
  }

  var nextMonthTransactions: [Transaction] {
    guard let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth)
    else { return [] }
    return getTransactions(for: nextMonth)
  }

  // MARK: - Transaction Filtering
  private func getTransactions(for month: Date) -> [Transaction] {
    let calendar = Calendar.current
    let monthComponents = calendar.dateComponents([.year, .month], from: month)

    let monthFilteredTransactions = transactions.filter { transaction in
      let transactionComponents = calendar.dateComponents([.year, .month], from: transaction.date)
      return transactionComponents.year == monthComponents.year
        && transactionComponents.month == monthComponents.month
    }

    let typeFilteredTransactions: [Transaction]
    switch selectedTab {
    case .all:
      typeFilteredTransactions = monthFilteredTransactions
    case .spending:
      typeFilteredTransactions = monthFilteredTransactions.filter { $0.type == .spending }
    case .income:
      typeFilteredTransactions = monthFilteredTransactions.filter { $0.type == .income }
    }

    // Apply sorting based on selected sort option
    let sortedTransactions: [Transaction]
    switch sortOption {
    case .date:
      if sortOrder == .descending {
        sortedTransactions = typeFilteredTransactions.sorted { $0.date > $1.date }
      } else {
        sortedTransactions = typeFilteredTransactions.sorted { $0.date < $1.date }
      }
    case .amount:
      if sortOrder == .descending {
        sortedTransactions = typeFilteredTransactions.sorted { $0.amount > $1.amount }
      } else {
        sortedTransactions = typeFilteredTransactions.sorted { $0.amount < $1.amount }
      }
    }

    return sortedTransactions
  }

  // MARK: - Currency Conversion
  private func calculateConvertedTotal() {
    isLoadingTotal = true
    conversionErrorMessage = nil

    let transactions = filteredTransactions
    let targetCurrency = defaultCurrency
    let dispatchGroup = DispatchGroup()

    var totalSum: Double = 0
    var hasConversionError = false
    var firstErrorMessage: String? = nil

    for transaction in transactions {
      dispatchGroup.enter()

      let multiplier = getTransactionMultiplier(for: transaction)

      CurrencyExchange.shared.convert(
        amount: transaction.amount,
        from: transaction.currency,
        to: targetCurrency
      ) { result in
        defer { dispatchGroup.leave() }

        switch result {
        case .success(let convertedAmount):
          totalSum += convertedAmount * multiplier
        case .failure(let error):
          hasConversionError = true
          if firstErrorMessage == nil {
            firstErrorMessage =
              "Failed to convert \(transaction.amount) \(transaction.currency) to \(targetCurrency): \(error.localizedDescription)"
          }
          print("[CurrencyConversion] Error: \(error)")
        }
      }
    }

    dispatchGroup.notify(queue: .main) {
      self.convertedTotal = hasConversionError ? nil : totalSum
      self.isLoadingTotal = false
      self.conversionErrorMessage = firstErrorMessage
    }
  }

  private func getTransactionMultiplier(for transaction: Transaction) -> Double {
    return (selectedTab == .all && transaction.type == .spending) ? -1.0 : 1.0
  }

  private func recalculateTotal() {
    convertedTotal = nil
    calculateConvertedTotal()
  }

  // MARK: - UI Helpers
  private func accentColor(for tab: TransactionTab) -> Color {
    switch tab {
    case .spending: return .red
    case .income: return .green
    case .all: return .blue
    }
  }

  private func icon(for type: TransactionType) -> String {
    switch type {
    case .spending: return "minus.circle.fill"
    case .income: return "plus.circle.fill"
    }
  }

  private func monthTitle(for date: Date) -> String {
    Self.monthFormatter.string(from: date)
  }

  private func totalTitle() -> String {
    switch selectedTab {
    case .all: return "Net Total"
    case .spending: return "Total Spending"
    case .income: return "Total Income"
    }
  }

  // MARK: - Gesture Handling
  private func handleSwipeGesture(_ value: DragGesture.Value) {
    let horizontalDrag = value.translation.width
    let verticalDrag = abs(value.translation.height)

    // Only trigger if horizontal drag is significantly larger than vertical
    guard abs(horizontalDrag) > verticalDrag * 2 else { return }

    // Apply resistance at the edges
    if abs(horizontalDrag) <= Constants.maxSwipeOffset {
      dragOffset = horizontalDrag
    } else {
      let sign: CGFloat = horizontalDrag > 0 ? 1 : -1
      let excess = abs(horizontalDrag) - Constants.maxSwipeOffset
      dragOffset = sign * (Constants.maxSwipeOffset + excess * Constants.swipeResistance)
    }

    isDragging = true
  }

  private func handleSwipeEnd(_ value: DragGesture.Value) {
    let horizontalDrag = value.translation.width
    let verticalDrag = abs(value.translation.height)

    // Only trigger if horizontal drag is significantly larger than vertical
    guard abs(horizontalDrag) > verticalDrag * 2 else {
      resetDragState()
      return
    }

    // Check if swipe meets minimum distance requirement
    if abs(horizontalDrag) > Constants.minSwipeDistance {
      withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
        if horizontalDrag > 0 {
          navigateToPreviousMonth()
        } else {
          navigateToNextMonth()
        }
        resetDragState()
      }
    } else {
      // Snap back if not enough distance
      withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
        resetDragState()
      }
    }
  }

  private func resetDragState() {
    dragOffset = 0
    isDragging = false
  }

  // MARK: - Navigation
  private func navigateToPreviousMonth() {
    selectedMonth =
      Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
  }

  private func navigateToNextMonth() {
    selectedMonth =
      Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
  }

  // MARK: - Transaction Management
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

  private func addBulkTransactions(_ transactions: [TransactionData]) {
    withAnimation {
      for transactionData in transactions {
        let newTransaction = Transaction(
          category: transactionData.category,
          amount: transactionData.amount,
          currency: transactionData.currency,
          detail: transactionData.detail,
          date: transactionData.date,
          type: transactionData.type
        )
        modelContext.insert(newTransaction)
      }
    }
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

  // MARK: - Main View
  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 12) {
        tabSelector
        monthSwipeView
      }
      .toolbar { addButton }
      .background(Color(.systemGroupedBackground))
      .onAppear { recalculateTotal() }
      .onChange(of: transactions) { recalculateTotal() }
      .onChange(of: selectedTab) { recalculateTotal() }
      .onChange(of: selectedMonth) { recalculateTotal() }
      .onChange(of: defaultCurrency) { recalculateTotal() }
      .onChange(of: sortOption) { recalculateTotal() }
      .onChange(of: sortOrder) { recalculateTotal() }
    }
    .accentColor(accentColor(for: selectedTab))
    .sheet(isPresented: $showingAddSheet) { addTransactionSheet }
    .sheet(isPresented: editingTransactionBinding) { editTransactionSheet }
  }

  // MARK: - View Components
  private var tabSelector: some View {
    Picker("Type", selection: $selectedTab) {
      ForEach(TransactionTab.allCases) { tab in
        Text(tab.label).tag(tab)
      }
    }
    .pickerStyle(.segmented)
    .padding([.horizontal, .top])
  }

  private var monthSwipeView: some View {
    VStack(alignment: .leading, spacing: 12) {
      GeometryReader { geometry in
        HStack(spacing: 0) {
          monthContentView(
            for: Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth)
              ?? selectedMonth,
            transactions: previousMonthTransactions,
            isCurrentMonth: false
          )
          .frame(width: geometry.size.width)

          monthContentView(
            for: selectedMonth,
            transactions: filteredTransactions,
            isCurrentMonth: true
          )
          .frame(width: geometry.size.width)

          monthContentView(
            for: Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth)
              ?? selectedMonth,
            transactions: nextMonthTransactions,
            isCurrentMonth: false
          )
          .frame(width: geometry.size.width)
        }
        .offset(x: dragOffset - geometry.size.width)
      }
      .gesture(swipeGesture)
    }
  }

  private var swipeGesture: some Gesture {
    DragGesture(minimumDistance: Constants.minimumDragDistance)
      .onChanged(handleSwipeGesture)
      .onEnded(handleSwipeEnd)
  }

  private var addButton: some ToolbarContent {
    ToolbarItem {
      Button(action: { showingAddSheet = true }) {
        Label("Add", systemImage: "plus")
      }
    }
  }

  private var editingTransactionBinding: Binding<Bool> {
    Binding<Bool>(
      get: { editingTransaction != nil },
      set: { if !$0 { editingTransaction = nil } }
    )
  }

  private var addTransactionSheet: some View {
    AddSpendingView(type: .spending) { category, amount, currency, detail, date, type in
      addTransaction(
        category: category,
        amount: amount,
        currency: currency,
        detail: detail,
        date: date,
        type: type
      )
    } onBulkSave: { transactions in
      addBulkTransactions(transactions)
    }
  }

  @ViewBuilder
  private var editTransactionSheet: some View {
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

  // MARK: - Month Content View
  private func monthContentView(
    for month: Date, transactions: [Transaction], isCurrentMonth: Bool = false
  ) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      headerSection(for: month, isCurrentMonth: isCurrentMonth)

      if isCurrentMonth && conversionErrorMessage != nil {
        errorMessageView
      }

      TransactionListView(
        transactions: transactions,
        selectedTab: selectedTab,
        accentColor: accentColor,
        icon: icon,
        onDelete: isCurrentMonth ? deleteTransaction : { _ in },
        onEdit: isCurrentMonth ? { editingTransaction = $0 } : { _ in }
      )
    }
  }

  @ViewBuilder
  private func headerSection(for month: Date, isCurrentMonth: Bool) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      // Net total row
      if isLoadingTotal {
        netTotalRow(
          title: totalTitle(),
          amount: 0,
          color: accentColor(for: selectedTab)
        )
        .redacted(reason: .placeholder)
      } else if convertedTotal != nil {
        netTotalRow(
          title: totalTitle(),
          amount: convertedTotal!,
          color: accentColor(for: selectedTab),
          currency: defaultCurrency
        )
      }
      // Month picker and sort option row
      monthPickerAndSortRow
    }
  }

  private var errorMessageView: some View {
    Text(conversionErrorMessage!)
      .font(.caption)
      .foregroundColor(.red)
      .padding(.horizontal)
  }

  private func deleteTransaction(_ transaction: Transaction) {
    withAnimation {
      modelContext.delete(transaction)
    }
  }

  private var monthPickerAndSortRow: some View {
    HStack {
      MonthPicker(selectedMonth: $selectedMonth)

      Picker("Sort", selection: $sortOption) {
        ForEach(SortOption.allCases) { option in
          Text(option.label).tag(option)
        }
      }
      .pickerStyle(.segmented)

      Button(action: {
        sortOrder = sortOrder == .ascending ? .descending : .ascending
      }) {
        HStack(spacing: 4) {
          Text("↑")
            .foregroundColor(sortOrder == .ascending ? .accentColor : .secondary)
          Text("↓")
            .foregroundColor(sortOrder == .descending ? .accentColor : .secondary)
        }
        .font(.title3)
      }
      .buttonStyle(PlainButtonStyle())
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .cornerRadius(12)
  }

  private func netTotalRow(
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
}
