import SwiftUI
import AVFoundation
import Combine

// MARK: - Glass Effect Extension
extension View {
    func glassEffect(in shape: AnyShape = AnyShape(Circle())) -> some View {
        self
            .background(.ultraThinMaterial, in: shape)
            .overlay(
                shape
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage?
    @State private var flashMode: AVCaptureDevice.FlashMode = .off
    @State private var cameraPosition: AVCaptureDevice.Position = .back
    @State private var isFlashMenuPresented = false
    
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
                        Menu {
                            Button(action: {
                                flashMode = .auto
                                cameraManager.setFlashMode(.auto)
                                
                                // Haptic feedback
                                let selectionFeedback = UISelectionFeedbackGenerator()
                                selectionFeedback.selectionChanged()
                            }) {
                                Label {
                                    Text("Auto")
                                } icon: {
                                    HStack {
                                        Image(systemName: "bolt.badge.a")
                                        if flashMode == .auto {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                            
                            Button(action: {
                                flashMode = .on
                                cameraManager.setFlashMode(.on)
                                
                                // Haptic feedback
                                let selectionFeedback = UISelectionFeedbackGenerator()
                                selectionFeedback.selectionChanged()
                            }) {
                                Label {
                                    Text("On")
                                } icon: {
                                    HStack {
                                        Image(systemName: "bolt")
                                        if flashMode == .on {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                            
                            Button(action: {
                                flashMode = .off
                                cameraManager.setFlashMode(.off)
                                
                                // Haptic feedback
                                let selectionFeedback = UISelectionFeedbackGenerator()
                                selectionFeedback.selectionChanged()
                            }) {
                                Label {
                                    Text("Off")
                                } icon: {
                                    HStack {
                                        Image(systemName: "bolt.slash")
                                        if flashMode == .off {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                             // Flash button with background and animation
                             ZStack {
                                 RoundedRectangle(cornerRadius: 22)
                                     .fill(.ultraThinMaterial)
                                     .overlay(
                                         RoundedRectangle(cornerRadius: 22)
                                             .stroke(.white.opacity(0.2), lineWidth: 1)
                                     )
                                     .frame(width: 44, height: 44)
                                 
                                 Image(systemName: flashIconName)
                                     .font(.title2)
                                     .foregroundColor(.white)
                                     .frame(width: 44, height: 44)
                             }
                         }
                         .menuOrder(.fixed)
                         .menuActionDismissBehavior(.automatic)
                        
                        Spacer()
                        
                        Spacer()
                        
                        // Camera Flip Button
                        Button(action: flipCamera) {
                            Image(systemName: "camera.rotate")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                        .glassEffect()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Bottom Controls
                    VStack(spacing: 30) {
                        
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
                                        .fill(.clear)
                                        .frame(width: 50, height: 50)
                                        .overlay {
                                            Image(systemName: "photo.on.rectangle")
                                                .foregroundColor(.white)
                                        }
                                }
                            }
                            .glassEffect(in: .rect(cornerRadius: 12))
                            
                            Spacer()
                            
                            // Capture Button
                            Button(action: capturePhoto) {
                                ZStack {
                                    Circle()
                                        .fill(.clear)
                                        .frame(width: 80, height: 80)
                                    
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 70, height: 70)
                                        .overlay(
                                            Circle()
                                                .stroke(.black.opacity(0.1), lineWidth: 1)
                                        )
                                }
                            }
                            .glassEffect()
                            
                            Spacer()
                            
                            // Empty spacer to balance layout
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 50, height: 50)
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
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    
                    Spacer()
                    
                    Button("Use Photo") {
                        // Handle photo usage
                        onDismiss()
                    }
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
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
        
        // Set flash mode based on current flash setting
        if let device = currentDevice, device.hasFlash {
            settings.flashMode = device.position == .front ? .off : getCurrentFlashMode()
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    private var currentFlashMode: AVCaptureDevice.FlashMode = .off
    
    private func getCurrentFlashMode() -> AVCaptureDevice.FlashMode {
        return currentFlashMode
    }
    
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        currentFlashMode = mode
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
