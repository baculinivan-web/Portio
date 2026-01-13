import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), calories: 1200, calorieGoal: 2000, protein: 80, proteinGoal: 150, carbs: 150, carbsGoal: 250, fat: 45, fatGoal: 70)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), calories: 1200, calorieGoal: 2000, protein: 80, proteinGoal: 150, carbs: 150, carbsGoal: 250, fat: 45, fatGoal: 70)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        // Fetch real data from SwiftData
        let entry = fetchLatestData(for: currentDate)
        entries.append(entry)

        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdateDate))
        completion(timeline)
    }
    
    @MainActor
    private func fetchLatestData(for date: Date) -> SimpleEntry {
        let stats = SharedDataManager.shared.fetchTodaysStats()
        
        return SimpleEntry(
            date: date,
            calories: stats.calories,
            calorieGoal: UserSettings.calorieGoal,
            protein: stats.protein,
            proteinGoal: UserSettings.proteinGoal,
            carbs: stats.carbs,
            carbsGoal: UserSettings.carbsGoal,
            fat: stats.fat,
            fatGoal: UserSettings.fatGoal
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let calories: Double
    let calorieGoal: Double
    let protein: Double
    let proteinGoal: Double
    let carbs: Double
    let carbsGoal: Double
    let fat: Double
    let fatGoal: Double
}

struct CalCalWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if family == .systemSmall {
                SmallWidgetView(entry: entry)
            } else {
                MediumWidgetView(entry: entry)
            }
        }
        .containerBackground(.thinMaterial, for: .widget)
    }
}

struct CalorieProgressView: View {
    let calories: Double
    let goal: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Calories")
                .font(.caption.bold())
                .foregroundStyle(.orange)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(calories))")
                    .font(.title2.bold())
                Text("/ \(Int(goal))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: min(calories / max(goal, 1), 1.0))
                .tint(.orange)
        }
    }
}

struct SmallWidgetView: View {
    var entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading) {
            CalorieProgressView(calories: entry.calories, goal: entry.calorieGoal)
            Spacer()
        }
    }
}

struct QuickActionButtonsView: View {
    var body: some View {
        HStack(spacing: 12) {
            Link(destination: URL(string: "calcal://add")!) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }
            
            Link(destination: URL(string: "calcal://camera")!) {
                Image(systemName: "camera.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }
        }
    }
}

struct MacroBreakdownView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MacroMiniView(label: "P", value: entry.protein, goal: entry.proteinGoal, color: .red)
            MacroMiniView(label: "C", value: entry.carbs, goal: entry.carbsGoal, color: .blue)
            MacroMiniView(label: "F", value: entry.fat, goal: entry.fatGoal, color: .green)
        }
        .frame(width: 80)
    }
}

struct MediumWidgetView: View {
    var entry: SimpleEntry
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Today")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                
                Text("\(Int(entry.calories))")
                    .font(.system(size: 34, weight: .bold))
                
                Text("kcal of \(Int(entry.calorieGoal))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                QuickActionButtonsView()
            }
            
            Spacer()
            
            MacroBreakdownView(entry: entry)
        }
    }
}

struct MacroMiniView: View {
    let label: String
    let value: Double
    let goal: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.caption2.bold())
                Spacer()
                Text("\(Int(value))g")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: min(value / max(goal, 1), 1.0))
                .tint(color)
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
        }
    }
}

struct CalCalWidget: Widget {
    let kind: String = "CalCalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CalCalWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("CalCal Daily")
        .description("Track your daily calories and macros.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    CalCalWidget()
} content: {
    CalCalWidgetEntryView(entry: SimpleEntry(date: Date(), calories: 1200, calorieGoal: 2000, protein: 80, proteinGoal: 150, carbs: 150, carbsGoal: 250, fat: 45, fatGoal: 70))
}
