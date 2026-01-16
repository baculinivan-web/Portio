import SwiftUI

struct StreakHistoryView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Streak History")
                    .font(.largeTitle)
                    .padding()
                Text("Monthly Contribution Grid (TikTok style) coming soon...")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    StreakHistoryView()
}
