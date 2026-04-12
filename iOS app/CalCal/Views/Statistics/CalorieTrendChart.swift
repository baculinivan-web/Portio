import SwiftUI
import Charts

struct CalorieTrendChart: View {
    let data: [NutritionStats]
    let timeframe: TimeFrame
    let calorieGoal: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Calories")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
            }
            
            Chart(data) { stats in
                // Goal Line
                RuleMark(y: .value("Goal", calorieGoal))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(.orange.opacity(0.5))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                
                // Trend Line
                LineMark(
                    x: .value("Date", stats.date, unit: timeframe == .year ? .month : .day),
                    y: .value("Calories", stats.calories)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.orange.gradient)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                // Gradient Area
                AreaMark(
                    x: .value("Date", stats.date, unit: timeframe == .year ? .month : .day),
                    y: .value("Calories", stats.calories)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.2), Color.orange.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
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
