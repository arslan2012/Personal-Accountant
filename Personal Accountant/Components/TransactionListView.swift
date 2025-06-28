import SwiftUI

struct TransactionListView: View {
  let transactions: [Transaction]
  let selectedTab: TransactionTab
  let accentColor: (TransactionTab) -> Color
  let icon: (TransactionType) -> String
  let onDelete: (Transaction) -> Void
  let onEdit: (Transaction) -> Void

  var body: some View {
    if transactions.isEmpty {
      VStack(spacing: 16) {
        Image(systemName: "tray")
          .font(.system(size: 48))
          .foregroundColor(.gray)
        Text("No transactions for this month")
          .font(.headline)
          .foregroundColor(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(.systemGroupedBackground))
    } else {
      List {
        ForEach(transactions) { transaction in
          HStack(alignment: .center, spacing: 16) {
            ZStack {
              Circle()
                .fill(
                  accentColor(
                    selectedTab == .all
                      ? (transaction.type
                        == .income
                        ? .income : .spending)
                      : selectedTab
                  ).opacity(0.18)
                )
                .frame(width: 44, height: 44)
              Image(systemName: icon(transaction.type))
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
                .foregroundColor(
                  accentColor(
                    selectedTab == .all
                      ? (transaction.type
                        == .income
                        ? .income : .spending)
                      : selectedTab
                  )
                )
            }
            VStack(alignment: .leading, spacing: 4) {
              Text(transaction.category)
                .font(.headline)
              Text(
                transaction.type.rawValue
                  .capitalized
              )
              .font(.caption)
              .foregroundColor(
                accentColor(
                  selectedTab == .all
                    ? (transaction.type
                      == .income
                      ? .income : .spending)
                    : selectedTab
                )
              )
              if !transaction.detail.isEmpty {
                Text("· ")
                  + Text(transaction.detail).font(
                    .caption
                  )
              }
              Text(
                transaction.date,
                format: Date.FormatStyle(
                  date: .numeric,
                  time: .omitted
                )
              )
              .font(.caption2)
              .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
              Text(
                "\(transaction.amount, specifier: "%.2f") \(transaction.currency)"
              )
              .bold()
              .foregroundColor(
                accentColor(
                  selectedTab == .all
                    ? (transaction.type == .income
                      ? .income : .spending)
                    : selectedTab
                )
              )
            }
          }
          .padding(.vertical, 10)
          .padding(.horizontal, 14)
          .background(
            RoundedRectangle(
              cornerRadius: 16,
              style: .continuous
            )
            .fill(Color(.secondarySystemGroupedBackground))
            .shadow(
              color: Color.black.opacity(0.04),
              radius: 4,
              x: 0,
              y: 2
            )
          )
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
          .swipeActions(
            edge: .trailing,
            allowsFullSwipe: false
          ) {
            Button("Delete", role: .destructive) {
              onDelete(transaction)
            }
            Button("Edit") {
              onEdit(transaction)
            }
            .tint(.blue)
          }
        }
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .background(Color(.systemGroupedBackground))
    }
  }
}
