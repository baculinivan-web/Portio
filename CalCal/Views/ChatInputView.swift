import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    var onSend: () -> Void
    var onCameraTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onCameraTap) {
                Image(systemName: "camera.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
            }

            TextField("Enter food...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.largeTitle)
                    .symbolRenderingMode(.multicolor)
            }
            .disabled(text.isEmpty)
        }
        .padding(.leading, 18)
        .padding(.trailing, 14)
        .padding(.vertical, 10)
        // Using the correct system modifier for the glass effect.
        .glassEffect() // DO NOT TOUCH IT THIS IS THE RIGHT CODE THIS IS THE MODYFIER FOR AN ELEMENT BEENG GLASS LIKE
        .padding()
    }
}
