import SwiftUI
import UIKit

struct ChatInputView: View {
    @Binding var text: String
    var attachedImages: [UIImage]
    var onSend: () -> Void
    var onCameraTap: () -> Void
    var onManualTap: () -> Void
    var onRemoveImage: (Int) -> Void
    var focusState: FocusState<Bool>.Binding

    private enum Metrics {
        static let outerPadding: CGFloat = 16
        static let controlSize: CGFloat = 58
        static let promptCornerRadius: CGFloat = controlSize / 2
        static let maxBottomSafeAreaCompensation: CGFloat = 40
    }

    private var bottomSafeAreaCompensation: CGFloat {
        guard !focusState.wrappedValue else { return 0 }

        let bottomInset = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .safeAreaInsets
            .bottom ?? 0

        return min(bottomInset, Metrics.maxBottomSafeAreaCompensation)
    }

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(alignment: .bottom, spacing: 10) {
                // Camera button
                Button(action: onCameraTap) {
                    ZStack {
                        Circle()
                            .fill(.clear)
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    .frame(width: Metrics.controlSize, height: Metrics.controlSize)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(.clear).interactive(), in: ContainerRelativeShape())
                .containerShape(Circle())

                // Input bubble
                VStack(alignment: .leading, spacing: 0) {
                    if !attachedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(0..<attachedImages.count, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: attachedImages[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))

                                        Button {
                                            withAnimation(.spring()) {
                                                onRemoveImage(index)
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Color.black.opacity(0.5))
                                                .clipShape(Circle())
                                        }
                                        .offset(x: 5, y: -5)
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.top, 10)
                            .padding(.bottom, 5)
                        }
                    }

                    TextField("Enter food...", text: $text, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...5)
                        .focused(focusState)
                        .frame(minHeight: 34)
                        .padding(.leading, 14)
                        .padding(.trailing, 14)
                        .padding(.vertical, 12)
                }
                .glassEffect(
                    .regular.tint(.clear).interactive(),
                    in: .rect(cornerRadius: Metrics.promptCornerRadius, style: .continuous)
                )
                .containerShape(
                    RoundedRectangle(cornerRadius: Metrics.promptCornerRadius, style: .continuous)
                )

                Button(action: trailingButtonAction) {
                    ZStack {
                        Circle()
                            .fill(.clear)
                        Image(systemName: focusState.wrappedValue ? "arrow.up" : "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.primary)
                    }
                    .frame(width: Metrics.controlSize, height: Metrics.controlSize)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(focusState.wrappedValue && text.isEmpty && attachedImages.isEmpty)
                .accessibilityLabel(focusState.wrappedValue ? "Send food entry" : "Log by hand")
                .glassEffect(.regular.tint(.clear).interactive(), in: ContainerRelativeShape())
                .containerShape(Circle())
                .animation(.spring(response: 0.25, dampingFraction: 0.85), value: focusState.wrappedValue)
            }
        }
        .padding(Metrics.outerPadding)
        .offset(y: bottomSafeAreaCompensation)
    }

    private func trailingButtonAction() {
        if focusState.wrappedValue {
            onSend()
        } else {
            onManualTap()
        }
    }
}
