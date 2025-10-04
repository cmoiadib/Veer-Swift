import SwiftUI
import Photos

struct HomeView: View {
    @State private var showingSettings = false
    @StateObject private var supabaseManager = SupabaseManager.shared
    @Environment(\.clerkManager) private var clerkManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var refreshID = UUID()

    var body: some View {
        NavigationStack {
            ZStack {
                // Glass-like translucent background
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Welcome Back Section
                        VStack(spacing: 12) {
                            Text("Welcome Back")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal)

                        // Recent Outfits Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Outfits")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.horizontal)

                            if supabaseManager.outfits.isEmpty {
                                // Empty State
                                VStack(spacing: 12) {
                                    Image(systemName: "tshirt")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.secondary)

                                    Text("No outfits yet")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    Text("Create your first try-on to see it here!")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 16) {
                                        ForEach(supabaseManager.outfits.prefix(10)) { outfit in
                                            OutfitCard(outfit: outfit, refreshID: refreshID)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // Token Summary Card
                        if !supabaseManager.tokens.isEmpty {
                            TokenSummaryCard(
                                totalValue: supabaseManager.tokens.reduce(0) { $0 + $1.tokenValue },
                                tokenCount: supabaseManager.tokens.count
                            )
                            .padding(.horizontal)
                        }

                        // Loading, Error, or Content States
                        if supabaseManager.isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Loading your tokens...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                        } else if let errorMessage = supabaseManager.errorMessage {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.title)
                                    .foregroundStyle(.orange)

                                Text("Unable to load tokens")
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)

                                Button("Retry") {
                                    loadData()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        } else if supabaseManager.tokens.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "star.circle")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.yellow)

                                Text("No Tokens Yet")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)

                                Text("Start taking photos and creating outfits to earn your first tokens!")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        } else {
                            // Group tokens by type
                            let groupedTokens = Dictionary(grouping: supabaseManager.tokens) { $0.tokenType }

                            LazyVStack(spacing: 20) {
                                // Style tokens
                                if let styleTokens = groupedTokens["style"], !styleTokens.isEmpty {
                                    TokenTypeSection(
                                        title: "Style Points",
                                        tokens: styleTokens,
                                        color: .purple,
                                        icon: "sparkles"
                                    )
                                    .padding(.horizontal)
                                }

                                // Photo tokens
                                if let photoTokens = groupedTokens["photo"], !photoTokens.isEmpty {
                                    TokenTypeSection(
                                        title: "Photo Rewards",
                                        tokens: photoTokens,
                                        color: .blue,
                                        icon: "camera.fill"
                                    )
                                    .padding(.horizontal)
                                }

                                // Achievement tokens
                                if let achievementTokens = groupedTokens["achievement"], !achievementTokens.isEmpty {
                                    TokenTypeSection(
                                        title: "Achievements",
                                        tokens: achievementTokens,
                                        color: .green,
                                        icon: "trophy.fill"
                                    )
                                    .padding(.horizontal)
                                }

                                // Other token types
                                ForEach(Array(groupedTokens.keys.sorted()), id: \.self) { type in
                                    if !["style", "photo", "achievement"].contains(type) {
                                        TokenTypeSection(
                                            title: type.capitalized,
                                            tokens: groupedTokens[type] ?? [],
                                            color: .orange,
                                            icon: "star.fill"
                                        )
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    loadData()
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                loadData()
            }
            .onChange(of: clerkManager.isAuthenticated) { oldValue, newValue in
                if newValue {
                    loadData()
                }
            }
            .onChange(of: supabaseManager.outfits.count) { oldValue, newValue in
                // Force refresh images when outfit count changes
                refreshID = UUID()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshOutfits"))) { _ in
                // Force refresh images when notification received
                refreshID = UUID()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                // Refresh when app becomes active
                if newPhase == .active {
                    loadData()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshOutfits"))) { _ in
                refreshID = UUID()
                loadData()
            }
            .task {
                // Initial load
                await loadDataAsync()
            }
        }
    }

    private func loadData() {
        guard let userId = clerkManager.user?.id else { return }
        Task {
            await loadDataAsync()
        }
    }

    private func loadDataAsync() async {
        guard let userId = clerkManager.user?.id else { return }
        await supabaseManager.fetchTokens(for: userId)
        await supabaseManager.fetchOutfits(for: userId)
    }
}

// MARK: - Outfit Card Component
struct OutfitCard: View {
    let outfit: TryOnOutfit
    let refreshID: UUID
    @State private var showingDetail = false

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            AsyncImage(url: URL(string: outfit.imageUrl + "?refresh=\(refreshID.uuidString)")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 200, height: 280)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                        .frame(width: 200, height: 280)
                @unknown default:
                    EmptyView()
                }
            }
            .id(refreshID)
            .overlay(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(outfit.clothingType)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(outfit.fitStyle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(8)
            }
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .sheet(isPresented: $showingDetail) {
            OutfitDetailView(outfit: outfit)
        }
    }
}

// MARK: - Outfit Detail View
struct OutfitDetailView: View {
    let outfit: TryOnOutfit
    @Environment(\.dismiss) private var dismiss
    @Environment(\.clerkManager) private var clerkManager
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var showingDeleteConfirmation = false
    @State private var isSavingToPhone = false
    @State private var showingSaveSuccess = false
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        AsyncImage(url: URL(string: outfit.imageUrl)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
                            default:
                                ProgressView()
                            }
                        }
                        .padding(.horizontal)

                        // Details
                        VStack(spacing: 12) {
                            DetailRow(label: "Type", value: outfit.clothingType)
                            DetailRow(label: "Fit", value: outfit.fitStyle)
                            if let state = outfit.clothingState {
                                DetailRow(label: "State", value: state)
                            }
                            DetailRow(label: "Created", value: formatDate(outfit.createdAt))
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                        // Action Buttons
                        VStack(spacing: 12) {
                            // Save to Phone Button
                            Button {
                                saveToPhone()
                            } label: {
                                if isSavingToPhone {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Label("Save to Phone", systemImage: "square.and.arrow.down")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(isSavingToPhone)

                            // Delete Button
                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Outfit", systemImage: "trash")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Outfit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .confirmationDialog("Delete this outfit?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    deleteOutfit()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
            }
            .alert("Saved!", isPresented: $showingSaveSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Photo saved to your Photos library")
            }
            .alert("Error", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveErrorMessage)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func saveToPhone() {
        isSavingToPhone = true

        Task {
            do {
                // Download image from URL
                guard let url = URL(string: outfit.imageUrl) else {
                    throw NSError(domain: "OutfitDetailView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image URL"])
                }

                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else {
                    throw NSError(domain: "OutfitDetailView", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
                }

                // Save to Photos
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }

                await MainActor.run {
                    isSavingToPhone = false
                    showingSaveSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSavingToPhone = false
                    saveErrorMessage = error.localizedDescription
                    showingSaveError = true
                }
            }
        }
    }

    private func deleteOutfit() {
        Task {
            do {
                guard let userId = await clerkManager.user?.id else { return }
                try await supabaseManager.deleteOutfit(outfit.id, userId: userId)

                // Immediately refresh the list
                await supabaseManager.fetchOutfits(for: userId)

                await MainActor.run {
                    // Notify HomeView to refresh UI
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshOutfits"), object: nil)
                    dismiss()
                }
            } catch {
                print("Failed to delete outfit: \(error)")
            }
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    HomeView()
}
