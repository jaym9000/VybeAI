// OpenAIService.swift
// VybeAI - Shock-Style Content Generator
//
// Created by JM Mahoro on 2025-03-26.
//

import Foundation
import UIKit
import Combine

// Protocol for dependency injection and testability
protocol OpenAIServiceProtocol {
    func generateImage(from sourceImage: UIImage, with prompt: String) -> AnyPublisher<UIImage, Error>
    func generateImageFromText(prompt: String) -> AnyPublisher<UIImage, Error>
}

class OpenAIService: ObservableObject, OpenAIServiceProtocol {
    // Published property for any state changes that might need to be observed
    @Published var isGenerating = false
    
    private let baseURL = "https://api.openai.com/v1"
    private let apiKey: String
    
    // Use the API key from APIKeys.swift by default
    init(apiKey: String = APIKeys.openAI) {
        self.apiKey = apiKey
    }
    
    // Real implementation using the OpenAI API
    func generateImage(from sourceImage: UIImage, with prompt: String) -> AnyPublisher<UIImage, Error> {
        // Set generating state to true
        self.isGenerating = true
        
        return Future<UIImage, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(OpenAIError.unknownError))
                return
            }
            
            guard !self.apiKey.isEmpty else {
                promise(.failure(OpenAIError.invalidAPIKey))
                return
            }
            
            guard let imageData = sourceImage.jpegData(compressionQuality: 0.8) else {
                promise(.failure(OpenAIError.invalidImage))
                return
            }
            
            // For demo purposes, we'll simulate the API call if the API key is invalid
            // In a real app, replace this with actual API implementation
            if self.apiKey == "YOUR_API_KEY" || self.apiKey.isEmpty {
                self.simulateImageGeneration(sourceImage: sourceImage, prompt: prompt, completion: promise)
                return
            }
            
            // Create the URL request
            guard let url = URL(string: "\(baseURL)/images/edits") else {
                promise(.failure(OpenAIError.unknownError))
                return
            }
            
            // Create multipart form data
            let boundary = UUID().uuidString
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            // Build the request body
            var body = Data()
            
            // Add image file
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
            
            // Add model parameter (dall-e-3 is the latest model)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
            body.append("dall-e-3\r\n".data(using: .utf8)!)
            
            // Add prompt parameter
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(prompt)\r\n".data(using: .utf8)!)
            
            // Add size parameter (1024x1024 is standard for DALL-E 3)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"size\"\r\n\r\n".data(using: .utf8)!)
            body.append("1024x1024\r\n".data(using: .utf8)!)
            
            // Add n parameter (number of images to generate)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"n\"\r\n\r\n".data(using: .utf8)!)
            body.append("1\r\n".data(using: .utf8)!)
            
            // Close the body
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            
            // Make the request
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    if let httpResponse = response as? HTTPURLResponse {
                        switch httpResponse.statusCode {
                        case 401:
                            promise(.failure(OpenAIError.invalidAPIKey))
                        case 429:
                            promise(.failure(OpenAIError.rateLimitExceeded))
                        case 500...599:
                            promise(.failure(OpenAIError.serverError))
                        default:
                            promise(.failure(OpenAIError.unknownError))
                        }
                    } else {
                        promise(.failure(OpenAIError.unknownError))
                    }
                    return
                }
                
                guard let data = data else {
                    promise(.failure(OpenAIError.invalidResponse))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let dataArray = json["data"] as? [[String: Any]],
                       let firstImage = dataArray.first,
                       let imageURLString = firstImage["url"] as? String,
                       let imageURL = URL(string: imageURLString) {
                        
                        // Download the generated image
                        URLSession.shared.dataTask(with: imageURL) { imageData, imageResponse, imageError in
                            if let imageError = imageError {
                                promise(.failure(imageError))
                                return
                            }
                            
                            guard let imageData = imageData,
                                  let generatedImage = UIImage(data: imageData) else {
                                promise(.failure(OpenAIError.invalidResponse))
                                return
                            }
                            
                            promise(.success(generatedImage))
                        }.resume()
                        
                    } else {
                        promise(.failure(OpenAIError.invalidResponse))
                    }
                } catch {
                    promise(.failure(error))
                }
            }.resume()
        }
        .handleEvents(receiveCompletion: { [weak self] _ in
            // Reset generating state on completion
            DispatchQueue.main.async {
                self?.isGenerating = false
            }
        })
        .eraseToAnyPublisher()
    }
    
    // Text-to-image generation using DALL-E 3
    func generateImageFromText(prompt: String) -> AnyPublisher<UIImage, Error> {
        // Set generating state to true
        self.isGenerating = true
        
        return Future<UIImage, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(OpenAIError.unknownError))
                return
            }
            
            guard !self.apiKey.isEmpty else {
                promise(.failure(OpenAIError.invalidAPIKey))
                return
            }
            
            // For demo purposes, we'll simulate the API call if the API key is invalid
            // In a real app, replace this with actual API implementation
            if self.apiKey == "YOUR_API_KEY" || self.apiKey.isEmpty {
                self.simulateTextToImageGeneration(prompt: prompt, completion: promise)
                return
            }
            
            // Create the URL request
            guard let url = URL(string: "\(baseURL)/images/generations") else {
                promise(.failure(OpenAIError.unknownError))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Prepare the request body with DALL-E 3 parameters
            let requestBody: [String: Any] = [
                "model": "dall-e-3", // Using DALL-E 3, which is the latest version
                "prompt": prompt,
                "n": 1, // DALL-E 3 only supports 1 image at a time
                "size": "1024x1024", // Standard size for DALL-E 3
                "quality": "hd", // HD quality for better results
                "style": "vivid", // Vivid style for more vibrant, dramatic images
                "response_format": "url"
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            } catch {
                promise(.failure(error))
                return
            }
            
            // Make the request
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    if let httpResponse = response as? HTTPURLResponse {
                        switch httpResponse.statusCode {
                        case 401:
                            promise(.failure(OpenAIError.invalidAPIKey))
                        case 429:
                            promise(.failure(OpenAIError.rateLimitExceeded))
                        case 500...599:
                            promise(.failure(OpenAIError.serverError))
                        default:
                            if let data = data,
                               let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let error = errorJson["error"] as? [String: Any],
                               let message = error["message"] as? String {
                                promise(.failure(OpenAIError.apiError(message)))
                            } else {
                                promise(.failure(OpenAIError.unknownError))
                            }
                        }
                    } else {
                        promise(.failure(OpenAIError.unknownError))
                    }
                    return
                }
                
                guard let data = data else {
                    promise(.failure(OpenAIError.invalidResponse))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let dataArray = json["data"] as? [[String: Any]],
                       let firstImage = dataArray.first,
                       let imageURLString = firstImage["url"] as? String,
                       let imageURL = URL(string: imageURLString) {
                        
                        // Download the generated image
                        URLSession.shared.dataTask(with: imageURL) { imageData, imageResponse, imageError in
                            if let imageError = imageError {
                                promise(.failure(imageError))
                                return
                            }
                            
                            guard let imageData = imageData,
                                  let generatedImage = UIImage(data: imageData) else {
                                promise(.failure(OpenAIError.invalidResponse))
                                return
                            }
                            
                            promise(.success(generatedImage))
                        }.resume()
                        
                    } else {
                        promise(.failure(OpenAIError.invalidResponse))
                    }
                } catch {
                    promise(.failure(error))
                }
            }.resume()
        }
        .handleEvents(receiveCompletion: { [weak self] _ in
            // Reset generating state on completion
            DispatchQueue.main.async {
                self?.isGenerating = false
            }
        })
        .eraseToAnyPublisher()
    }
    
    // Simulate image generation for demo purposes
    // Replace this with actual API calls in production
    private func simulateImageGeneration(sourceImage: UIImage, prompt: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // For demonstration, apply a simple filter to the source image
            if let processedImage = self.applyDemoFilter(to: sourceImage) {
                completion(.success(processedImage))
            } else {
                completion(.failure(OpenAIError.unknownError))
            }
        }
    }
    
    // Simulate text-to-image generation for demo purposes
    private func simulateTextToImageGeneration(prompt: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // For demo purposes, generate a simple image based on the prompt
            if let generatedImage = self.generateDemoImage(for: prompt) {
                completion(.success(generatedImage))
            } else {
                completion(.failure(OpenAIError.unknownError))
            }
        }
    }
    
    // Simple filter for demo purposes
    private func applyDemoFilter(to image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let context = CIContext()
        
        // Apply a combination of filters for a dramatic effect
        // 1. Apply a vignette
        let vignetteFilter = CIFilter(name: "CIVignette")
        vignetteFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        vignetteFilter?.setValue(0.8, forKey: kCIInputIntensityKey)
        vignetteFilter?.setValue(1.0, forKey: kCIInputRadiusKey)
        
        guard let outputImage1 = vignetteFilter?.outputImage else { return nil }
        
        // 2. Adjust colors
        let colorFilter = CIFilter(name: "CIColorControls")
        colorFilter?.setValue(outputImage1, forKey: kCIInputImageKey)
        colorFilter?.setValue(1.2, forKey: kCIInputSaturationKey)
        colorFilter?.setValue(0.1, forKey: kCIInputContrastKey)
        
        guard let outputImage2 = colorFilter?.outputImage else { return nil }
        
        // 3. Add a sharpening filter
        let sharpenFilter = CIFilter(name: "CISharpenLuminance")
        sharpenFilter?.setValue(outputImage2, forKey: kCIInputImageKey)
        sharpenFilter?.setValue(0.5, forKey: kCIInputSharpnessKey)
        
        guard let finalOutput = sharpenFilter?.outputImage,
              let cgImage = context.createCGImage(finalOutput, from: finalOutput.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    // Generate a demo image based on text prompt
    private func generateDemoImage(for prompt: String) -> UIImage? {
        let size = CGSize(width: 1024, height: 1024)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Extract keywords from prompt to determine colors
            let lowercasePrompt = prompt.lowercased()
            
            // Background color based on prompt theme
            var backgroundColor: UIColor
            var foregroundColor: UIColor
            
            if lowercasePrompt.contains("sunset") || lowercasePrompt.contains("orange") || lowercasePrompt.contains("warm") {
                backgroundColor = UIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0)
                foregroundColor = UIColor(red: 0.8, green: 0.3, blue: 0.1, alpha: 1.0)
            } else if lowercasePrompt.contains("ocean") || lowercasePrompt.contains("blue") || lowercasePrompt.contains("water") {
                backgroundColor = UIColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1.0)
                foregroundColor = UIColor(red: 0.1, green: 0.3, blue: 0.7, alpha: 1.0)
            } else if lowercasePrompt.contains("forest") || lowercasePrompt.contains("green") || lowercasePrompt.contains("nature") {
                backgroundColor = UIColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1.0)
                foregroundColor = UIColor(red: 0.1, green: 0.5, blue: 0.2, alpha: 1.0)
            } else if lowercasePrompt.contains("night") || lowercasePrompt.contains("dark") || lowercasePrompt.contains("space") {
                backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1.0)
                foregroundColor = UIColor(red: 0.3, green: 0.3, blue: 0.6, alpha: 1.0)
            } else if lowercasePrompt.contains("fire") || lowercasePrompt.contains("red") || lowercasePrompt.contains("hot") {
                backgroundColor = UIColor(red: 0.9, green: 0.3, blue: 0.2, alpha: 1.0)
                foregroundColor = UIColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 1.0)
            } else {
                // Default to purple gradient for other concepts
                backgroundColor = UIColor(red: 0.5, green: 0.3, blue: 0.9, alpha: 1.0)
                foregroundColor = UIColor(red: 0.3, green: 0.1, blue: 0.7, alpha: 1.0)
            }
            
            // Draw gradient background
            let rectanglePath = UIBezierPath(rect: CGRect(origin: .zero, size: size))
            context.cgContext.saveGState()
            rectanglePath.addClip()
            
            let colors = [backgroundColor.cgColor, foregroundColor.cgColor]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colorLocations: [CGFloat] = [0.0, 1.0]
            
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations) {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }
            
            context.cgContext.restoreGState()
            
            // Draw some shapes based on the prompt
            let numberOfShapes = 30
            for i in 0..<numberOfShapes {
                let shapeSize = CGFloat.random(in: 20...150)
                let x = CGFloat.random(in: 0...(size.width - shapeSize))
                let y = CGFloat.random(in: 0...(size.height - shapeSize))
                
                let opacity = CGFloat.random(in: 0.1...0.7)
                let shapeColor = UIColor.white.withAlphaComponent(opacity)
                
                // Determine shape type based on prompt
                if lowercasePrompt.contains("circle") || lowercasePrompt.contains("round") || i % 3 == 0 {
                    // Draw circle
                    let circlePath = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: shapeSize, height: shapeSize))
                    shapeColor.setFill()
                    circlePath.fill()
                } else if lowercasePrompt.contains("square") || lowercasePrompt.contains("box") || i % 3 == 1 {
                    // Draw square
                    let squarePath = UIBezierPath(rect: CGRect(x: x, y: y, width: shapeSize, height: shapeSize))
                    shapeColor.setFill()
                    squarePath.fill()
                } else {
                    // Draw triangle
                    let trianglePath = UIBezierPath()
                    trianglePath.move(to: CGPoint(x: x + shapeSize/2, y: y))
                    trianglePath.addLine(to: CGPoint(x: x, y: y + shapeSize))
                    trianglePath.addLine(to: CGPoint(x: x + shapeSize, y: y + shapeSize))
                    trianglePath.close()
                    
                    shapeColor.setFill()
                    trianglePath.fill()
                }
            }
            
            // Add a simple text representation
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8),
                .paragraphStyle: paragraphStyle
            ]
            
            // Truncate the prompt if it's too long
            let displayPrompt = prompt.count > 50 ? prompt.prefix(50) + "..." : prompt
            let attributedString = NSAttributedString(string: "AI Image: \(displayPrompt)", attributes: attrs)
            attributedString.draw(with: CGRect(x: 20, y: size.height - 100, width: size.width - 40, height: 80), options: .usesLineFragmentOrigin, context: nil)
        }
    }
}

// OpenAI API errors
enum OpenAIError: Error, LocalizedError {
    case invalidAPIKey
    case invalidImage
    case invalidResponse
    case rateLimitExceeded
    case serverError
    case unknownError
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your OpenAI API key."
        case .invalidImage:
            return "The source image is invalid."
        case .invalidResponse:
            return "Invalid response from the API."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .serverError:
            return "Server error. Please try again later."
        case .unknownError:
            return "An unknown error occurred."
        case .apiError(let message):
            return message
        }
    }
} 