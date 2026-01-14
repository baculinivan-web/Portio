import SwiftUI

struct NutrientWarningCard: View {
    let triggeredNutrients: [WarningNutrient]
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.orange.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(warningTitle)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("You might want to limit high \(triggeredNutrients.map { $0.rawValue }.joined(separator: "/")) foods")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }
    }
    
    private var warningTitle: String {
        let titles = triggeredNutrients.map { $0.rawValue }
        if titles.isEmpty { return "Nutritional Warning" }
        if titles.count == 1 {
            return "High \(titles[0]) detected"
        } else {
            let combined = titles.dropLast().joined(separator: ", ") + " & " + titles.last!
            return "High \(combined) detected"
        }
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.1).ignoresSafeArea()
        NutrientWarningCard(triggeredNutrients: [.calories, .carbs]) {
            print("Tapped")
        }
        .padding()
    }
}
