import SwiftUI
import Photos

// MARK: - Result View
struct ResultView: View {
    // MARK: - Properties
    let generatedImage: UIImage
    let clothingType: String
    let fitStyle: String
    let clothingState: String
    let onKeep: () -> Void
    let onDiscard: () -> Void

    // MARK: - State
    @State private var showingSaveSuccess = false
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    @State private var isSaving = false
    @State private var saveSuccessMessage = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.clerkManager) private var clerkManager
    @StateObject private var supabaseManager = SupabaseManager.shared

    var body: some View {
        ZStack {
            // Background
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Generated Image
                generatedImageView
                    .padding(.horizontal, 24)

                Spacer()
                    .frame(maxHeight: 40)

                // Action Buttons
                actionButtonsView
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }

            // Saving Overlay
            if isSaving {
                savingOverlayView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Try-On Result")
                    .font(.headline)
            }

            ToolbarItem(placement: .topBarLeading) {
                Button {
                    onDiscard()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .alert("Success!", isPresented: $showingSaveSuccess) {
            Button("OK") {
                if saveSuccessMessage.contains("cloud") {
                    onKeep()
                    dismiss()
                }
            }
        } message: {
            Text(saveSuccessMessage)
        }
        .alert("Save Error", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
        }
    }

    // MARK: - View Components

    private var generatedImageView: some View {
        Image(uiImage: generatedImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
    }

    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            // Keep Photo Button (Primary Action)
            Button {
                handleKeepPhoto()
            } label: {
                Label("Keep Photo", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .sensoryFeedback(.success, trigger: showingSaveSuccess)

            // Save to Phone Button
            Button {
                handleSaveToPhone()
            } label: {
                Label("Save to Phone", systemImage: "square.and.arrow.down")
                    .font(.headline)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .sensoryFeedback(.success, trigger: showingSaveSuccess)

            // Discard Button
            Button(role: .destructive) {
                onDiscard()
                dismiss()
            } label: {
                Label("Discard", systemImage: "trash")
                    .font(.headline)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .sensoryFeedback(.warning, trigger: showingSaveError)
        }
    }

    private var savingOverlayView: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)

                Text("Saving...")
                    .font(.headline)
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
    }

    // MARK: - Actions

    private func handleKeepPhoto() {
        isSaving = true

        Task {
            do {
                // Get actual user ID from Clerk authentication
                guard let userId = clerkManager.user?.id else {
                    await MainActor.run {
                        isSaving = false
                        saveErrorMessage = "You must be signed in to save photos to the cloud."
                        showingSaveError = true
                    }
                    return
                }

                // Upload to Supabase cloud storage
                let imageURL = try await supabaseManager.uploadTryOnImage(generatedImage, userId: userId)

                // Save outfit metadata to database
                try await supabaseManager.saveTryOnOutfit(
                    userId: userId,
                    imageUrl: imageURL,
                    clothingType: clothingType,
                    fitStyle: fitStyle,
                    clothingState: clothingState
                )

                // Immediately fetch the updated list
                if let userId = clerkManager.user?.id {
                    await supabaseManager.fetchOutfits(for: userId)
                }

                await MainActor.run {
                    // Notify HomeView to refresh
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshOutfits"), object: nil)

                    isSaving = false
                    saveSuccessMessage = "Your try-on result has been saved to the cloud!"
                    showingSaveSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveErrorMessage = "Failed to save to cloud: \(error.localizedDescription)"
                    showingSaveError = true
                }
            }
        }
    }

    private func handleSaveToPhone() {
        isSaving = true

        Task {
            // Request Photos permission and save
            let status = await requestPhotosPermission()

            switch status {
            case .authorized, .limited:
                do {
                    try await saveToPhotos()
                    await MainActor.run {
                        isSaving = false
                        saveSuccessMessage = "Photo saved to your Photos library!"
                        showingSaveSuccess = true
                    }
                } catch {
                    await MainActor.run {
                        isSaving = false
                        saveErrorMessage = "Failed to save photo: \(error.localizedDescription)"
                        showingSaveError = true
                    }
                }

            case .denied, .restricted:
                await MainActor.run {
                    isSaving = false
                    saveErrorMessage = "Photos access is required to save images. Please enable it in Settings."
                    showingSaveError = true
                }

            case .notDetermined:
                await MainActor.run {
                    isSaving = false
                    saveErrorMessage = "Unable to determine Photos access status."
                    showingSaveError = true
                }

            @unknown default:
                await MainActor.run {
                    isSaving = false
                    saveErrorMessage = "Unknown permission status."
                    showingSaveError = true
                }
            }
        }
    }

    private func requestPhotosPermission() async -> PHAuthorizationStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        if status == .notDetermined {
            return await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }

        return status
    }

    private func saveToPhotos() async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: generatedImage)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ResultView(
            generatedImage: UIImage(systemName: "photo.fill")!.withTintColor(.blue, renderingMode: .alwaysOriginal),
            clothingType: "T-Shirt",
            fitStyle: "Regular",
            clothingState: "Closed",
            onKeep: {},
            onDiscard: {}
        )
    }
}
