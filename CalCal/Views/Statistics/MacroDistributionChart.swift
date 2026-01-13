import SwiftUI
import Charts

struct MacroDistributionChart: View {
    let data: [NutritionStats]
    let timeframe: TimeFrame
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Macros Distribution")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
            }
            
            Chart(data) { stats in
                BarMark(
                    x: .value("Date", stats.date, unit: timeframe == .year ? .month : .day),
                    y: .value("Grams", stats.protein)
                )
                .foregroundStyle(by: .value("Macro", "Protein"))
                
                BarMark(
                    x: .value("Date", stats.date, unit: timeframe == .year ? .month : .day),
                    y: .value("Grams", stats.carbs)
                )
                .foregroundStyle(by: .value("Macro", "Carbs"))
                
                BarMark(
                    x: .value("Date", stats.date, unit: timeframe == .year ? .month : .day),
                    y: .value("Grams", stats.fat)
                )
                .foregroundStyle(by: .value("Macro", "Fat"))
            }
            .chartForegroundStyleScale([
                "Protein": Color.purple.gradient,
                "Carbs": Color.blue.gradient,
                "Fat": Color.green.gradient
            ])
            .chartXAxis {
                AxisMarks(values: .stride(by: timeframe == .year ? .month : .day)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.white.opacity(0.1))
                    if timeframe == .year {
                        AxisValueLabel(format: .dateTime.month(.narrow))
                    } else {
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.white.opacity(0.1))
                    AxisValueLabel()
                }
            }
            .frame(height: 220)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}
