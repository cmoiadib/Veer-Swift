import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - Camera View for Try-On AI
struct CameraView: View {
    // MARK: - State Management
    @State private var currentStep: CaptureStep = .userPhoto
    @State private var userPhoto: UIImage?
    @State private var clothingPhoto: UIImage?
    @State private var isGenerating = false
    @State private var showingCameraPicker = false
    @State private var showingPhotoPicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var generatedImage: UIImage?
    @State private var showingResult = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingClothingOptions = false
    @State private var selectedClothingType: ClothingType = .tshirt
    @State private var selectedFitStyle: FitStyle = .regular
    @State private var selectedClothingState: ClothingState = .closed

    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss

    // MARK: - Camera Permission
    @State private var cameraPermissionGranted = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.clear
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Step Indicator
                        stepIndicatorView

                        // Instruction Text
                        instructionTextView

                        // Photo Preview
                        photoPreviewView

                        // Clothing Options (shown after both photos are captured)
                        if userPhoto != nil && clothingPhoto != nil && showingClothingOptions {
                            clothingOptionsView
                                .frame(maxHeight: 280)
                        }

                        // Action Buttons
                        actionButtonsView

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                }

                // Loading Overlay
                if isGenerating {
                    loadingOverlayView
                }
            }
            .navigationDestination(isPresented: $showingResult) {
                if let generatedImage = generatedImage {
                    ResultView(
                        generatedImage: generatedImage,
                        clothingType: selectedClothingType.rawValue,
                        fitStyle: selectedFitStyle.rawValue,
                        clothingState: selectedClothingState.rawValue,
                        onKeep: handleKeepPhoto,
                        onDiscard: handleDiscardPhoto
                    )
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .fullScreenCover(isPresented: $showingCameraPicker) {
                CameraPickerView(selectedImage: currentStepBinding)
                    .ignoresSafeArea()
            }
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
            .onChange(of: selectedPhotoItem) { oldValue, newValue in
                Task {
                    await loadPhotoFromPicker(newValue)
                }
            }
        }
    }

    // MARK: - Computed Properties
    private var currentStepBinding: Binding<UIImage?> {
        currentStep == .userPhoto ? $userPhoto : $clothingPhoto
    }

    private var currentStepPhoto: UIImage? {
        currentStep == .userPhoto ? userPhoto : clothingPhoto
    }

    private var canValidate: Bool {
        currentStepPhoto != nil
    }

    // MARK: - View Components

    private var stepIndicatorView: some View {
        HStack(spacing: 12) {
            // Step 1 Indicator
            Circle()
                .fill(currentStep == .userPhoto ? Color.accentColor : Color.secondary.opacity(0.3))
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                )

            // Connector Line
            Rectangle()
                .fill(currentStep == .clothingPhoto ? Color.accentColor : Color.secondary.opacity(0.3))
                .frame(height: 2)

            // Step 2 Indicator
            Circle()
                .fill(currentStep == .clothingPhoto ? Color.accentColor : Color.secondary.opacity(0.3))
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                )
        }
        .frame(maxWidth: 200)
    }

    private var instructionTextView: some View {
        VStack(spacing: 8) {
            Text(currentStep.title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Text(currentStep.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var photoPreviewView: some View {
        Group {
            if let photo = currentStepPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width - 48, height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            } else {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .frame(width: UIScreen.main.bounds.width - 48, height: 400)
                    .overlay(
                        VStack(spacing: 16) {
                            Image(systemName: currentStep.placeholderIcon)
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)

                            Text("No photo selected")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
                    )
            }
        }
    }

    private var clothingOptionsView: some View {
        VStack(spacing: 12) {
            // Clothing Type Menu
            Menu {
                ForEach(ClothingType.allCases, id: \.self) { type in
                    Button {
                        selectedClothingType = type
                    } label: {
                        Label(type.rawValue, systemImage: type.icon)
                    }
                }
            } label: {
                HStack {
                    Label("Type", systemImage: selectedClothingType.icon)
                        .font(.subheadline)
                    Spacer()
                    Text(selectedClothingType.rawValue)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Fit Style Menu
            Menu {
                ForEach(FitStyle.allCases, id: \.self) { style in
                    Button {
                        selectedFitStyle = style
                    } label: {
                        VStack(alignment: .leading) {
                            Text(style.rawValue)
                            Text(style.description)
                                .font(.caption)
                        }
                    }
                }
            } label: {
                HStack {
                    Label("Fit", systemImage: "ruler")
                        .font(.subheadline)
                    Spacer()
                    Text(selectedFitStyle.rawValue)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Clothing State Menu (conditional)
            if selectedClothingType.supportsOpenClosed {
                Menu {
                    ForEach(ClothingState.allCases, id: \.self) { state in
                        Button {
                            selectedClothingState = state
                        } label: {
                            VStack(alignment: .leading) {
                                Text(state.rawValue)
                                Text(state.description)
                                    .font(.caption)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Label("State", systemImage: "switch.2")
                            .font(.subheadline)
                        Spacer()
                        Text(selectedClothingState.rawValue)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            if currentStepPhoto == nil {
                // Camera and Gallery Buttons
                VStack(spacing: 12) {
                    // Camera Button
                    Button {
                        handleCameraButtonTap()
                    } label: {
                        Label("Take Photo", systemImage: "camera.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: showingCameraPicker)

                    // Gallery Button
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        Label("Gallery", systemImage: "photo.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: showingPhotoPicker)
                }
            } else if !showingClothingOptions {
                // Retake and Validate Buttons (before clothing options)
                HStack(spacing: 16) {
                    // Retake Button
                    Button {
                        handleRetake()
                    } label: {
                        Label("Retake", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: currentStepPhoto != nil)

                    // Validate Button
                    Button {
                        handleValidate()
                    } label: {
                        Label("Validate Photo", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.success, trigger: currentStep == .clothingPhoto)
                    .disabled(!canValidate)
                    .opacity(canValidate ? 1 : 0.6)
                }
            } else {
                // Generate and Cancel Buttons (after clothing options shown)
                VStack(spacing: 12) {
                    Button {
                        generateTryOn()
                    } label: {
                        Label("Generate Try-On", systemImage: "sparkles")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.success, trigger: isGenerating)

                    Button {
                        resetFlow()
                    } label: {
                        Label("Cancel & Restart", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var loadingOverlayView: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Generating your try-on...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(40)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Actions

    private func handleCameraButtonTap() {
        Task {
            let status = AVCaptureDevice.authorizationStatus(for: .video)

            switch status {
            case .authorized:
                await MainActor.run {
                    showingCameraPicker = true
                }
            case .notDetermined:
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                if granted {
                    await MainActor.run {
                        showingCameraPicker = true
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Camera access is required to take photos."
                        showingError = true
                    }
                }
            case .denied, .restricted:
                await MainActor.run {
                    errorMessage = "Camera access is required. Please enable it in Settings."
                    showingError = true
                }
            @unknown default:
                break
            }
        }
    }

    private func handleRetake() {
        if currentStep == .userPhoto {
            userPhoto = nil
        } else {
            clothingPhoto = nil
        }
    }

    private func handleValidate() {
        guard canValidate else { return }

        if currentStep == .userPhoto {
            // Move to clothing photo step
            currentStep = .clothingPhoto
        } else {
            // Both photos captured, show clothing options
            showingClothingOptions = true
        }
    }

    private func loadPhotoFromPicker(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    if currentStep == .userPhoto {
                        userPhoto = image
                    } else {
                        clothingPhoto = image
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load image from gallery."
                showingError = true
            }
        }
    }

    private func generateTryOn() {
        guard let userPhoto = userPhoto,
              let clothingPhoto = clothingPhoto else {
            errorMessage = "Both photos are required."
            showingError = true
            return
        }

        isGenerating = true

        Task {
            do {
                let geminiService = GeminiAPIService(apiKey: "AIzaSyD_5_pZEMrVNDqFMxF4RKwEcZC74r7tvVw")
                let result = try await geminiService.generateClothingVisualization(
                    personImage: userPhoto,
                    clothingImage: clothingPhoto,
                    clothingType: selectedClothingType,
                    fitStyle: selectedFitStyle,
                    clothingState: selectedClothingState
                )

                await MainActor.run {
                    generatedImage = result
                    isGenerating = false
                    showingResult = true
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }

    private func handleKeepPhoto() {
        // Photo was saved in ResultView, notify and reset
        NotificationCenter.default.post(name: NSNotification.Name("RefreshOutfits"), object: nil)
        resetFlow()
    }

    private func handleDiscardPhoto() {
        resetFlow()
    }

    private func resetFlow() {
        currentStep = .userPhoto
        userPhoto = nil
        clothingPhoto = nil
        generatedImage = nil
        showingResult = false
        showingClothingOptions = false
        selectedClothingType = .tshirt
        selectedFitStyle = .regular
        selectedClothingState = .closed
    }
}

// MARK: - Capture Step Enum
enum CaptureStep {
    case userPhoto
    case clothingPhoto

    var title: String {
        switch self {
        case .userPhoto:
            return "Take a photo of yourself"
        case .clothingPhoto:
            return "Take a photo of the clothing item"
        }
    }

    var subtitle: String {
        switch self {
        case .userPhoto:
            return "Make sure you're well-lit and facing the camera"
        case .clothingPhoto:
            return "Capture the full clothing item clearly"
        }
    }

    var placeholderIcon: String {
        switch self {
        case .userPhoto:
            return "person.fill"
        case .clothingPhoto:
            return "tshirt.fill"
        }
    }
}

// MARK: - Camera Picker View
struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView

        init(_ parent: CameraPickerView) {
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

// MARK: - Clothing Type Enum
enum ClothingType: String, CaseIterable {
    case tshirt = "T-Shirt"
    case shirt = "Shirt"
    case hoodie = "Hoodie"
    case jacket = "Jacket"
    case sweater = "Sweater"
    case dress = "Dress"
    case pants = "Pants"
    case shorts = "Shorts"
    case skirt = "Skirt"

    var icon: String {
        switch self {
        case .tshirt: return "tshirt.fill"
        case .shirt: return "shirt.fill"
        case .hoodie: return "figure.walk"
        case .jacket: return "figure.walk"
        case .sweater: return "tshirt.fill"
        case .dress: return "figure.stand.dress"
        case .pants: return "figure.walk"
        case .shorts: return "figure.walk"
        case .skirt: return "figure.stand.dress"
        }
    }

    var supportsOpenClosed: Bool {
        switch self {
        case .jacket, .hoodie, .shirt, .dress:
            return true
        default:
            return false
        }
    }
}

// MARK: - Fit Style Enum
enum FitStyle: String, CaseIterable {
    case tight = "Tight / Form-fitting"
    case regular = "Regular Fit"
    case relaxed = "Relaxed Fit"
    case oversize = "Oversized"

    var description: String {
        switch self {
        case .tight: return "Close to body, shows contours"
        case .regular: return "Standard comfortable fit"
        case .relaxed: return "Loose and comfortable"
        case .oversize: return "Very loose, street style"
        }
    }
}

// MARK: - Clothing State Enum
enum ClothingState: String, CaseIterable {
    case closed = "Closed"
    case open = "Open"

    var description: String {
        switch self {
        case .closed: return "Buttoned/Zipped up"
        case .open: return "Unbuttoned/Unzipped"
        }
    }
}

// MARK: - Preview
#Preview {
    CameraView()
}
