import SwiftUI
import Charts

struct CalorieTrendChart: View {
    let data: [NutritionStats]
    let timeframe: TimeFrame
    let calorieGoal: Double
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Calorie Trend")
                .font(.headline)
                .padding(.bottom, 8)
            
            Chart(data) { stats in
                // Goal Line
                RuleMark(y: .value("Goal", calorieGoal))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(.secondary)
                
                // Trend Line
                LineMark(
                    x: .value("Date", stats.date, unit: timeframe == .year ? .month : .day),
                    y: .value("Calories", stats.calories)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.orange.gradient)
                .symbol(by: .value("Date", stats.date))
                
                // Gradient Area
                AreaMark(
                    x: .value("Date", stats.date, unit: timeframe == .year ? .month : .day),
                    y: .value("Calories", stats.calories)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
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
