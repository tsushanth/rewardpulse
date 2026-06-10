import SwiftUI
import Charts

struct EarningsChartView: View {
    let data: [(Date, Int)]

    private var chartData: [(label: String, cents: Int)] {
        data.map { (date, cents) in
            let label = date.formatted(.dateTime.weekday(.abbreviated))
            return (label: label, cents: cents)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7-Day Earnings")
                .font(.headline)

            Chart {
                ForEach(chartData, id: \.label) { item in
                    BarMark(
                        x: .value("Day", item.label),
                        y: .value("Earnings", Double(item.cents) / 100.0)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .cornerRadius(4)
                }
            }
            .chartYAxis {
                AxisMarks(format: .currency(code: "USD"))
            }
            .frame(height: 180)
            .accessibilityLabel("7-day earnings bar chart")
            .accessibilityHint("Shows your earnings for the past 7 days")
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius))
    }
}
