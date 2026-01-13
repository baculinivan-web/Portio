import SwiftUI
import SwiftData

struct TrendsView: View {
    @Environment(\.modelContext) private var modelContext
    let selectedTimeframe: TimeFrame
    @State private var stats: [NutritionStats] = []
    
    @AppStorage("calorieGoal") private var calorieGoal: Double = UserSettings.calorieGoal
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Performance Overview")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                // Summaries
                VStack(spacing: 12) {
                    TrendComparisonView(currentData: stats, metric: \.calories, title: "Calories")
                    TrendComparisonView(currentData: stats, metric: \.protein, title: "Protein")
                }
                .padding(.horizontal)
                
                // Charts
                VStack(spacing: 24) {
                    CalorieTrendChart(data: stats, timeframe: selectedTimeframe, calorieGoal: calorieGoal)
                    
                    MacroDistributionChart(data: stats, timeframe: selectedTimeframe)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .onAppear {
            fetchData()
        }
        .onChange(of: selectedTimeframe) { _, _ in
            withAnimation {
                fetchData()
            }
        }
    }
    
    private func fetchData() {
        let aggregator = NutritionAggregator(modelContext: modelContext)
        do {
            self.stats = try aggregator.aggregateStats(for: selectedTimeframe)
        } catch {
            print("Failed to fetch stats: \(error)")
        }
    }
}

#Preview {
    TrendsView(selectedTimeframe: .week)
}
