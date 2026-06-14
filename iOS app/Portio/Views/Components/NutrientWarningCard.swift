import SwiftUI

struct NutrientWarningCard: View {
    let triggeredWarnings: [WarningType]
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(.orange.opacity(0.2))
                    .frame(width: 34, height: 34)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(warningTitle)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(warningSubtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

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

        if !overshoots.isEmpty { components.append("High \(joinedList(overshoots))") }

        if !imbalances.isEmpty { components.append("Imbalance") }

        if components.isEmpty { return "Nutritional Warning" }
        return components.joined(separator: " + ")
    }

    private var warningSubtitle: String {
        let hasImbalance = triggeredWarnings.contains { if case .imbalance = $0 { return true } else { return false } }
        let overshoots = triggeredWarnings.compactMap { if case .overshoot(let n) = $0 { return n.rawValue.lowercased() } else { return nil } }

        if hasImbalance {
            if overshoots.isEmpty {
                return "Protein is lagging behind the rest of the day."
            }
            return "Protein is lagging; also watch \(joinedList(overshoots))."
        }

        return "Limit high-\(overshoots.joined(separator: "/")) foods from here."
    }

    private func joinedList(_ values: [String]) -> String {
        guard let last = values.last else { return "" }
        if values.count == 1 { return last }
        return "\(values.dropLast().joined(separator: ", ")) & \(last)"
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.1).ignoresSafeArea()
        VStack {
            NutrientWarningCard(triggeredWarnings: [.overshoot(.calories), .overshoot(.carbs)]) {}
            NutrientWarningCard(triggeredWarnings: [.imbalance(.carbs)]) {}
            NutrientWarningCard(triggeredWarnings: [.overshoot(.calories), .imbalance(.fat)]) {}
        }
        .padding()
    }
}
