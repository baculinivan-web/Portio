import SwiftUI
import SwiftData

struct ContributionGridView: View {
    let month: Int
    let year: Int
    let dailyStats: [Date: NutritionStats]
    var onDateSelected: (Date) -> Void
    
    private var calendar: Calendar { Calendar.current }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = calendar.date(from: DateComponents(year: year, month: month)) ?? Date()
        return formatter.string(from: date).uppercased()
    }
    
    private var daysInMonth: [Date?] {
        guard let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        // Convert to 0-indexed (Monday = 0)
        let offset = (firstWeekday + 5) % 7
        
        var days: [Date?] = Array(repeating: nil, count: offset)
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)
    private let weekdays = ["M", "T", "W", "T", "F", "S", "S"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Month/Year Header
            VStack(alignment: .leading, spacing: 4) {
                Text(monthName)
                    .font(.system(size: 44, weight: .black, design: .default))
                Text("\(String(year))")
                    .font(.system(size: 44, weight: .light, design: .default))
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 32)
            
            // Weekday Labels
            HStack {
                ForEach(0..<7) { index in
                    Text(weekdays[index])
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(index == 1 ? .orange : .secondary.opacity(0.4)) // Orange for 'T' as per reference if desired, or just secondary
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24)
            
            // Grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<daysInMonth.count, id: \.self) { index in
                    if let date = daysInMonth[index] {
                        ContributionDot(
                            date: date,
                            stats: dailyStats[calendar.startOfDay(for: date)],
                            action: { onDateSelected(date) }
                        )
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 40, height: 40)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .padding(.top, 100)
    }
}

struct ContributionDot: View {
    let date: Date
    let stats: NutritionStats?
    let action: () -> Void
    
    @AppStorage("calorieGoal", store: UserSettings.shared) private var calorieGoal: Double = UserSettings.calorieGoal
    @AppStorage("weightGoalMode", store: UserSettings.shared) private var weightGoalModeRaw: String = UserSettings.weightGoalMode.rawValue
    
    private var weightGoalMode: UserSettings.WeightGoalMode {
        UserSettings.WeightGoalMode(rawValue: weightGoalModeRaw) ?? .maintain
    }
    
    private var color: Color {
        guard let stats = stats, stats.calories > 0 else {
            return Color.black.opacity(0.1)
        }
        
        let calories = stats.calories
        
        switch weightGoalMode {
        case .lose:
            if calories <= calorieGoal {
                return .orange
            } else {
                return .orange.opacity(0.4)
            }
        case .gain:
            if calories >= calorieGoal {
                return .orange
            } else {
                return .orange.opacity(0.4)
            }
        case .maintain:
            let lowerBound = calorieGoal * 0.9
            let upperBound = calorieGoal * 1.1
            if calories >= lowerBound && calories <= upperBound {
                return .orange
            } else {
                return .orange.opacity(0.4)
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContributionGridView(month: 2, year: 2025, dailyStats: [:]) { _ in }
}
