import SwiftUI

struct MonthPicker: View {
  @Binding var selectedMonth: Date
  @State private var showingPicker = false
  @State private var tempMonthIndex = 0
  @State private var tempYear = 2024

  private let months = Calendar.current.monthSymbols
  private let currentYear = Calendar.current.component(.year, from: Date())
  private let years = Array((2020...2030))

  private var selectedMonthIndex: Int {
    Calendar.current.component(.month, from: selectedMonth) - 1
  }

  private var selectedYear: Int {
    Calendar.current.component(.year, from: selectedMonth)
  }

  private var displayText: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    return formatter.string(from: selectedMonth)
  }

  var body: some View {
    Button(action: {
      // Initialize temporary values with current selection
      tempMonthIndex = selectedMonthIndex
      tempYear = selectedYear
      showingPicker.toggle()
    }) {
      HStack {
        Image(systemName: "calendar")
          .foregroundColor(.blue)
        Text(displayText)
          .foregroundColor(.primary)
        Image(systemName: "chevron.down")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color(.systemGray6))
      .cornerRadius(8)
    }
    .frame(maxWidth: 200)
    .sheet(isPresented: $showingPicker) {
      NavigationView {
        HStack {
          Picker("Month", selection: $tempMonthIndex) {
            ForEach(0..<months.count, id: \.self) { index in
              Text(months[index]).tag(index)
            }
          }
          .pickerStyle(.wheel)

          Picker("Year", selection: $tempYear) {
            ForEach(years, id: \.self) { year in
              Text(String(year)).tag(year)
            }
          }
          .pickerStyle(.wheel)
        }
        .navigationTitle("Select Month")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done") {
              // Apply the temporary selection to the binding
              updateDate(
                month: tempMonthIndex + 1,
                year: tempYear
              )
              showingPicker = false
            }
          }
          ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
              // Dismiss without applying changes
              showingPicker = false
            }
          }
        }
      }
      .presentationDetents([.height(300)])
    }
  }

  private func updateDate(month: Int, year: Int) {
    let components = DateComponents(year: year, month: month, day: 1)
    if let newDate = Calendar.current.date(from: components) {
      selectedMonth = newDate
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var selectedMonth = Date()

    var body: some View {
      VStack {
        MonthPicker(selectedMonth: $selectedMonth)
        Text(
          "Selected: \(selectedMonth, formatter: DateFormatter.monthYear)"
        )
      }
      .padding()
    }
  }

  return PreviewWrapper()
}

extension DateFormatter {
  static let monthYear: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    return formatter
  }()
}
