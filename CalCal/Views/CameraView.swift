import SwiftUI
import AVFoundation

struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }
                
                Spacer()
                
                // Placeholder for camera feed
                Text("Camera Feed Placeholder")
                    .foregroundColor(.white)
                
                Spacer()
                
                // Bottom controls placeholder
                HStack {
                    Spacer()
                    Button {
                        // Capture action
                    } label: {
                        Circle()
                            .strokeBorder(.white, lineWidth: 3)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .fill(.white)
                                    .frame(width: 60, height: 60)
                            )
                    }
                    Spacer()
                }
                .padding(.bottom, 30)
            }
        }
    }
}

#Preview {
    CameraView()
}
