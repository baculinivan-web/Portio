import SwiftUI
import AVFoundation

struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button {
                        cameraManager.stopSession()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding()
                    Spacer()
                }
                
                Spacer()
                
                // Bottom controls
                HStack {
                    Spacer()
                    Button {
                        cameraManager.capturePhoto()
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
        .onAppear {
            cameraManager.checkPermissionsAndSetup()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
}

#Preview {
    CameraView()
}
