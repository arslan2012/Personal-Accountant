import Charts
import SwiftData
import SwiftUI

struct ChartsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var assets: [Asset]

    @AppStorage("defaultCurrency") private var defaultCurrency: String = "USD"
    @State private var selectedTimeframe: TimeFrame = .sixMonths

    enum TimeFrame: String, CaseIterable {
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"

        var months: Int {
            switch self {
            case .threeMonths: return 3
            case .sixMonths: return 6
            case .oneYear: return 12
            }
        }

        var label: String {
            switch self {
            case .threeMonths: return "3 Months"
            case .sixMonths: return "6 Months"
            case .oneYear: return "1 Year"
            }
        }
    }

    var filteredTransactionsByMonth:
        [(month: String, income: Double, spending: Double)]
    {
        let calendar = Calendar.current
        let now = Date()
        let cutoffDate =
            calendar.date(
                byAdding: .month,
                value: -selectedTimeframe.months,
                to: now
            ) ?? now

        let filtered = transactions.filter { $0.date >= cutoffDate }
        let grouped = Dictionary(grouping: filtered) { transaction in
            let components = calendar.dateComponents(
                [.year, .month],
                from: transaction.date
            )
            return
                "\(components.year!)-\(String(format: "%02d", components.month!))"
        }

        return grouped.compactMap { (key, transactions) in
            let income = transactions.filter { $0.type == .income }.reduce(0) {
                $0 + $1.amount
            }
            let spending = transactions.filter { $0.type == .spending }.reduce(
                0
            ) { $0 + $1.amount }

            // Convert month key to readable format
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            if let date = formatter.date(from: key) {
                formatter.dateFormat = "MMM yyyy"
                let monthName = formatter.string(from: date)
                return (month: monthName, income: income, spending: spending)
            }
            return nil
        }.sorted { $0.month < $1.month }
    }

    var spendingByCategory: [(category: String, amount: Double, color: Color)] {
        let spendingTransactions = transactions.filter { $0.type == .spending }
        let grouped = Dictionary(
            grouping: spendingTransactions,
            by: { $0.category }
        )

        let colors: [Color] = [
            .red, .orange, .yellow, .green, .blue, .purple, .pink, .brown,
            .gray, .cyan,
        ]

        return grouped.enumerated().map { (index, item) in
            let (category, transactions) = item
            let total = transactions.reduce(0) { $0 + $1.amount }
            let color = colors[index % colors.count]
            return (category: category, amount: total, color: color)
        }.sorted { $0.amount > $1.amount }
    }

    var assetsByType:
        [(type: String, amount: Double, percentage: Double, color: Color)]
    {
        let grouped = Dictionary(grouping: assets, by: { $0.type })
        let totalAmount = assets.reduce(0) { $0 + $1.amount }

        return grouped.map { (type, assets) in
            let typeTotal = assets.reduce(0) { $0 + $1.amount }
            let percentage =
                totalAmount > 0 ? (typeTotal / totalAmount) * 100 : 0
            let color = accentColor(for: type)
            return (
                type: type.rawValue.capitalized, amount: typeTotal,
                percentage: percentage, color: color
            )
        }.sorted { $0.amount > $1.amount }
    }

    func accentColor(for type: AssetType) -> Color {
        switch type {
        case .savings: return .green
        case .crypto: return .orange
        case .investment: return .purple
        case .other: return .gray
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Monthly Income vs Spending Chart
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Monthly Overview")
                                .font(.headline)
                                .bold()
                            Spacer()
                            Picker("Timeframe", selection: $selectedTimeframe) {
                                ForEach(TimeFrame.allCases, id: \.self) {
                                    timeframe in
                                    Text(timeframe.rawValue).tag(timeframe)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 120)
                        }

                        if !filteredTransactionsByMonth.isEmpty {
                            Chart {
                                ForEach(
                                    filteredTransactionsByMonth,
                                    id: \.month
                                ) { data in
                                    BarMark(
                                        x: .value("Month", data.month),
                                        y: .value("Income", data.income)
                                    )
                                    .foregroundStyle(.green)
                                    .opacity(0.8)

                                    BarMark(
                                        x: .value("Month", data.month),
                                        y: .value("Spending", -data.spending)
                                    )
                                    .foregroundStyle(.red)
                                    .opacity(0.8)
                                }
                            }
                            .frame(height: 200)
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisValueLabel {
                                        if let doubleValue = value.as(
                                            Double.self
                                        ) {
                                            Text(
                                                "\(abs(doubleValue), specifier: "%.0f")"
                                            )
                                        }
                                    }
                                    AxisGridLine()
                                    AxisTick()
                                }
                            }
                            .chartLegend(position: .bottom) {
                                HStack {
                                    HStack {
                                        Rectangle()
                                            .fill(.green)
                                            .frame(width: 12, height: 12)
                                        Text("Income")
                                            .font(.caption)
                                    }
                                    HStack {
                                        Rectangle()
                                            .fill(.red)
                                            .frame(width: 12, height: 12)
                                        Text("Spending")
                                            .font(.caption)
                                    }
                                }
                            }
                        } else {
                            ContentUnavailableView(
                                "No Transaction Data",
                                systemImage: "chart.bar",
                                description: Text(
                                    "Add some transactions to see monthly trends"
                                )
                            )
                            .frame(height: 200)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                    // Spending by Category Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Spending by Category")
                            .font(.headline)
                            .bold()

                        if !spendingByCategory.isEmpty {
                            Chart(spendingByCategory, id: \.category) { data in
                                SectorMark(
                                    angle: .value("Amount", data.amount),
                                    innerRadius: .ratio(0.4),
                                    angularInset: 2
                                )
                                .foregroundStyle(data.color)
                                .opacity(0.8)
                            }
                            .frame(height: 200)

                            // Legend
                            LazyVGrid(
                                columns: Array(
                                    repeating: GridItem(.flexible()),
                                    count: 2
                                ),
                                spacing: 8
                            ) {
                                ForEach(spendingByCategory, id: \.category) {
                                    data in
                                    HStack {
                                        Circle()
                                            .fill(data.color)
                                            .frame(width: 12, height: 12)
                                        Text(data.category)
                                            .font(.caption)
                                            .lineLimit(1)
                                        Spacer()
                                        Text(
                                            "\(data.amount, specifier: "%.0f")"
                                        )
                                        .font(.caption)
                                        .bold()
                                    }
                                }
                            }
                        } else {
                            ContentUnavailableView(
                                "No Spending Data",
                                systemImage: "chart.pie",
                                description: Text(
                                    "Add some spending transactions to see category breakdown"
                                )
                            )
                            .frame(height: 200)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                    // Assets by Type Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Assets by Type")
                            .font(.headline)
                            .bold()

                        if !assetsByType.isEmpty {
                            Chart(assetsByType, id: \.type) { data in
                                SectorMark(
                                    angle: .value("Amount", data.amount),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 2
                                )
                                .foregroundStyle(data.color)
                                .opacity(0.8)
                            }
                            .frame(height: 200)

                            // Legend with percentages
                            LazyVGrid(
                                columns: Array(
                                    repeating: GridItem(.flexible()),
                                    count: 2
                                ),
                                spacing: 8
                            ) {
                                ForEach(assetsByType, id: \.type) { data in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Circle()
                                                .fill(data.color)
                                                .frame(width: 12, height: 12)
                                            Text(data.type)
                                                .font(.caption)
                                                .bold()
                                            Spacer()
                                        }
                                        HStack {
                                            Text(
                                                "\(data.percentage, specifier: "%.1f")%"
                                            )
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            Spacer()
                                            Text(
                                                "\(data.amount, specifier: "%.0f")"
                                            )
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        } else {
                            ContentUnavailableView(
                                "No Asset Data",
                                systemImage: "chart.pie.fill",
                                description: Text(
                                    "Add some assets to see type distribution"
                                )
                            )
                            .frame(height: 200)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Charts")
            .background(Color(.systemGroupedBackground))
        }
    }
}
