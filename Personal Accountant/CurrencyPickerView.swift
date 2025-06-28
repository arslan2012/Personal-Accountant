import SwiftUI

struct CurrencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCurrency: String
    let supportedCurrencies: [String]
    @State private var searchText = ""
    
    var filteredCurrencies: [String] {
        if searchText.isEmpty {
            return supportedCurrencies
        } else {
            return supportedCurrencies.filter { currency in
                currency.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredCurrencies, id: \.self) { currency in
                    HStack {
                        Text(currency)
                        Spacer()
                        if currency == selectedCurrency {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCurrency = currency
                        dismiss()
                    }
                }
            }
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search currencies")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
} 