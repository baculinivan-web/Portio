import WidgetKit
import SwiftUI
import SwiftData

struct NutrientProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), calories: 1200, calorieGoal: 2000, protein: 80, proteinGoal: 150, carbs: 150, carbsGoal: 250, fat: 45, fatGoal: 70)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), calories: 1200, calorieGoal: 2000, protein: 80, proteinGoal: 150, carbs: 150, carbsGoal: 250, fat: 45, fatGoal: 70)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
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

enum NutrientType: String {
    case calories, protein, carbs, fats
    
    var title: String {
        switch self {
        case .calories: return "Calories"
        case .protein: return "Protein"
        case .carbs: return "Carbs"
        case .fats: return "Fats"
        }
    }
    
    var symbol: String {
        switch self {
        case .calories: return "flame.fill"
        case .protein: return "bolt.fill"
        case .carbs: return "leaf.fill"
        case .fats: return "drop.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .calories: return .orange
        case .protein: return .red
        case .carbs: return .blue
        case .fats: return .green
        }
    }
    
    var unit: String {
        switch self {
        case .calories: return "kcal"
        default: return "g"
        }
    }
}

struct NutrientBaseView: View {
    let type: NutrientType
    let value: Double
    let goal: Double
    
    var remaining: Double {
        max(goal - value, 0)
    }
    
    var over: Double {
        max(value - goal, 0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TODAY")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
            
            Text(type.title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.top, 4)
            
            if over > 0 {
                Text("\(Int(over))\(type.unit) over")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.red)
            } else {
                Text("\(Int(remaining))\(type.unit) left")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(type.color)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                NutrientGaugeView(value: value, goal: goal, symbol: type.symbol, color: type.color)
            }
        }
        .padding(12)
    }
}

struct NutrientGaugeView: View {
    let value: Double
    let goal: Double
    let symbol: String
    let color: Color
    
    var body: some View {
        ZStack {
            // Background outer ring (subtle)
            Circle()
                .stroke(color.opacity(0.1), lineWidth: 4)
            
            // The gauge arc (matching image style)
            Circle()
                .trim(from: 0, to: min(value / max(goal, 1), 1.0) * 0.75) // 75% arc
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(135))
            
            // Inner circle for symbol background
            Circle()
                .fill(Color(uiColor: .systemBackground).opacity(0.1))
                .padding(4)
            
            // The icon
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(width: 44, height: 44)
    }
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
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(8) // Inner padding to prevent touching the ring
        }
    }
}

struct QuickActionButtonsView: View {
    var body: some View {
        HStack(spacing: 8) {
            Link(destination: URL(string: "calcal://add")!) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.orange.opacity(0.8))
                    .clipShape(Circle())
            }
            
            Link(destination: URL(string: "calcal://camera")!) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.orange.opacity(0.8))
                    .clipShape(Circle())
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
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(Int(value))g")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.gradient)
                        .frame(width: geometry.size.width * min(value / max(goal, 1), 1.0), height: 6)
                }
            }
            .frame(height: 6)
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
        .overlay {
            // Subtle glass border
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.15), lineWidth: 0.5)
                .padding(-1) // Ensure it's at the very edge
        }
    }
}

struct SmallWidgetView: View {
    var entry: SimpleEntry
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Today")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            Spacer()
            
            CalorieRingView(calories: entry.calories, goal: entry.calorieGoal)
                .padding(.vertical, 4)
            
            Spacer()
            
            Text("\(Int(entry.calorieGoal)) kcal goal")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(4)
    }
}

struct MediumWidgetView: View {
    var entry: SimpleEntry
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Today")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(.orange)
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int(entry.calories))")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                    Text("kcal")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(.secondary)
                }
                
                Text("of \(Int(entry.calorieGoal)) goal")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.top, -2)
                
                Spacer()
                
                QuickActionButtonsView()
            }
            .padding(.vertical, 4)

            Spacer(minLength: 20)
            
            VStack(alignment: .leading, spacing: 10) {
                MacroMiniView(label: "Protein", value: entry.protein, goal: entry.proteinGoal, color: .orange)
                MacroMiniView(label: "Carbs", value: entry.carbs, goal: entry.carbsGoal, color: .blue)
                MacroMiniView(label: "Fat", value: entry.fat, goal: entry.fatGoal, color: .green)
            }
            .frame(width: 130) // Increased width to fill the right side better
        }
        .padding(.horizontal, 8)
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

// MARK: - Individual Nutrient Widgets

struct CalorieWidget: Widget {
    let kind: String = "CalorieWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NutrientProvider()) { entry in
            NutrientBaseView(type: .calories, value: entry.calories, goal: entry.calorieGoal)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Calories")
        .description("Track your daily calorie intake.")
        .supportedFamilies([.systemSmall])
    }
}

struct ProteinWidget: Widget {
    let kind: String = "ProteinWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NutrientProvider()) { entry in
            NutrientBaseView(type: .protein, value: entry.protein, goal: entry.proteinGoal)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Protein")
        .description("Track your daily protein intake.")
        .supportedFamilies([.systemSmall])
    }
}

struct CarbsWidget: Widget {
    let kind: String = "CarbsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NutrientProvider()) { entry in
            NutrientBaseView(type: .carbs, value: entry.carbs, goal: entry.carbsGoal)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Carbs")
        .description("Track your daily carbs intake.")
        .supportedFamilies([.systemSmall])
    }
}

struct FatWidget: Widget {
    let kind: String = "FatWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NutrientProvider()) { entry in
            NutrientBaseView(type: .fats, value: entry.fat, goal: entry.fatGoal)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Fats")
        .description("Track your daily fats intake.")
        .supportedFamilies([.systemSmall])
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