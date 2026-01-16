import Foundation
import SwiftData

class StreakManager {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Calculates the current streak of consecutive days with at least one food item logged.
    /// A streak continues if there is at least one entry for each consecutive day going backwards from today or yesterday.
    func calculateCurrentStreak() throws -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        
        var streak = 0
        var checkDate = startOfToday
        
        // 1. Check if we have anything today or yesterday to start/continue the streak
        let hasToday = try hasEntries(on: startOfToday)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
        let hasYesterday = try hasEntries(on: yesterday)
        
        if !hasToday && !hasYesterday {
            return 0
        }
        
        // If we have nothing today but had something yesterday, the streak is still alive (it's "yesterday's" streak)
        // If we have something today, we start counting from today.
        if !hasToday {
            checkDate = yesterday
        }
        
        // 2. Count backwards
        while true {
            if try hasEntries(on: checkDate) {
                streak += 1
                guard let nextDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = nextDate
            } else {
                break
            }
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
