import SwiftUI
import AVFoundation
import Combine

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage?
    @State private var flashMode: AVCaptureDevice.FlashMode = .off
    @State private var cameraPosition: AVCaptureDevice.Position = .back
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background like iOS Camera app
                Color.black
                    .ignoresSafeArea()
                
                // Camera Preview
                CameraPreviewView(cameraManager: cameraManager)
                    .ignoresSafeArea()
                
                // Camera Controls Overlay
                VStack {
                    // Top Controls
                    HStack {
                        // Flash Control
                        Button(action: toggleFlash) {
                            Image(systemName: flashIconName)
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(.regularMaterial, in: Circle())
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        Spacer()
                        
                        Spacer()
                        
                        // Camera Flip Button
                        Button(action: flipCamera) {
                            Image(systemName: "camera.rotate")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(.regularMaterial, in: Circle())
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Bottom Controls
                    VStack(spacing: 30) {
                        // Photo-only mode indicator
                        Text("PHOTO")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.yellow)
                        
                        HStack {
                            // Photo Library Thumbnail
                            Button(action: { showingImagePicker = true }) {
                                if let capturedImage = capturedImage {
                                    Image(uiImage: capturedImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(.white.opacity(0.3), lineWidth: 2)
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.regularMaterial)
                                        .frame(width: 50, height: 50)
                                        .overlay {
                                            Image(systemName: "photo.on.rectangle")
                                                .foregroundColor(.white)
                                        }
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(.white.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                            
                            Spacer()
                            
                            // Capture Button
                            Button(action: capturePhoto) {
                                ZStack {
                                    Circle()
                                        .fill(.regularMaterial)
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            Circle()
                                                .stroke(.white.opacity(0.3), lineWidth: 2)
                                        )
                                    
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 70, height: 70)
                                        .overlay(
                                            Circle()
                                                .stroke(.black.opacity(0.1), lineWidth: 1)
                                        )
                                }
                            }
                            
                            Spacer()
                            
                            // Timer Button
                            Button(action: {}) {
                                Image(systemName: "timer")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(.regularMaterial, in: Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                    .padding(.bottom, 40)
                }
                
                // Captured Image Preview Overlay
                if let capturedImage = capturedImage {
                    CapturedImagePreview(
                        image: capturedImage,
                        onDismiss: { self.capturedImage = nil }
                    )
                }
            }
        }
        .onAppear {
            cameraManager.requestPermission()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $capturedImage)
        }
    }
    
    private var flashIconName: String {
        switch flashMode {
        case .off:
            return "bolt.slash"
        case .on:
            return "bolt"
        case .auto:
            return "bolt.badge.a"
        @unknown default:
            return "bolt.slash"
        }
    }
    
    private func toggleFlash() {
        switch flashMode {
        case .off:
            flashMode = .auto
        case .auto:
            flashMode = .on
        case .on:
            flashMode = .off
        @unknown default:
            flashMode = .off
        }
        cameraManager.setFlashMode(flashMode)
    }
    
    private func flipCamera() {
        cameraPosition = cameraPosition == .back ? .front : .back
        cameraManager.flipCamera()
    }
    
    private func capturePhoto() {
        cameraManager.capturePhoto { image in
            if let image = image {
                self.capturedImage = image
            }
        }
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        cameraManager.setupPreview(in: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame when view bounds change
        DispatchQueue.main.async {
            cameraManager.updatePreviewFrame(to: uiView.bounds)
        }
    }
}

// MARK: - Captured Image Preview
struct CapturedImagePreview: View {
    let image: UIImage
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Button("Retake") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    
                    Spacer()
                    
                    Button("Use Photo") {
                        // Handle photo usage
                        onDismiss()
                    }
                    .foregroundColor(.yellow)
                    .padding()
                }
                
                Spacer()
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
            }
        }
    }
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject {
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentDevice: AVCaptureDevice?
    private var photoCompletion: ((UIImage?) -> Void)?
    private var previewView: UIView?
    
    override init() {
        super.init()
    }
    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                DispatchQueue.main.async {
                    self.setupCamera()
                }
            }
        }
    }
    
    private func setupCamera() {
        guard captureSession == nil else { return }
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get back camera")
            return
        }
        
        currentDevice = backCamera
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            
            if captureSession?.canAddInput(input) == true {
                captureSession?.addInput(input)
            }
            
            photoOutput = AVCapturePhotoOutput()
            if let photoOutput = photoOutput, captureSession?.canAddOutput(photoOutput) == true {
                captureSession?.addOutput(photoOutput)
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession?.startRunning()
                
                // Set up preview after session starts running
                DispatchQueue.main.async {
                    self.setupPreviewIfReady()
                }
            }
            
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    func setupPreview(in view: UIView) {
        previewView = view
        setupPreviewIfReady()
    }
    
    private func setupPreviewIfReady() {
        guard let captureSession = captureSession,
              let previewView = previewView,
              captureSession.isRunning else { return }
        
        // Remove existing preview layer if any
        previewLayer?.removeFromSuperlayer()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = previewView.bounds
        
        if let previewLayer = previewLayer {
            previewView.layer.addSublayer(previewLayer)
        }
    }
    
    func updatePreviewFrame(to bounds: CGRect) {
        previewLayer?.frame = bounds
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard let photoOutput = photoOutput else {
            completion(nil)
            return
        }
        
        photoCompletion = completion
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        guard let device = currentDevice, device.hasFlash else { return }
        
        do {
            try device.lockForConfiguration()
            // Flash mode is set per photo capture, not on the device
            device.unlockForConfiguration()
        } catch {
            print("Error setting flash mode: \(error)")
        }
    }
    
    func flipCamera() {
        guard let captureSession = captureSession else { return }
        
        captureSession.beginConfiguration()
        
        // Remove current input
        if let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput {
            captureSession.removeInput(currentInput)
        }
        
        // Get the other camera
        let newPosition: AVCaptureDevice.Position = currentDevice?.position == .back ? .front : .back
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            captureSession.commitConfiguration()
            return
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newCamera)
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
                currentDevice = newCamera
            }
        } catch {
            print("Error flipping camera: \(error)")
        }
        
        captureSession.commitConfiguration()
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            photoCompletion?(nil)
            return
        }
        
        photoCompletion?(image)
    }
}

// MARK: - Image Picker (for photo library access)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    CameraView()
}