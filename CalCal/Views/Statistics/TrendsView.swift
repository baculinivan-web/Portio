import SwiftUI
import SwiftData

struct TrendsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTimeframe: TimeFrame = .week
    @State private var stats: [NutritionStats] = []
    
    @AppStorage("calorieGoal") private var calorieGoal: Double = UserSettings.calorieGoal
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Timeframe Selection
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(TimeFrame.allCases) { timeframe in
                        Text(timeframe.rawValue).tag(timeframe)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedTimeframe) { _, _ in
                    fetchData()
                }
                
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
            .padding(.vertical)
        }
        .onAppear {
            fetchData()
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
    TrendsView()
}
