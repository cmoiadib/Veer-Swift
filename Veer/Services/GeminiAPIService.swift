import Foundation
import UIKit

// MARK: - Gemini API Service
class GeminiAPIService {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Generate Content with Images
    func generateClothingVisualization(personImage: UIImage, clothingImage: UIImage) async throws -> UIImage {
        return try await performRequestWithRetry(personImage: personImage, clothingImage: clothingImage)
    }
    
    // MARK: - Private Methods
    private func performRequestWithRetry(personImage: UIImage, clothingImage: UIImage, attempt: Int = 1) async throws -> UIImage {
        let maxRetries = 3
        let baseDelay: TimeInterval = 1.0
        
        do {
            return try await performSingleRequest(personImage: personImage, clothingImage: clothingImage)
        } catch GeminiAPIError.httpError(let statusCode) {
            // Retry for temporary errors (503, 429, 502, 504)
            if attempt < maxRetries && [503, 429, 502, 504].contains(statusCode) {
                let delay = baseDelay * pow(2.0, Double(attempt - 1)) // Exponential backoff
                print("Gemini API error \(statusCode), retrying in \(delay) seconds... (attempt \(attempt)/\(maxRetries))")
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await performRequestWithRetry(personImage: personImage, clothingImage: clothingImage, attempt: attempt + 1)
            } else {
                throw GeminiAPIError.httpError(statusCode)
            }
        } catch {
            // For other errors, don't retry
            throw error
        }
    }
    
    private func performSingleRequest(personImage: UIImage, clothingImage: UIImage) async throws -> UIImage {
        // Convert images to base64
        guard let personImageData = personImage.jpegData(compressionQuality: 0.8),
              let clothingImageData = clothingImage.jpegData(compressionQuality: 0.8) else {
            throw GeminiAPIError.imageProcessingFailed
        }
        
        let personBase64 = personImageData.base64EncodedString()
        let clothingBase64 = clothingImageData.base64EncodedString()
        
        // Create the request payload for image generation
        let requestBody = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [
                        GeminiPart.text("""
                        Create a photorealistic image showing the person from the first image wearing the clothing item from the second image. 
                        
                        Instructions:
                        1. Analyze the person's body position, lighting, and proportions in the first image
                        2. Take the clothing item from the second image and fit it naturally onto the person
                        3. Adjust the clothing's size, perspective, and lighting to match the person's photo
                        4. Ensure the clothing looks realistic and properly fitted
                        5. Maintain the original background and lighting of the person's photo
                        6. Generate a high-quality, photorealistic composite image
                        
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
        request.timeoutInterval = 60.0 // Increase timeout for large image processing
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw GeminiAPIError.encodingFailed
        }
        
        // Send the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
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