import SwiftUI
import SwiftData
import Combine

enum TransactionTab: String, CaseIterable, Identifiable {
    case all, spending, income
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: return "All"
        case .spending: return "Spending"
        case .income: return "Income"
        }
    }
}

struct IncomeOutcomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "USD"
    @State private var showingAddSheet = false
    @State private var selectedTab: TransactionTab = .all
    @State private var convertedTotal: Double? = nil
    @State private var isLoadingTotal = false
    @State private var conversionCancellable: AnyCancellable? = nil
    @State private var conversionErrorMessage: String? = nil
    
    var filteredTransactions: [Transaction] {
        switch selectedTab {
        case .all:
            return transactions.sorted { $0.date > $1.date }
        case .spending:
            return transactions.filter { $0.type == .spending }.sorted { $0.date > $1.date }
        case .income:
            return transactions.filter { $0.type == .income }.sorted { $0.date > $1.date }
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
            let sign = (selectedTab == .all && tx.type == .spending) ? -1.0 : 1.0
            CurrencyExchange.shared.convert(amount: tx.amount, from: tx.currency, to: preferred) { result in
                switch result {
                case .success(let converted):
                    sum += converted * sign
                case .failure(let error):
                    errorOccurred = true
                    if firstError == nil {
                        firstError = "Failed to convert \(tx.amount) \(tx.currency) to \(preferred): \(error.localizedDescription)"
                    }
                    print("[CurrencyConversion] Error converting \(tx.amount) \(tx.currency) to \(preferred): \(error)")
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
    
    // Recalculate when transactions, tab, or currency changes
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
                        headerView(title: selectedTab == .all ? "Net Total" : (selectedTab == .spending ? "Total Spending" : "Total Income"), amount: 0, color: accentColor(for: selectedTab))
                            .redacted(reason: .placeholder)
                    } else if let total = convertedTotal {
                        headerView(title: selectedTab == .all ? "Net Total" : (selectedTab == .spending ? "Total Spending" : "Total Income"), amount: total, color: accentColor(for: selectedTab), currency: defaultCurrency)
                    } else {
                        headerView(title: "Could not convert all currencies", amount: 0, color: .gray, currency: defaultCurrency)
                        if let msg = conversionErrorMessage {
                            Text(msg).font(.caption).foregroundColor(.red).padding(.horizontal)
                        }
                    }
                }
                transactionList(transactions: filteredTransactions)
            }
            .navigationTitle("Income/Outcome")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .onAppear(perform: recalculateOnChange)
            .onChange(of: transactions) { _ in recalculateOnChange() }
            .onChange(of: selectedTab) { _ in recalculateOnChange() }
            .onChange(of: defaultCurrency) { _ in recalculateOnChange() }
        }
        .accentColor(accentColor(for: selectedTab))
        .sheet(isPresented: $showingAddSheet) {
            AddSpendingView(type: .spending) { category, amount, currency, detail, date, type in
                addTransaction(category: category, amount: amount, currency: currency, detail: detail, date: date, type: type)
            }
        }
    }

    private func addTransaction(category: String, amount: Double, currency: String, detail: String, date: Date, type: TransactionType) {
        withAnimation {
            let newTransaction = Transaction(category: category, amount: amount, currency: currency, detail: detail, date: date, type: type)
            modelContext.insert(newTransaction)
        }
    }

    private func deleteTransactions(offsets: IndexSet, from transactions: [Transaction]) {
        withAnimation {
            for index in offsets {
                modelContext.delete(transactions[index])
            }
        }
    }
    
    // MARK: - Styled Views
    func headerView(title: String, amount: Double, color: Color, currency: String? = nil) -> some View {
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
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(transactions) { transaction in
                    HStack(alignment: .center, spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(accentColor(for: selectedTab == .all ? (transaction.type == .income ? .income : .spending) : selectedTab).opacity(0.18))
                                .frame(width: 44, height: 44)
                            Image(systemName: icon(for: transaction.type))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                                .foregroundColor(accentColor(for: selectedTab == .all ? (transaction.type == .income ? .income : .spending) : selectedTab))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(transaction.category)
                                .font(.headline)
                            HStack(spacing: 6) {
                                Text(transaction.type.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(accentColor(for: selectedTab == .all ? (transaction.type == .income ? .income : .spending) : selectedTab))
                                if !transaction.detail.isEmpty {
                                    Text("· ") + Text(transaction.detail).font(.caption)
                                }
                            }
                            Text(transaction.date, format: Date.FormatStyle(date: .numeric, time: .omitted))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(transaction.amount, specifier: "%.2f") \(transaction.currency)")
                                .bold()
                                .foregroundColor(accentColor(for: selectedTab == .all ? (transaction.type == .income ? .income : .spending) : selectedTab))
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    )
                }
                .onDelete { offsets in
                    deleteTransactions(offsets: offsets, from: transactions)
                }
            }
            .padding([.horizontal, .bottom])
        }
    }
} 