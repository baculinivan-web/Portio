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
    @Published var cameraError: CameraError?
    
    private let output = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    enum CameraError: Error, LocalizedError {
        case cameraUnavailable
        case cannotAddInput
        case cannotAddOutput
        case captureFailed
        
        var errorDescription: String? {
            switch self {
            case .cameraUnavailable:
                return "Camera is not available on this device."
            case .cannotAddInput:
                return "Failed to connect to the camera input."
            case .cannotAddOutput:
                return "Failed to setup camera output."
            case .captureFailed:
                return "Failed to capture photo."
            }
        }
    }
    
    override init() {
        super.init()
    }
    
    func checkPermissionsAndSetup() {
        #if targetEnvironment(simulator)
        DispatchQueue.main.async {
            self.cameraError = .cameraUnavailable
        }
        return
        #endif
        
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
                } else {
                    DispatchQueue.main.async {
                        self.cameraError = .cameraUnavailable
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.cameraError = .cameraUnavailable
            }
        @unknown default:
            break
        }
    }
    
    private func setupSession() {
        session.beginConfiguration()
        
        // Add Input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            self.cameraError = .cameraUnavailable
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(input) {
                session.addInput(input)
                self.videoDeviceInput = input
            } else {
                self.cameraError = .cannotAddInput
                return
            }
        } catch {
            self.cameraError = .cannotAddInput
            return
        }
        
        // Add Output
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            self.cameraError = .cannotAddOutput
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
