import Combine
import SwiftData
import SwiftUI

struct AssetsView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var assets: [Asset]

  @AppStorage("defaultCurrency") private var defaultCurrency: String = "USD"
  @State private var showingAddSheet = false
  @State private var convertedTotal: Double? = nil
  @State private var isLoadingTotal = false
  @State private var conversionCancellable: AnyCancellable? = nil
  @State private var editingAsset: Asset? = nil

  var totalByCurrency: [String: Double] {
    Dictionary(grouping: assets, by: { $0.currency })
      .mapValues { $0.reduce(0) { $0 + $1.amount } }
  }

  // Calculate the total in the user's preferred currency
  func calculateConvertedTotal() {
    isLoadingTotal = true
    let group = DispatchGroup()
    var sum: Double = 0
    var errorOccurred = false
    for asset in assets {
      group.enter()
      CurrencyExchange.shared.convert(
        amount: asset.amount,
        from: asset.currency,
        to: defaultCurrency
      ) { result in
        switch result {
        case .success(let converted):
          sum += converted
        case .failure(_):
          errorOccurred = true
        }
        group.leave()
      }
    }
    group.notify(queue: .main) {
      self.convertedTotal = errorOccurred ? nil : sum
      self.isLoadingTotal = false
    }
  }

  // Recalculate when assets or currency changes
  private func recalculateOnChange() {
    convertedTotal = nil
    calculateConvertedTotal()
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
    NavigationStack {
      VStack(alignment: .leading, spacing: 12) {
        Group {
          if isLoadingTotal {
            headerView(amount: 0, currency: defaultCurrency)
              .redacted(reason: .placeholder)
          } else if let total = convertedTotal {
            headerView(amount: total, currency: defaultCurrency)
          } else {
            headerView(
              amount: 0,
              currency: defaultCurrency,
              error: true
            )
          }
        }
        if !totalByCurrency.isEmpty {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
              ForEach(Array(totalByCurrency.keys), id: \.self) {
                currency in
                let total = totalByCurrency[currency] ?? 0
                HStack(spacing: 6) {
                  Text("Total")
                    .font(.caption)
                    .foregroundColor(.secondary)
                  Text("\(currency)")
                    .font(.headline)
                    .bold()
                  Text("\(total, specifier: "%.2f")")
                    .font(.headline)
                    .bold()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(
                  Capsule()
                    .fill(Color.blue.opacity(0.12))
                )
              }
            }
            .padding(.horizontal)
          }
        }
        assetList(assets: assets)
      }
      .toolbar {
        ToolbarItem {
          Button(action: { showingAddSheet = true }) {
            Label("Add Asset", systemImage: "plus")
          }
        }
      }
      .background(Color(.systemGroupedBackground))
      .onAppear(perform: recalculateOnChange)
      .onChange(of: assets) { recalculateOnChange() }
      .onChange(of: defaultCurrency) { recalculateOnChange() }
    }
    .sheet(isPresented: $showingAddSheet) {
      AddAssetView { name, amount, currency, type, detail in
        addAsset(
          name: name,
          amount: amount,
          currency: currency,
          type: type,
          detail: detail
        )
      }
    }
    .sheet(
      isPresented: Binding<Bool>(
        get: { editingAsset != nil },
        set: { if !$0 { editingAsset = nil } }
      )
    ) {
      if let asset = editingAsset {
        AddAssetView(
          editingAsset: asset
        ) { name, amount, currency, type, detail in
          editAsset(
            asset: asset,
            name: name,
            amount: amount,
            currency: currency,
            type: type,
            detail: detail
          )
        }
      }
    }
  }

  // Header view for converted total
  func headerView(amount: Double, currency: String, error: Bool = false)
    -> some View
  {
    HStack {
      Text(error ? "Could not convert all assets" : "Total Assets")
        .font(.title2)
        .bold()
      Spacer()
      Text("\(amount, specifier: "%.2f") \(currency)")
        .font(.title2)
        .bold()
        .foregroundColor(error ? .gray : .blue)
    }
    .padding()
    .background(Color.blue.opacity(0.1))
    .cornerRadius(12)
    .padding(.horizontal)
  }

  private func addAsset(
    name: String,
    amount: Double,
    currency: String,
    type: AssetType,
    detail: String?
  ) {
    withAnimation {
      let newAsset = Asset(
        name: name,
        amount: amount,
        currency: currency,
        type: type,
        detail: detail
      )
      modelContext.insert(newAsset)
    }
  }

  func icon(for type: AssetType) -> String {
    switch type {
    case .savings: return "banknote"
    case .crypto: return "bitcoinsign.circle"
    case .investment: return "chart.bar"
    case .other: return "archivebox"
    }
  }

  func assetList(assets: [Asset]) -> some View {
    List {
      ForEach(assets) { asset in
        HStack(alignment: .center, spacing: 16) {
          ZStack {
            Circle()
              .fill(
                accentColor(for: asset.type).opacity(0.18)
              )
              .frame(width: 44, height: 44)
            Image(systemName: icon(for: asset.type))
              .resizable()
              .scaledToFit()
              .frame(width: 26, height: 26)
              .foregroundColor(accentColor(for: asset.type))
          }
          VStack(alignment: .leading, spacing: 4) {
            Text(asset.name)
              .font(.headline)
            HStack(spacing: 6) {
              Text(asset.type.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(
                  accentColor(for: asset.type)
                )
              if let detail = asset.detail, !detail.isEmpty {
                Text("· ") + Text(detail).font(.caption)
              }
            }
          }
          Spacer()
          VStack(alignment: .trailing, spacing: 2) {
            Text(
              "\(asset.amount, specifier: "%.2f") \(asset.currency)"
            )
            .bold()
            .foregroundColor(accentColor(for: asset.type))
          }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
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
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
          Button("Delete", role: .destructive) {
            withAnimation {
              modelContext.delete(asset)
            }
          }
          Button("Edit") {
            editingAsset = asset
          }
          .tint(.blue)
        }
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(Color(.systemGroupedBackground))
  }

  private func editAsset(
    asset: Asset,
    name: String,
    amount: Double,
    currency: String,
    type: AssetType,
    detail: String?
  ) {
    withAnimation {
      asset.name = name
      asset.amount = amount
      asset.currency = currency
      asset.type = type
      asset.detail = detail
    }
  }
}
