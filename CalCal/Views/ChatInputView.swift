import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    var attachedImages: [UIImage]
    var onSend: () -> Void
    var onCameraTap: () -> Void
    var onRemoveImage: (Int) -> Void

    var body: some View {
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
                                    onRemoveImage(index)
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
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                }
            }
            
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
                .disabled(text.isEmpty && attachedImages.isEmpty)
            }
            .padding(.leading, 18)
            .padding(.trailing, 14)
            .padding(.vertical, 10)
        }
        // Using the correct system modifier for the glass effect.
        .glassEffect() // DO NOT TOUCH IT THIS IS THE RIGHT CODE THIS IS THE MODYFIER FOR AN ELEMENT BEENG GLASS LIKE
        .padding()
    }
}
