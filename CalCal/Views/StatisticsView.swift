import SwiftUI
import SwiftData

struct StatisticsView: View {
    @State private var selectedTab: StatsTab = .today

    var body: some View {
        ZStack {
            // Masterpiece background
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Picker("View Mode", selection: $selectedTab) {
                    ForEach(StatsTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(.ultraThinMaterial)
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
                            TrendsView()
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
    }
}

#Preview {
    NavigationStack {
        StatisticsView()
    }
}