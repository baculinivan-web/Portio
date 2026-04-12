import Foundation
import SwiftData

class NutritionAggregator {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Aggregation
    
    func aggregateStats(for timeframe: TimeFrame) throws -> [NutritionStats] {
        let calendar = Calendar.current
        let now = Date()
        
        var stats: [NutritionStats] = []
        
        switch timeframe {
        case .week:
            // Get stats for the last 7 days
            for i in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
                let startOfDay = calendar.startOfDay(for: date)
                guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }
                
                let dayStats = try fetchStats(start: startOfDay, end: endOfDay)
                stats.append(dayStats)
            }
        case .month:
            // Get stats for the last 30 days
            for i in 0..<30 {
                guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
                let startOfDay = calendar.startOfDay(for: date)
                guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }
                
                let dayStats = try fetchStats(start: startOfDay, end: endOfDay)
                stats.append(dayStats)
            }
        case .year:
             // Get stats for the last 12 months
            for i in 0..<12 {
                guard let date = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
                guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else { continue }
                guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { continue }
                
                let monthStats = try fetchStats(start: startOfMonth, end: endOfMonth)
                stats.append(monthStats)
            }
        }
        
        return stats.reversed() // Oldest to newest
    }

    func fetchDailyStats(for date: Date) throws -> NutritionStats {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw NSError(domain: "NutritionAggregator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid date"])
        }
        return try fetchStats(start: startOfDay, end: endOfDay)
    }

    func fetchMonthlyStats(month: Int, year: Int) throws -> [NutritionStats] {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        guard let startOfMonth = calendar.date(from: components) else {
            return []
        }
        
        guard let monthRange = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }
        
        var stats: [NutritionStats] = []
        for day in monthRange {
            var dayComponents = components
            dayComponents.day = day
            guard let date = calendar.date(from: dayComponents) else { continue }
            stats.append(try fetchDailyStats(for: date))
        }
        return stats
    }
    
    func fetchStats(start: Date, end: Date) throws -> NutritionStats {
        let predicate = #Predicate<FoodItem> { item in
            item.dateEaten >= start && item.dateEaten < end
        }
        
        let descriptor = FetchDescriptor<FoodItem>(predicate: predicate)
        let items = try modelContext.fetch(descriptor)
        
        var totalCalories: Double = 0
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFat: Double = 0
        
        for item in items {
            totalCalories += item.calories
            totalProtein += item.protein
            totalCarbs += item.carbs
            totalFat += item.fat
        }
        
        return NutritionStats(
            date: start,
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat
        )
    }
}

enum TimeFrame: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    var id: String { self.rawValue }
}

public struct NutritionStats: Identifiable {
    public let id = UUID()
    public let date: Date
    public let calories: Double
    public let protein: Double
    public let carbs: Double
    public let fat: Double
    
    public init(date: Date, calories: Double, protein: Double, carbs: Double, fat: Double) {
        self.date = date
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}
