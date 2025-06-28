import Charts
import SwiftUI

struct PieChartView<DataType: Identifiable>: View {
  let title: String
  let data: [DataType]
  let emptyStateTitle: String
  let emptyStateIcon: String
  let emptyStateDescription: String
  let valueKeyPath: KeyPath<DataType, Double>
  let colorKeyPath: KeyPath<DataType, Color>
  let labelKeyPath: KeyPath<DataType, String>
  let showPercentages: Bool
  let innerRadius: Double

  init(
    title: String,
    data: [DataType],
    emptyStateTitle: String,
    emptyStateIcon: String,
    emptyStateDescription: String,
    valueKeyPath: KeyPath<DataType, Double>,
    colorKeyPath: KeyPath<DataType, Color>,
    labelKeyPath: KeyPath<DataType, String>,
    showPercentages: Bool = false,
    innerRadius: Double = 0.4
  ) {
    self.title = title
    self.data = data
    self.emptyStateTitle = emptyStateTitle
    self.emptyStateIcon = emptyStateIcon
    self.emptyStateDescription = emptyStateDescription
    self.valueKeyPath = valueKeyPath
    self.colorKeyPath = colorKeyPath
    self.labelKeyPath = labelKeyPath
    self.showPercentages = showPercentages
    self.innerRadius = innerRadius
  }

  private var totalValue: Double {
    data.reduce(0) { $0 + $1[keyPath: valueKeyPath] }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.headline)
        .bold()

      if !data.isEmpty {
        Chart(data) { item in
          SectorMark(
            angle: .value("Amount", item[keyPath: valueKeyPath]),
            innerRadius: .ratio(innerRadius),
            angularInset: 2
          )
          .foregroundStyle(item[keyPath: colorKeyPath])
          .opacity(0.8)
        }
        .frame(height: 200)

        // Legend
        LazyVGrid(
          columns: Array(repeating: GridItem(.flexible()), count: 2),
          spacing: 8
        ) {
          ForEach(data) { item in
            if showPercentages {
              VStack(alignment: .leading, spacing: 4) {
                HStack {
                  Circle()
                    .fill(item[keyPath: colorKeyPath])
                    .frame(width: 12, height: 12)
                  Text(item[keyPath: labelKeyPath])
                    .font(.caption)
                    .bold()
                  Spacer()
                }
                HStack {
                  let percentage =
                    totalValue > 0 ? (item[keyPath: valueKeyPath] / totalValue) * 100 : 0
                  Text("\(percentage, specifier: "%.1f")%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                  Spacer()
                  Text("\(item[keyPath: valueKeyPath], specifier: "%.0f")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
              }
            } else {
              HStack {
                Circle()
                  .fill(item[keyPath: colorKeyPath])
                  .frame(width: 12, height: 12)
                Text(item[keyPath: labelKeyPath])
                  .font(.caption)
                  .lineLimit(1)
                Spacer()
                Text("\(item[keyPath: valueKeyPath], specifier: "%.0f")")
                  .font(.caption)
                  .bold()
              }
            }
          }
        }
      } else {
        ContentUnavailableView(
          emptyStateTitle,
          systemImage: emptyStateIcon,
          description: Text(emptyStateDescription)
        )
        .frame(height: 200)
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
  }
}
