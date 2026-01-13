import SwiftUI
import PhotosUI

struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var cameraManager = CameraManager()
    @State private var selectedItems: [PhotosPickerItem] = []
    
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
                    // Gallery Button
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 1, matching: .images) {
                        if let thumbnail = cameraManager.latestThumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 2))
                        } else {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 2))
                        }
                    }
                    .onChange(of: selectedItems) { _, newValue in
                        if let first = newValue.first {
                            Task {
                                if let data = try? await first.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    await MainActor.run {
                                        cameraManager.capturedImage = image
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Capture Button
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
                    
                    // Placeholder for symmetrical layout
                    Color.clear.frame(width: 50, height: 50)
                }
                .padding(.horizontal, 40)
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
