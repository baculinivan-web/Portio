import SwiftUI
import Charts

struct MacroDistributionChart: View {
    let data: [NutritionStats]
    let timeframe: TimeFrame
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Macro Distribution")
                .font(.headline)
                .padding(.bottom, 8)
            
            Chart(data) { stats in
                BarMark(
                    x: .value("Date", stats.date, unit: timeframe == .year ? .month : .day),
                    y: .value("Grams", stats.protein)
                )
                .foregroundStyle(.purple)
                .foregroundStyle(by: .value("Macro", "Protein"))
                
                BarMark(
                    x: .value("Date", stats.date, unit: timeframe == .year ? .month : .day),
                    y: .value("Grams", stats.carbs)
                )
                .foregroundStyle(.blue)
                .foregroundStyle(by: .value("Macro", "Carbs"))
                
                BarMark(
                    x: .value("Date", stats.date, unit: timeframe == .year ? .month : .day),
                    y: .value("Grams", stats.fat)
                )
                .foregroundStyle(.green)
                .foregroundStyle(by: .value("Macro", "Fat"))
            }
            .chartForegroundStyleScale([
                "Protein": Color.purple,
                "Carbs": Color.blue,
                "Fat": Color.green
            ])
            .chartXAxis {
                AxisMarks(values: .stride(by: timeframe == .year ? .month : .day)) { value in
                    if timeframe == .year {
                        AxisValueLabel(format: .dateTime.month(.narrow))
                    } else {
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
}
