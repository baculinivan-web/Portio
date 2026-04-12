import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    var attachedImages: [UIImage]
    var onSend: () -> Void
    var onCameraTap: () -> Void
    var onRemoveImage: (Int) -> Void
    var focusState: FocusState<Bool>.Binding

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            // Camera button
            Button(action: onCameraTap) {
                Image(systemName: "camera.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            .frame(width: 58, height: 58)
            .glassEffect(.regular.tint(.clear), in: ContainerRelativeShape())
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

                HStack(alignment: .bottom, spacing: 8) {
                    TextField("Enter food...", text: $text, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...5)
                        .focused(focusState)
                        .frame(minHeight: 34)

                    Button(action: onSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.largeTitle)
                            .symbolRenderingMode(.multicolor)
                    }
                    .disabled(text.isEmpty && attachedImages.isEmpty)
                    .frame(height: 34)
                }
                .padding(.leading, 14)
                .padding(.trailing, 10)
                .padding(.vertical, 12)
            }
            .glassEffect(.regular.tint(.clear), in: ContainerRelativeShape())
            .containerShape(RoundedRectangle(cornerRadius: 22))
        }
        .padding()
    }
}
