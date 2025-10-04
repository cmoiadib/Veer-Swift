import SwiftUI
import Foundation
import Supabase
import Combine

// MARK: - Try-On Outfit Model
struct TryOnOutfit: Codable, Identifiable {
    let id: UUID
    let userId: String
    let imageUrl: String
    let clothingType: String
    let fitStyle: String
    let clothingState: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case imageUrl = "image_url"
        case clothingType = "clothing_type"
        case fitStyle = "fit_style"
        case clothingState = "clothing_state"
        case createdAt = "created_at"
    }
}

// MARK: - Token Model
struct Token: Codable, Identifiable {
    let id: UUID
    let userId: String
    let tokenName: String
    let tokenValue: Double // Changed from Decimal to Double for Supabase compatibility
    let tokenType: String
    let description: String?
    let earnedDate: Date
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case tokenName = "token_name"
        case tokenValue = "token_value"
        case tokenType = "token_type"
        case description
        case earnedDate = "earned_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Computed properties for UI display
    var displayValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: tokenValue)) ?? "0"
    }

    var typeIcon: String {
        switch tokenType {
        case "style":
            return "sparkles"
        case "photo":
            return "camera.fill"
        case "daily":
            return "calendar"
        case "achievement":
            return "trophy.fill"
        case "social":
            return "heart.fill"
        default:
            return "star.fill"
        }
    }

    var typeColor: Color {
        switch tokenType {
        case "style":
            return .purple
        case "photo":
            return .blue
        case "daily":
            return .orange
        case "achievement":
            return .yellow
        case "social":
            return .pink
        default:
            return .gray
        }
    }
}

// MARK: - Supabase Manager
@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    @Published var tokens: [Token] = []
    @Published var outfits: [TryOnOutfit] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase: SupabaseClient

    private init() {
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: "https://pdhmakamlgsosiubivzk.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBkaG1ha2FtbGdzb3NpdWJpdnprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNzQ2OTYsImV4cCI6MjA3NDc1MDY5Nn0.XhO6vvsgzSkoPWToIH7VOUzKNeWG5Dwi9FkhG81jjTE"
        )
    }

    // MARK: - Token Operations

    /// Fetch tokens for a specific user
    func fetchTokens(for userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response: [Token] = try await supabase
                .from("tokens")
                .select()
                .eq("user_id", value: userId)
                .order("earned_date", ascending: false)
                .execute()
                .value

            self.tokens = response
        } catch {
            self.errorMessage = "Failed to fetch tokens: \(error.localizedDescription)"
            print("Supabase fetch error: \(error)")
        }

        isLoading = false
    }

    /// Fetch sample tokens for demo purposes
    func fetchSampleTokens() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: [Token] = try await supabase
                .from("tokens")
                .select()
                .eq("user_id", value: "sample_user_1")
                .order("earned_date", ascending: false)
                .execute()
                .value

            self.tokens = response
        } catch {
            self.errorMessage = "Failed to fetch sample tokens: \(error.localizedDescription)"
            print("Supabase fetch error: \(error)")
        }

        isLoading = false
    }

    /// Add a new token for a user
    func addToken(
        userId: String,
        name: String,
        value: Double,
        type: String,
        description: String? = nil
    ) async -> Bool {
        do {
            let newToken: [String: AnyJSON] = [
                "user_id": .string(userId),
                "token_name": .string(name),
                "token_value": .double(value),
                "token_type": .string(type),
                "description": .string(description ?? "")
            ]

            try await supabase
                .from("tokens")
                .insert(newToken)
                .execute()

            // Refresh tokens after adding
            await fetchTokens(for: userId)
            return true
        } catch {
            self.errorMessage = "Failed to add token: \(error.localizedDescription)"
            print("Supabase insert error: \(error)")
            return false
        }
    }

    /// Get total token value for a user
    func getTotalTokenValue(for userId: String) -> Double {
        return tokens.reduce(0) { $0 + $1.tokenValue }
    }

    /// Get tokens grouped by type
    func getTokensByType() -> [String: [Token]] {
        return Dictionary(grouping: tokens) { $0.tokenType }
    }

    // MARK: - Try-On Outfit Operations

    /// Fetch saved outfits for a specific user
    func fetchOutfits(for userId: String) async {
        do {
            let response: [TryOnOutfit] = try await supabase
                .from("try_on_outfits")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value

            await MainActor.run {
                // Force update by creating new array
                self.outfits = []
                self.outfits = response
                print("✅ Fetched \(response.count) outfits for user \(userId)")
            }
        } catch {
            print("❌ Failed to fetch outfits: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to load outfits"
            }
        }
    }

    /// Save a try-on outfit record to the database
    func saveTryOnOutfit(
        userId: String,
        imageUrl: String,
        clothingType: String,
        fitStyle: String,
        clothingState: String?
    ) async throws {
        let outfit: [String: AnyJSON] = [
            "user_id": .string(userId),
            "image_url": .string(imageUrl),
            "clothing_type": .string(clothingType),
            "fit_style": .string(fitStyle),
            "clothing_state": clothingState.map { .string($0) } ?? .null
        ]

        try await supabase
            .from("try_on_outfits")
            .insert(outfit)
            .execute()

        // Refresh outfits after saving
        await fetchOutfits(for: userId)
    }

    /// Delete an outfit
    func deleteOutfit(_ outfitId: UUID, userId: String) async throws {
        print("🗑️ Deleting outfit \(outfitId)")

        try await supabase
            .from("try_on_outfits")
            .delete()
            .eq("id", value: outfitId.uuidString)
            .execute()

        print("✅ Outfit deleted successfully")
    }

    // MARK: - Storage Operations

    /// Upload an image to Supabase Storage
    func uploadTryOnImage(_ image: UIImage, userId: String) async throws -> String {
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw SupabaseStorageError.imageConversionFailed
        }

        // Generate unique filename
        let timestamp = Date().timeIntervalSince1970
        let filename = "tryon_\(userId)_\(timestamp).jpg"
        let filePath = "try-on-images/\(filename)"

        do {
            try await supabase.storage
                .from("user-photos")
                .upload(
                    filePath,
                    data: imageData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "image/jpeg",
                        upsert: false
                    )
                )

            // Get public URL
            let publicURL = try supabase.storage
                .from("user-photos")
                .getPublicURL(path: filePath)

            return publicURL.absoluteString
        } catch {
            print("Supabase storage error: \(error)")
            throw SupabaseStorageError.uploadFailed(error.localizedDescription)
        }
    }
}

// MARK: - Supabase Storage Errors
enum SupabaseStorageError: Error, LocalizedError {
    case imageConversionFailed
    case uploadFailed(String)

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image for upload"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        }
    }
}

// MARK: - Environment Key
private struct SupabaseManagerKey: EnvironmentKey {
    static let defaultValue = SupabaseManager.shared
}

extension EnvironmentValues {
    var supabaseManager: SupabaseManager {
        get { self[SupabaseManagerKey.self] }
        set { self[SupabaseManagerKey.self] = newValue }
    }
}
