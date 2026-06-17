import SwiftUI

struct DayAnalysisCardView: View {
    let result: DayAnalysisResult?
    let status: DayAnalysisViewModel.Status
    let isAutomaticEnabled: Bool
    let onTap: () -> Void

    private var text: String {
        if !isAutomaticEnabled && result == nil {
            return "Tap for AI analysis"
        }

        if let summary = result?.summary, !summary.isEmpty {
            return summary
        }

        if status.isLoading {
            return "Analysing today's food"
        }

        if case .failed = status {
            return "Tap to retry AI analysis"
        }

        return "Tap for AI analysis"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text(text)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .frame(maxWidth: .infinity, alignment: .leading)

                if status.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(text)
        .animation(.snappy(duration: 0.28), value: text)
        .animation(.snappy(duration: 0.28), value: status)
    }
}
