import SwiftUI
import SwiftData

struct StatisticsView: View {
    @State private var selectedTab: StatsTab = .today
    @State private var selectedTimeframe: TimeFrame = .week

    var body: some View {
        ScrollView {
            // Tiny clear view to help trigger large title behavior
            Color.clear.frame(height: 1)
            
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    switch selectedTab {
                    case .today:
                        TodayView()
                            .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    case .allTime:
                        TrendsView(selectedTimeframe: selectedTimeframe)
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
                    }
                } header: {
                    VStack(spacing: 12) {
                        Picker("View Mode", selection: $selectedTab) {
                            ForEach(StatsTab.allCases) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(4)
                        .background(.ultraThinMaterial, in: Capsule())
                        
                        if selectedTab == .allTime {
                            Picker("Timeframe", selection: $selectedTimeframe) {
                                ForEach(TimeFrame.allCases) { timeframe in
                                    Text(timeframe.rawValue).tag(timeframe)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding()
                    .onChange(of: selectedTab) { _, _ in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            // This triggers the transition
                        }
                    }
                }
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .vertical)
        .navigationTitle("Your Statistics")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        StatisticsView()
    }
}
