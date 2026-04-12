import Foundation

enum TimeRange: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case sixMonths = "6M"
    var id: Self { self }
}

struct DailyCalories: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
}

enum StatsTab: String, CaseIterable, Identifiable {
    case today = "Today"
    case allTime = "All Time"
    var id: Self { self }
}
