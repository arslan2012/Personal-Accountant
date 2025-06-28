import SwiftUI

struct HeaderView: View {
  let title: String
  let amount: Double
  let color: Color
  let currency: String?
  let isError: Bool

  init(title: String, amount: Double, color: Color, currency: String? = nil, isError: Bool = false)
  {
    self.title = title
    self.amount = amount
    self.color = color
    self.currency = currency
    self.isError = isError
  }

  var body: some View {
    HStack {
      Text(title)
        .font(.title2)
        .bold()
      Spacer()
      if let currency = currency {
        Text("\(amount, specifier: "%.2f") \(currency)")
          .font(.title2)
          .bold()
          .foregroundColor(isError ? .gray : color)
      } else {
        Text("$\(amount, specifier: "%.2f")")
          .font(.title2)
          .bold()
          .foregroundColor(isError ? .gray : color)
      }
    }
    .padding()
    .background(color.opacity(0.1))
    .cornerRadius(12)
    .padding(.horizontal)
  }
}

struct HeaderViewWithDatePicker: View {
  let title: String
  let amount: Double
  let color: Color
  let currency: String?
  @Binding var selectedMonth: Date

  init(
    title: String, amount: Double, color: Color, currency: String? = nil,
    selectedMonth: Binding<Date>
  ) {
    self.title = title
    self.amount = amount
    self.color = color
    self.currency = currency
    self._selectedMonth = selectedMonth
  }

  var body: some View {
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
}
