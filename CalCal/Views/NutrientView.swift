import SwiftUI

struct NutrientView: View {
    let name: String
    let value: Double
    let goal: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("**\(value, format: .number.precision(.fractionLength(0)))** / \(goal, format: .number.precision(.fractionLength(0))) g")
                .font(.system(.caption, design: .rounded).weight(.medium))
                .contentTransition(.numericText(value: value))
        }
    }
}