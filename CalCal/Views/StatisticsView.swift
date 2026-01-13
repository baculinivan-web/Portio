import SwiftUI
import SwiftData
import Charts

// MARK: - Main View
struct StatisticsView: View {
    @Query(sort: \FoodItem.dateEaten, order: .reverse) private var allItems: [FoodItem]
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedDate: Date = .now

    var body: some View {
        VStack {
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            DateScrubberView(selectedDate: $selectedDate, timeRange: selectedTimeRange)
            
            CalorieChartView(
                items: allItems,
                targetDate: selectedDate,
                timeRange: selectedTimeRange
            )
        }
        .navigationTitle("Your Statistics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Supporting Enums and Structs
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

// MARK: - Date Scrubber View
struct DateScrubberView: View {
    @Binding var selectedDate: Date
    let timeRange: TimeRange
    
    private var dateRangeText: String {
        let interval = timeRange == .week ? Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate) :
                       timeRange == .month ? Calendar.current.dateInterval(of: .month, for: selectedDate) :
                       Calendar.current.dateInterval(of: .year, for: selectedDate) // Simplified for 6M
        
        guard let interval else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if timeRange == .sixMonths {
            return "Jan - Jun 2025" // This needs to be made dynamic
        }
        
        return "\(formatter.string(from: interval.start)) - \(formatter.string(from: interval.end))"
    }

    var body: some View {
        HStack {
            Button(action: { moveDate(by: -1) }) { Image(systemName: "chevron.left") }
            Spacer()
            Text(dateRangeText).font(.headline)
            Spacer()
            Button(action: { moveDate(by: 1) }) { Image(systemName: "chevron.right") }
        }
        .padding()
    }
    
    private func moveDate(by amount: Int) {
        var dateComponent = DateComponents()
        switch timeRange {
        case .week: dateComponent.weekOfYear = amount
        case .month: dateComponent.month = amount
        case .sixMonths: dateComponent.month = amount * 6
        }
        if let newDate = Calendar.current.date(byAdding: dateComponent, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

// MARK: - Chart View
struct CalorieChartView: View {
    let items: [FoodItem]
    let targetDate: Date
    let timeRange: TimeRange

    private var chartData: [DailyCalories] {
        // 1. Determine the date interval for the chart
        guard let interval = dateInterval() else { return [] }
        
        // 2. Filter items to only those within the interval
        let filteredItems = items.filter { interval.contains($0.dateEaten) }
        
        // 3. Group items by day and sum calories
        let groupedByDay = Dictionary(grouping: filteredItems) { item in
            Calendar.current.startOfDay(for: item.dateEaten)
        }
        
        // 4. Create DailyCalories structs for the chart
        var dailyTotals: [DailyCalories] = []
        var currentDate = interval.start
        while currentDate <= interval.end {
            let calories = groupedByDay[currentDate]?.reduce(0) { $0 + $1.calories } ?? 0
            dailyTotals.append(DailyCalories(date: currentDate, calories: calories))
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return dailyTotals
    }

    var body: some View {
        Chart(chartData) { dataPoint in
            BarMark(
                x: .value("Date", dataPoint.date, unit: .day),
                y: .value("Calories", dataPoint.calories)
            )
            .foregroundStyle(.blue)
            .cornerRadius(6)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) {
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
            }
        }
        .padding()
    }
    
    private func dateInterval() -> DateInterval? {
        let calendar = Calendar.current
        switch timeRange {
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: targetDate)
        case .month:
            return calendar.dateInterval(of: .month, for: targetDate)
        case .sixMonths: // Simplified for now
            let start = calendar.date(byAdding: .month, value: -6, to: targetDate) ?? targetDate
            return DateInterval(start: start, end: targetDate)
        }
    }
}

#Preview {
    NavigationStack {
        StatisticsView()
    }
}