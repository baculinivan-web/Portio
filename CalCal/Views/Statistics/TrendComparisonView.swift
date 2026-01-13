import SwiftUI

struct TrendComparisonView: View {
    let currentData: [NutritionStats]
    let metric: KeyPath<NutritionStats, Double>
    let title: String
    
    // Simplification: We are just comparing the average of the current data set to a mock "previous" average or just summarizing the current trend.
    // Real comparison requires fetching previous period data which is outside the scope of the aggregator currently (aggregator fetches by range).
    // I'll update this to show the average for the period.
    
    private var average: Double {
        guard !currentData.isEmpty else { return 0 }
        let sum = currentData.reduce(0) { $0 + $1[keyPath: metric] }
        return sum / Double(currentData.count)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Average \(title)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(Int(average))")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            // Placeholder comparison
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.right")
                Text("N/A vs last period")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(8)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
    }
}
