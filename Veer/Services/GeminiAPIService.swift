import Foundation
import UIKit

// Import types from CameraView
// These enums are defined in CameraView.swift and used here for type safety
// If you refactor, consider moving these to a shared Models file

// MARK: - Gemini API Service
class GeminiAPIService {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - Generate Content with Images
    func generateClothingVisualization(
        personImage: UIImage,
        clothingImage: UIImage,
        clothingType: ClothingType,
        fitStyle: FitStyle,
        clothingState: ClothingState
    ) async throws -> UIImage {
        return try await performRequestWithRetry(
            personImage: personImage,
            clothingImage: clothingImage,
            clothingType: clothingType,
            fitStyle: fitStyle,
            clothingState: clothingState
        )
    }

    // MARK: - Private Methods
    private func performRequestWithRetry(
        personImage: UIImage,
        clothingImage: UIImage,
        clothingType: ClothingType,
        fitStyle: FitStyle,
        clothingState: ClothingState,
        attempt: Int = 1
    ) async throws -> UIImage {
        let maxRetries = 3
        let baseDelay: TimeInterval = 1.0

        do {
            return try await performSingleRequest(
                personImage: personImage,
                clothingImage: clothingImage,
                clothingType: clothingType,
                fitStyle: fitStyle,
                clothingState: clothingState
            )
        } catch GeminiAPIError.httpError(let statusCode) {
            // Retry for temporary errors (503, 429, 502, 504)
            if attempt < maxRetries && [503, 429, 502, 504].contains(statusCode) {
                let delay = baseDelay * pow(2.0, Double(attempt - 1)) // Exponential backoff
                print("Gemini API error \(statusCode), retrying in \(delay) seconds... (attempt \(attempt)/\(maxRetries))")

                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await performRequestWithRetry(
                    personImage: personImage,
                    clothingImage: clothingImage,
                    clothingType: clothingType,
                    fitStyle: fitStyle,
                    clothingState: clothingState,
                    attempt: attempt + 1
                )
            } else {
                throw GeminiAPIError.httpError(statusCode)
            }
        } catch {
            // For other errors, don't retry
            throw error
        }
    }

    private func performSingleRequest(
        personImage: UIImage,
        clothingImage: UIImage,
        clothingType: ClothingType,
        fitStyle: FitStyle,
        clothingState: ClothingState
    ) async throws -> UIImage {
        // Convert images to base64 with reduced quality to avoid size limits
        guard let personImageData = personImage.jpegData(compressionQuality: 0.5),
              let clothingImageData = clothingImage.jpegData(compressionQuality: 0.5) else {
            throw GeminiAPIError.imageProcessingFailed
        }

        // Check image sizes (Gemini has limits around 4MB per image)
        print("Person image size: \(personImageData.count / 1024) KB")
        print("Clothing image size: \(clothingImageData.count / 1024) KB")

        let personBase64 = personImageData.base64EncodedString()
        let clothingBase64 = clothingImageData.base64EncodedString()

        // Generate dynamic prompt based on selections
        let fitStyleDescription = generateFitStyleDescription(fitStyle)
        let clothingTypeDescription = clothingType.rawValue.lowercased()
        let stateDescription = generateClothingStateDescription(clothingType, clothingState)

        // Create the request payload for image generation
        let requestBody = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [
                        GeminiPart.text("""
                        Create a photorealistic image showing the person from the first image wearing the \(clothingTypeDescription) from the second image.

                        Clothing Type: \(clothingType.rawValue)
                        Fit Style: \(fitStyle.rawValue)
                        State: \(clothingState.rawValue)

                        Instructions:
                        1. Analyze the person's body position, lighting, and proportions in the first image
                        2. Take the \(clothingTypeDescription) from the second image and fit it onto the person
                        3. Apply a \(fitStyle.rawValue.lowercased()) fit: \(fitStyleDescription)
                        4. \(stateDescription)
                        5. Adjust the clothing's size, perspective, and lighting to match the person's photo
                        6. Ensure the clothing drapes and fits according to the specified fit style
                        7. Maintain the original background and lighting of the person's photo
                        8. Generate a high-quality, photorealistic composite image

                        Important: The fit should be \(fitStyle.rawValue.lowercased()) - \(fitStyleDescription)

                        Return only the final composite image showing the person wearing the clothing.
                        """),
                        GeminiPart.image(mimeType: "image/jpeg", data: personBase64),
                        GeminiPart.image(mimeType: "image/jpeg", data: clothingBase64)
                    ]
                )
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.4,
                topK: 32,
                topP: 1,
                maxOutputTokens: 4096
            )
        )

        // Create URL request
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90.0 // Increase timeout for large image processing

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            request.httpBody = try encoder.encode(requestBody)

            // Debug: Print request size
            if let bodySize = request.httpBody?.count {
                print("Request body size: \(bodySize / 1024) KB")
            }
        } catch {
            print("Encoding error: \(error)")
            throw GeminiAPIError.encodingFailed
        }

        // Send the request
        print("Sending request to: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiAPIError.invalidResponse
        }

        print("Response status code: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            // Try to decode error response
            if let errorString = String(data: data, encoding: .utf8) {
                print("Error response body: \(errorString)")
            }
            throw GeminiAPIError.httpError(httpResponse.statusCode)
        }

        // Parse the response
        do {
            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

            // Extract the generated image from the response using the correct path
            if let candidate = geminiResponse.candidates.first,
               let part = candidate.content.parts.first,
               let inlineData = part.inlineData {

                // Decode the base64 image data
                guard let imageData = Data(base64Encoded: inlineData.data),
                      let generatedImage = UIImage(data: imageData) else {
                    throw GeminiAPIError.imageDecodingFailed
                }

                return generatedImage

            } else {
                // If no image is returned, throw an error
                throw GeminiAPIError.noImageInResponse
            }

        } catch let decodingError as DecodingError {
            print("Decoding error details: \(decodingError)")
            throw GeminiAPIError.decodingFailed
        } catch {
            print("General parsing error: \(error)")
            throw GeminiAPIError.decodingFailed
        }
    }
}

// MARK: - Helper Functions
extension GeminiAPIService {
    private func generateFitStyleDescription(_ fitStyle: FitStyle) -> String {
        switch fitStyle {
        case .tight:
            return "the clothing should hug the body closely, showing the body's contours and silhouette. Minimal fabric bunching or looseness."
        case .regular:
            return "the clothing should fit comfortably with a standard amount of room. Not too tight, not too loose - just right for everyday wear."
        case .relaxed:
            return "the clothing should be loose and comfortable with extra room throughout. The fabric should drape naturally with some slack."
        case .oversize:
            return "the clothing should be significantly oversized with plenty of extra fabric. Think street style - loose, baggy, and intentionally large. The garment should hang well past normal fitting points."
        }
    }

    private func generateClothingStateDescription(_ type: ClothingType, _ state: ClothingState) -> String {
        guard type.supportsOpenClosed else { return "" }

        switch state {
        case .closed:
            switch type {
            case .jacket, .hoodie:
                return "The garment should be fully zipped up and closed."
            case .shirt, .dress:
                return "The garment should be fully buttoned up and closed."
            default:
                return "The garment should be closed."
            }
        case .open:
            switch type {
            case .jacket, .hoodie:
                return "The garment should be unzipped and open, showing what's underneath."
            case .shirt, .dress:
                return "The garment should be unbuttoned and open, showing what's underneath."
            default:
                return "The garment should be open."
            }
        }
    }

    private func createPlaceholderImage(with text: String) -> UIImage {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Set background color
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Set text attributes
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ]

            // Draw text
            let textRect = CGRect(x: 20, y: 20, width: size.width - 40, height: size.height - 40)
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
}

// MARK: - Gemini API Models
struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

enum GeminiPart: Codable {
    case text(String)
    case image(mimeType: String, data: String)

    enum CodingKeys: String, CodingKey {
        case text
        case inlineData = "inline_data"
    }

    enum InlineDataKeys: String, CodingKey {
        case mimeType = "mime_type"
        case data
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let text):
            try container.encode(text, forKey: .text)
        case .image(let mimeType, let data):
            var inlineDataContainer = container.nestedContainer(keyedBy: InlineDataKeys.self, forKey: .inlineData)
            try inlineDataContainer.encode(mimeType, forKey: .mimeType)
            try inlineDataContainer.encode(data, forKey: .data)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let text = try? container.decode(String.self, forKey: .text) {
            self = .text(text)
        } else if let inlineDataContainer = try? container.nestedContainer(keyedBy: InlineDataKeys.self, forKey: .inlineData) {
            let mimeType = try inlineDataContainer.decode(String.self, forKey: .mimeType)
            let data = try inlineDataContainer.decode(String.self, forKey: .data)
            self = .image(mimeType: mimeType, data: data)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid GeminiPart"))
        }
    }
}

struct GeminiGenerationConfig: Codable {
    let temperature: Double
    let topK: Int
    let topP: Double
    let maxOutputTokens: Int
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Codable {
    let content: GeminiResponseContent
}

struct GeminiResponseContent: Codable {
    let parts: [GeminiResponsePart]
}

struct GeminiResponsePart: Codable {
    let inlineData: GeminiInlineData?
}

struct GeminiInlineData: Codable {
    let mimeType: String
    let data: String
}

// MARK: - Gemini API Errors
enum GeminiAPIError: Error, LocalizedError {
    case invalidURL
    case imageProcessingFailed
    case encodingFailed
    case invalidResponse
    case httpError(Int)
    case decodingFailed
    case imageDecodingFailed
    case noImageInResponse
    case noTextInResponse
    case serviceUnavailable
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .imageProcessingFailed:
            return "Failed to process images"
        case .encodingFailed:
            return "Failed to encode request"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            switch code {
            case 400:
                return "Invalid request (400). The API endpoint or request format may be incorrect. Check the console logs for details."
            case 503:
                return "Service temporarily unavailable. Please try again in a moment."
            case 429:
                return "Too many requests. Please wait a moment and try again."
            case 502, 504:
                return "Server temporarily unavailable. Please try again."
            default:
                return "HTTP error: \(code)"
            }
        case .decodingFailed:
            return "Failed to decode response"
        case .imageDecodingFailed:
            return "Failed to decode generated image"
        case .noImageInResponse:
            return "No image found in API response"
        case .noTextInResponse:
            return "No text found in API response"
        case .serviceUnavailable:
            return "The AI service is temporarily unavailable. Please try again later."
        case .rateLimited:
            return "Too many requests. Please wait a moment before trying again."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .httpError(let code) where [503, 429, 502, 504].contains(code):
            return "This is usually temporary. The app will automatically retry."
        case .serviceUnavailable, .rateLimited:
            return "Please wait a moment and try again."
        default:
            return nil
        }
    }
}
