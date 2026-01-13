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
        let currentDate = Date()
        
        Task { @MainActor in
            let stats = SharedDataManager.shared.fetchTodaysStats()
            
            let entry = SimpleEntry(
                date: currentDate,
                calories: stats.calories,
                calorieGoal: UserSettings.calorieGoal,
                protein: stats.protein,
                proteinGoal: UserSettings.proteinGoal,
                carbs: stats.carbs,
                carbsGoal: UserSettings.carbsGoal,
                fat: stats.fat,
                fatGoal: UserSettings.fatGoal
            )
            
            let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
            completion(timeline)
        }
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

struct CalorieRingView: View {
    let calories: Double
    let goal: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.orange.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: min(calories / max(goal, 1), 1.0))
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: -2) {
                Text("\(Int(calories))")
                    .font(.system(.title3, design: .rounded).bold())
                Text("kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
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
        }
    }
}

struct CalCalWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if family == .systemSmall {
                SmallWidgetView(entry: entry)
            } else {
                MediumWidgetView(entry: entry)
            }
        }
        .containerBackground(.thinMaterial, for: .widget)
    }
}

struct SmallWidgetView: View {
    var entry: SimpleEntry
    
    var body: some View {
        VStack {
            HStack {
                Text("CalCal")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                Spacer()
            }
            
            Spacer()
            
            CalorieRingView(calories: entry.calories, goal: entry.calorieGoal)
                .padding(4)
            
            Spacer()
            
            Text("/ \(Int(entry.calorieGoal))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
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
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(entry.calories))")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("kcal")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                
                Text("of \(Int(entry.calorieGoal)) goal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
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
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                MacroMiniView(label: "Protein", value: entry.protein, goal: entry.proteinGoal, color: .red)
                MacroMiniView(label: "Carbs", value: entry.carbs, goal: entry.carbsGoal, color: .blue)
                MacroMiniView(label: "Fat", value: entry.fat, goal: entry.fatGoal, color: .green)
            }
            .frame(width: 90)
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

struct CalCalWidget_Previews: PreviewProvider {
    static var previews: some View {
        CalCalWidgetEntryView(entry: SimpleEntry(date: Date(), calories: 1200, calorieGoal: 2000, protein: 80, proteinGoal: 150, carbs: 150, carbsGoal: 250, fat: 45, fatGoal: 70))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        CalCalWidgetEntryView(entry: SimpleEntry(date: Date(), calories: 1200, calorieGoal: 2000, protein: 80, proteinGoal: 150, carbs: 150, carbsGoal: 250, fat: 45, fatGoal: 70))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}