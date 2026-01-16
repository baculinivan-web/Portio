import SwiftUI
import SwiftData

struct StreakHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var monthlyStats: [String: [Date: NutritionStats]] = [:]
    @State private var selectedDate: Date? = nil
    @State private var showingLegend = false
    
    private var months: [(month: Int, year: Int)] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<12).compactMap { i in
            guard let date = calendar.date(byAdding: .month, value: -i, to: now) else { return nil }
            return (calendar.component(.month, from: date), calendar.component(.year, from: date))
        }
    }
    
    var body: some View {
        NavigationStack {
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
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingLegend = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                }
            }
            .alert("About Colors", isPresented: $showingLegend) {
                Button("Got it") { }
            } message: {
                Text("• Light Gray: No items logged\n• Translucent Orange: At least one item logged\n• Solid Orange: Goal reached (depends on your Weight Goal Mode)")
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
