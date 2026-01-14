import SwiftUI
import SwiftData

struct StatisticsView: View {
    @State private var selectedTab: StatsTab = .today
    @State private var selectedTimeframe: TimeFrame = .week

    var body: some View {
        ZStack {
            // Masterpiece background
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.red.opacity(0.1), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Picker("View Mode", selection: $selectedTab) {
                        ForEach(StatsTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if selectedTab == .allTime {
                        Picker("Timeframe", selection: $selectedTimeframe) {
                            ForEach(TimeFrame.allCases) { timeframe in
                                Text(timeframe.rawValue).tag(timeframe)
                            }
                        }
                        .pickerStyle(.segmented)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding()
                .onChange(of: selectedTab) { _, _ in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        // This triggers the transition
                    }
                }
                
                ScrollView {
                    VStack {
                        switch selectedTab {
                        case .today:
                            TodayView()
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        case .allTime:
                            TrendsView(selectedTimeframe: selectedTimeframe)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding(.top)
                }
                .scrollEdgeEffectStyle(.soft, for: .vertical)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.05),
                            .init(color: .black, location: 0.95),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .navigationTitle("Your Statistics")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        StatisticsView()
    }
}