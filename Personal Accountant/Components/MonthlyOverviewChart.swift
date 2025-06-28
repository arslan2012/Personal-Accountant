import Charts
import SwiftUI

struct MonthlyOverviewChart: View {
  let data: [(month: String, income: Double, spending: Double)]
  @Binding var selectedTimeframe: TimeFrame

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Monthly Overview")
          .font(.headline)
          .bold()
        Spacer()
        Picker("Timeframe", selection: $selectedTimeframe) {
          ForEach(TimeFrame.allCases, id: \.self) { timeframe in
            Text(timeframe.rawValue).tag(timeframe)
          }
        }
        .pickerStyle(.segmented)
        .frame(width: 120)
      }

      if !data.isEmpty {
        Chart {
          ForEach(data, id: \.month) { data in
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
              if let doubleValue = value.as(Double.self) {
                Text("\(abs(doubleValue), specifier: "%.0f")")
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
          description: Text("Add some transactions to see monthly trends")
        )
        .frame(height: 200)
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
  }
}
