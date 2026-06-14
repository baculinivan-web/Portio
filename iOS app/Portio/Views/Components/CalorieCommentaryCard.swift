import SwiftUI

struct CalorieCommentaryCard: View {
    let commentary: CalorieCommentary

    var body: some View {
        Text(commentary.message)
            .font(.system(.subheadline, design: .rounded))
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack(spacing: 16) {
        CalorieCommentaryCard(
            commentary: CalorieCommentary(title: "Budget cliffhanger", message: "One more dramatic snack and the credits may roll early.")
        )
        CalorieCommentaryCard(
            commentary: CalorieCommentary(title: "Good pacing", message: "You are building toward the goal without crowding it yet.")
        )
    }
    .padding()
}
