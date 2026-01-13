import SwiftUI

struct PhotoPreviewView: View {
    let image: UIImage
    var onUse: () -> Void
    var onRetake: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                HStack(spacing: 50) {
                    Button(action: onRetake) {
                        Text("Retake")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 30)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white, lineWidth: 1))
                    }
                    
                    Button(action: onUse) {
                        Text("Use Photo")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 30)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    PhotoPreviewView(image: UIImage(systemName: "photo")!, onUse: {}, onRetake: {})
}
