// ImageModel.swift
// VybeAI - Shock-Style Content Generator
//
// Created by JM Mahoro on 2025-03-26.
//

import SwiftUI

struct ImageModel: Identifiable {
    var id = UUID()
    var sourceImage: UIImage?
    var generatedImage: UIImage?
    var createdAt: Date = Date()
    var prompt: String = "Viral-style, ultra-realistic transformation"
    var status: GenerationStatus = .idle
    
    enum GenerationStatus: Equatable {
        case idle
        case uploading
        case processing
        case completed
        case failed(Error)
        
        var isLoading: Bool {
            switch self {
            case .uploading, .processing:
                return true
            default:
                return false
            }
        }
        
        var canDownload: Bool {
            if case .completed = self {
                return true
            }
            return false
        }
        
        // Implement Equatable
        static func == (lhs: GenerationStatus, rhs: GenerationStatus) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle):
                return true
            case (.uploading, .uploading):
                return true
            case (.processing, .processing):
                return true
            case (.completed, .completed):
                return true
            case (.failed, .failed):
                // Note: We're comparing the cases, not the associated values
                // This is sufficient for UI animations
                return true
            default:
                return false
            }
        }
    }
    
    var errorMessage: String? {
        if case .failed(let error) = status {
            return error.localizedDescription
        }
        return nil
    }
} 