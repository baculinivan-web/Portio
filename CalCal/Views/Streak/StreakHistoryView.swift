import SwiftUI
import SwiftData

struct StreakHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var monthlyStats: [String: [Date: NutritionStats]] = [:]
    @State private var selectedDate: Date? = nil
    
    private var months: [(month: Int, year: Int)] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<12).compactMap { i in
            guard let date = calendar.date(byAdding: .month, value: -i, to: now) else { return nil }
            return (calendar.component(.month, from: date), calendar.component(.year, from: date))
        }
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(months, id: \.month) { item in
                        ContributionGridView(
                            month: item.month,
                            year: item.year,
                            dailyStats: monthlyStats["\(item.year)-\(item.month)"] ?? [:],
                            onDateSelected: { date in
                                selectedDate = date
                            }
                        )
                        .containerRelativeFrame(.vertical)
                        .onAppear {
                            loadStats(month: item.month, year: item.year)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .ignoresSafeArea()
            
            // Dismiss Button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.secondary.opacity(0.5))
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
    
    private func loadStats(month: Int, year: Int) {
        let key = "\(year)-\(month)"
        guard monthlyStats[key] == nil else { return }
        
        let aggregator = NutritionAggregator(modelContext: modelContext)
        do {
            let stats = try aggregator.fetchMonthlyStats(month: month, year: year)
            var dict: [Date: NutritionStats] = [:]
            let calendar = Calendar.current
            for s in stats {
                dict[calendar.startOfDay(for: s.date)] = s
            }
            monthlyStats[key] = dict
        } catch {
            print("Failed to load stats for \(key): \(error)")
        }
    }
}

#Preview {
    StreakHistoryView()
}
