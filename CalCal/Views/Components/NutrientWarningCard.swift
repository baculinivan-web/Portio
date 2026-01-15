import SwiftUI

struct NutrientWarningCard: View {
    let triggeredWarnings: [WarningType]
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
                
                Text(warningSubtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }
    }
    
    private var warningTitle: String {
        var components: [String] = []
        
        let overshoots = triggeredWarnings.compactMap { if case .overshoot(let n) = $0 { return n.rawValue } else { return nil } }
        let imbalances = triggeredWarnings.filter { if case .imbalance = $0 { return true } else { return false } }
        
        if !overshoots.isEmpty {
            if overshoots.count == 1 {
                components.append("High \(overshoots[0])")
            } else {
                components.append("High \(overshoots.dropLast().joined(separator: ", ")) & \(overshoots.last!)")
            }
        }
        
        if !imbalances.isEmpty {
            components.append("Nutrient Imbalance")
        }
        
        if components.isEmpty { return "Nutritional Warning" }
        if components.count == 1 {
            return "\(components[0]) detected"
        } else {
            return "\(components.joined(separator: " & ")) detected"
        }
    }
    
    private var warningSubtitle: String {
        let hasImbalance = triggeredWarnings.contains { if case .imbalance = $0 { return true } else { return false } }
        if hasImbalance {
            return "Consider increasing protein and balancing intake"
        } else {
            let overshoots = triggeredWarnings.compactMap { if case .overshoot(let n) = $0 { return n.rawValue } else { return nil } }
            return "You might want to limit high \(overshoots.joined(separator: "/")) foods"
        }
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.1).ignoresSafeArea()
        VStack {
            NutrientWarningCard(triggeredWarnings: [.overshoot(.calories), .overshoot(.carbs)]) {
                print("Tapped")
            }
            NutrientWarningCard(triggeredWarnings: [.imbalance(.carbs)]) {
                print("Tapped")
            }
            NutrientWarningCard(triggeredWarnings: [.overshoot(.calories), .imbalance(.fat)]) {
                print("Tapped")
            }
        }
        .padding()
    }
}
