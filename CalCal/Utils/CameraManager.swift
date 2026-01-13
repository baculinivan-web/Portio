import Foundation
import AVFoundation
import UIKit
import Photos
import Combine

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var capturedImage: UIImage?
    @Published var isSessionRunning = false
    @Published var latestThumbnail: UIImage?
    
    private let output = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    enum CameraError: Error {
        case cameraUnavailable
        case cannotAddInput
        case cannotAddOutput
        case captureFailed
    }
    
    override init() {
        super.init()
    }
    
    func checkPermissionsAndSetup() {
        checkCameraPermissions()
        checkPhotoLibraryPermissions()
    }
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupSession()
                    }
                }
            }
        default:
            break
        }
    }
    
    private func checkPhotoLibraryPermissions() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            if status == .authorized || status == .limited {
                self.fetchLatestPhoto()
            }
        }
    }
    
    private func fetchLatestPhoto() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        if let firstAsset = fetchResult.firstObject {
            let manager = PHImageManager.default()
            let option = PHImageRequestOptions()
            option.isSynchronous = false
            option.deliveryMode = .highQualityFormat
            
            manager.requestImage(for: firstAsset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: option) { image, _ in
                DispatchQueue.main.async {
                    self.latestThumbnail = image
                }
            }
        }
    }
    
    private func setupSession() {
        session.beginConfiguration()
        
        // Add Input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(input) {
                session.addInput(input)
                self.videoDeviceInput = input
            } else {
                return
            }
        } catch {
            return
        }
        
        // Add Output
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            return
        }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
    
    func stopSession() {
        if session.isRunning {
            session.stopRunning()
            isSessionRunning = session.isRunning
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else { return }
        self.capturedImage = UIImage(data: imageData)
    }
}
