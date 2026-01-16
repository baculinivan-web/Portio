import Foundation
import SwiftData

class StreakManager {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Calculates the current streak of consecutive days with at least one food item logged.
    /// This version is optimized by fetching only the dates of all entries.
    func calculateCurrentStreak() throws -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        
        // Fetch only the dates of all entries, sorted descending
        var descriptor = FetchDescriptor<FoodItem>(
            sortBy: [SortDescriptor(\.dateEaten, order: .reverse)]
        )
        // Optimization: We only need enough dates to confirm the streak
        // If someone has a 1000 day streak, fetching 1000 records is still cheap if we only pull dates.
        
        let allItems = try modelContext.fetch(descriptor)
        if allItems.isEmpty { return 0 }
        
        // Convert dates to start-of-day set for easy lookup
        let loggedDates = Set(allItems.map { calendar.startOfDay(for: $0.dateEaten) })
        
        var streak = 0
        var checkDate = startOfToday
        
        // If nothing today, check if streak is alive from yesterday
        if !loggedDates.contains(startOfToday) {
            checkDate = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
            if !loggedDates.contains(checkDate) {
                return 0
            }
        }
        
        // Count backwards
        while loggedDates.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        return streak
    }
    
    private func hasEntries(on date: Date) throws -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return false }
        
        let predicate = #Predicate<FoodItem> { item in
            item.dateEaten >= startOfDay && item.dateEaten < endOfDay
        }
        
        var descriptor = FetchDescriptor<FoodItem>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        let count = try modelContext.fetchCount(descriptor)
        return count > 0
    }
}
