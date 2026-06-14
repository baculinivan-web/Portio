import Foundation

enum FoodItemDaySelection {
    static func items(from items: [FoodItem], on date: Date, calendar: Calendar = .current) -> [FoodItem] {
        items
            .filter { calendar.isDate($0.dateEaten, inSameDayAs: date) }
            .sorted { $0.dateEaten > $1.dateEaten }
    }

    static func isToday(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        calendar.isDate(date, inSameDayAs: now)
    }

    static func title(for date: Date, now: Date = .now, calendar: Calendar = .current, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MMM d")

        if isToday(date, now: now, calendar: calendar) {
            return "Today, \(formatter.string(from: date))"
        }

        return formatter.string(from: date)
    }
}
