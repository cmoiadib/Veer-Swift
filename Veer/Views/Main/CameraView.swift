import SwiftUI
import AVFoundation
import Combine
import PhotosUI

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

// MARK: - Processing View
struct ProcessingView: View {
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Loading spinner
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }
                
                Text("AI is working its magic...")
                    .font(.title2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Superimposing clothing onto your photo")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

// MARK: - Result View
struct ResultView: View {
    let image: UIImage
    let onStartOver: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Button("Start Over") {
                        onStartOver()
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
                    
                    Button("Save") {
                        // Save to photo library
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
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
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer()
                
                Text("Your AI-generated result!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
            }
        }
    }
}

enum PhotoCaptureStep {
    case person
    case clothing
    case processing
    case result
}

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var showingImagePicker = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var personPhoto: UIImage?
    @State private var clothingPhoto: UIImage?
    @State private var currentStep: PhotoCaptureStep = .person
    @State private var flashMode: AVCaptureDevice.FlashMode = .off
    @State private var cameraPosition: AVCaptureDevice.Position = .back
    @State private var showFlashMenu = false
    @State private var isProcessing = false
    @State private var resultImage: UIImage?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var isRetrying = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background like iOS Camera app
                Color.black
                    .ignoresSafeArea()
                
                // Camera Preview
                if currentStep == .person || currentStep == .clothing {
                    CameraPreviewView(cameraManager: cameraManager)
                        .ignoresSafeArea()
                }
                
                // Processing view with retry indicator
                if currentStep == .processing {
                    ZStack {
                        ProcessingView()
                        
                        if isRetrying {
                            VStack {
                                Spacer()
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                    Text("Retrying...")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .padding(.bottom, 100)
                            }
                        }
                    }
                }
                
                // Result View
                if currentStep == .result, let resultImage = resultImage {
                    ResultView(image: resultImage) {
                        // Reset to start over
                        resetCameraFlow()
                    }
                }
                
                // Camera Controls Overlay
                if currentStep == .person || currentStep == .clothing {
                    VStack {
                        // Top Controls
                        HStack {
                            // Instruction Text
                            Text(currentStep == .person ? "Take a photo of yourself" : "Take a photo of the clothing")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                            
                            Spacer()
                            
                            // Flash Control
                            ZStack {
                            // Background button that's always visible for proper layout
                            RoundedRectangle(cornerRadius: 22)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                .frame(width: 44, height: 44)
                            
                            Menu {
                                ForEach([
                                    (AVCaptureDevice.FlashMode.off, "bolt.slash", "Off"),
                                    (AVCaptureDevice.FlashMode.auto, "bolt.badge.a", "Auto"),
                                    (AVCaptureDevice.FlashMode.on, "bolt", "On")
                                ], id: \.0) { option in
                                    Button(action: {
                                        flashMode = option.0
                                        cameraManager.setFlashMode(option.0)
                                        
                                        // Haptic feedback
                                        let selectionFeedback = UISelectionFeedbackGenerator()
                                        selectionFeedback.selectionChanged()
                                    }) {
                                        Label(option.2, systemImage: option.1)
                                    }
                                }
                            } label: {
                                Image(systemName: flashIconName)
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .opacity(showFlashMenu ? 0.3 : 1.0)
                                    .animation(.easeInOut(duration: 0.15), value: showFlashMenu)
                            }
                            .menuOrder(.fixed)
                            .menuActionDismissBehavior(.automatic)
                            .simultaneousGesture(
                                TapGesture()
                                    .onEnded { _ in
                                        showFlashMenu = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            showFlashMenu = false
                                        }
                                    }
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
                        }
                        .glassEffect()
                    }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        Spacer()
                        
                        // Bottom Controls
                        VStack(spacing: 30) {
                            
                            HStack {
                                // Photo Library Thumbnail or Previous Photo
                                Button(action: { 
                                    if currentStep == .clothing && personPhoto != nil {
                                        // Show person photo
                                    } else {
                                        showingImagePicker = true 
                                    }
                                }) {
                                    if currentStep == .clothing, let personPhoto = personPhoto {
                                        Image(uiImage: personPhoto)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 50, height: 50)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(.white.opacity(0.3), lineWidth: 2)
                                            )
                                    } else if let capturedImage = capturedImage {
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
                            if currentStep == .clothing {
                                // Gallery button for clothing selection
                                Button(action: {
                                    showingPhotoPicker = true
                                }) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.clear)
                                        .frame(width: 50, height: 50)
                                        .overlay {
                                            Image(systemName: "photo.stack")
                                                .foregroundColor(.white)
                                                .font(.title2)
                                        }
                                }
                                .glassEffect(in: .rect(cornerRadius: 12))
                            } else {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 50, height: 50)
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                    .padding(.bottom, 40)
                }
                }
                
                // Captured Image Preview Overlay
                if let capturedImage = capturedImage {
                    CapturedImagePreview(
                        image: capturedImage,
                        currentStep: currentStep,
                        onRetake: { self.capturedImage = nil },
                        onUsePhoto: { 
                            if currentStep == .person {
                                personPhoto = capturedImage
                                currentStep = .clothing
                                self.capturedImage = nil
                            } else if currentStep == .clothing {
                                clothingPhoto = capturedImage
                                self.capturedImage = nil
                                processPhotos()
                            }
                        }
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
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { oldItem, newItem in
            Task {
                if let newItem = newItem {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            capturedImage = uiImage
                        }
                    }
                }
                selectedPhotoItem = nil
            }
        }
        .alert("Processing Error", isPresented: $showingError) {
            Button("Try Again") {
                processPhotos()
            }
            Button("Cancel") {
                currentStep = .clothing
            }
        } message: {
            Text(errorMessage ?? "An error occurred while processing your photos. Please try again.")
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
    
    private func resetCameraFlow() {
        currentStep = .person
        personPhoto = nil
        clothingPhoto = nil
        resultImage = nil
        capturedImage = nil
        isProcessing = false
        errorMessage = nil
        showingError = false
        isRetrying = false
    }
    
    private func processPhotos() {
        guard let personPhoto = personPhoto, let clothingPhoto = clothingPhoto else { return }
        
        currentStep = .processing
        errorMessage = nil
        showingError = false
        isRetrying = false
        
        Task {
            do {
                let apiKey = "AIzaSyD_5_pZEMrVNDqFMxF4RKwEcZC74r7tvVw"
                let geminiService = GeminiAPIService(apiKey: apiKey)
                
                // Monitor retry attempts
                let result = try await withThrowingTaskGroup(of: UIImage.self) { group in
                    group.addTask {
                        // Set retry indicator when service starts retrying
                        await MainActor.run {
                            self.isRetrying = true
                        }
                        
                        let result = try await geminiService.generateClothingVisualization(
                            personImage: personPhoto,
                            clothingImage: clothingPhoto
                        )
                        
                        await MainActor.run {
                            self.isRetrying = false
                        }
                        
                        return result
                    }
                    
                    return try await group.next()!
                }
                
                await MainActor.run {
                    self.resultImage = result
                    self.currentStep = .result
                    self.isRetrying = false
                }
                
            } catch let error as GeminiAPIError {
                await MainActor.run {
                    self.isRetrying = false
                    
                    // Set user-friendly error message
                    switch error {
                    case .invalidURL:
                        self.errorMessage = "Invalid API URL configuration. Please try again."
                    case .imageProcessingFailed:
                        self.errorMessage = "Failed to process images. Please try again."
                    case .encodingFailed:
                        self.errorMessage = "Failed to encode request. Please try again."
                    case .serviceUnavailable:
                        self.errorMessage = "The AI service is temporarily unavailable. Please try again in a moment."
                    case .rateLimited:
                        self.errorMessage = "Too many requests. Please wait a moment and try again."
                    case .httpError(let code):
                        if code == 503 {
                            self.errorMessage = "The AI service is temporarily busy. Please try again."
                        } else if code == 429 {
                            self.errorMessage = "Rate limit exceeded. Please wait and try again."
                        } else if code >= 500 {
                            self.errorMessage = "Server error occurred. Please try again later."
                        } else {
                            self.errorMessage = "Network error (Code: \(code)). Please check your connection and try again."
                        }
                    case .invalidResponse:
                        self.errorMessage = "Invalid response from AI service. Please try again."
                    case .decodingFailed:
                        self.errorMessage = "Error processing AI response. Please try again."
                    case .imageDecodingFailed:
                        self.errorMessage = "Failed to decode generated image. Please try again."
                    case .noImageInResponse:
                        self.errorMessage = "No image was generated. Please try again."
                    case .noTextInResponse:
                        self.errorMessage = "No response received from AI. Please try again."
                    }
                    
                    self.showingError = true
                    self.currentStep = .clothing
                }
                
            } catch {
                print("Unexpected error processing photos: \(error)")
                
                await MainActor.run {
                    self.isRetrying = false
                    self.errorMessage = "An unexpected error occurred. Please try again."
                    self.showingError = true
                    self.currentStep = .clothing
                }
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
    let currentStep: PhotoCaptureStep
    let onRetake: () -> Void
    let onUsePhoto: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Button("Retake") {
                        onRetake()
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
                        onUsePhoto()
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
