import SwiftUI
import SwiftData

struct StatisticsView: View {
    @State private var selectedTab: StatsTab = .today

    var body: some View {
        VStack {
            Picker("View Mode", selection: $selectedTab) {
                ForEach(StatsTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Using a ZStack or just a switch to switch views
            // Ideally we want smooth transitions
            switch selectedTab {
            case .today:
                TodayView()
            case .allTime:
                TrendsView()
            }
            
            Spacer()
        }
        .navigationTitle("Your Statistics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        StatisticsView()
    }
}