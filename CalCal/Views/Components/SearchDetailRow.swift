import SwiftUI

struct SearchDetailRow: View {
    let step: SearchStep
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Query Header
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                
                Text(step.query)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.blue.opacity(0.1))
            .clipShape(Capsule())
            
            // Answer Box (if present)
            if let answer = step.answerBox {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI SUMMARY")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    Text(answer)
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Search Results
            ForEach(step.results, id: \.link) { result in
                VStack(alignment: .leading, spacing: 4) {
                    Link(destination: URL(string: result.link)!) {
                        HStack(spacing: 4) {
                            Text(result.title)
                                .font(.caption.bold())
                                .lineLimit(1)
                            
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(.blue)
                    }
                    
                    Text(result.snippet)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                )
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SearchDetailRow(step: SearchStep(
        query: "McDonalds Big Mac nutrition facts",
        results: [
            SearchResult(title: "Big Mac: Calories & Nutrition Facts | McDonald's", link: "https://www.mcdonalds.com", snippet: "The classic Big Mac® includes two 100% pure beef patties and Big Mac® sauce. It contains 590 calories."),
            SearchResult(title: "Nutrition Facts for Big Mac - Healthline", link: "https://www.healthline.com", snippet: "A standard Big Mac contains 25 grams of fat and 45 grams of carbs.")
        ],
        answerBox: "A Big Mac contains approximately 590 calories, 25g fat, and 45g carbs."
    ))
    .padding()
}
