// ImageGenerationViewModel.swift
// VybeAI - Shock-Style Content Generator
//
// Created by JM Mahoro on 2025-03-26.
//

import SwiftUI
import Combine

class ImageGenerationViewModel: ObservableObject {
    // Published properties
    @Published var imageModel: ImageModel = ImageModel()
    @Published var showPaywall: Bool = false
    @Published var generatedImages: [ImageEntry] = []
    
    // Dependencies
    private let openAIService: OpenAIServiceProtocol
    private let imageCaptureService: ImageCaptureServiceProtocol
    private let subscriptionManager: SubscriptionManager
    private let historyManager = ImageHistoryManager()
    
    // Store cancellables
    private var cancellables = Set<AnyCancellable>()
    
    init(
        openAIService: OpenAIServiceProtocol,
        imageCaptureService: ImageCaptureServiceProtocol,
        subscriptionManager: SubscriptionManager
    ) {
        self.openAIService = openAIService
        self.imageCaptureService = imageCaptureService
        self.subscriptionManager = subscriptionManager
        
        // Load history when initializing
        loadHistory()
    }
    
    // Load history from history manager
    private func loadHistory() {
        Task {
            let entries = await historyManager.getImageEntries()
            DispatchQueue.main.async {
                self.generatedImages = entries
            }
        }
    }
    
    // Check if the user can generate an image
    func canGenerateImage() -> Bool {
        return subscriptionManager.canGenerateImages()
    }
    
    // Generate an image from the source image and prompt
    func generateImage() {
        // Check if there's a source image
        guard let sourceImage = imageModel.sourceImage else {
            imageModel.status = .failed(OpenAIError.invalidImage)
            return
        }
        
        // Check if the user can generate an image
        if !canGenerateImage() {
            showPaywall = true
            return
        }
        
        // Update status to uploading
        imageModel.status = .uploading
        
        // Generate the image using the OpenAI service
        openAIService.generateImage(from: sourceImage, with: imageModel.prompt)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.imageModel.status = .failed(error)
                    }
                },
                receiveValue: { [weak self] generatedImage in
                    guard let self = self else { return }
                    
                    // Update the image model
                    self.imageModel.generatedImage = generatedImage
                    self.imageModel.status = .completed
                    
                    // Add to history
                    self.addToHistory(image: generatedImage, prompt: self.imageModel.prompt, sourceImage: sourceImage)
                    
                    // Mark first free generation as used if using free tier
                    if self.subscriptionManager.currentSubscription == .free {
                        self.subscriptionManager.useFirstFreeGeneration()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // Add a generated image to history
    private func addToHistory(image: UIImage, prompt: String, sourceImage: UIImage) {
        // Add to in-memory array for immediate display
        let entry = ImageEntry(
            image: image,
            prompt: prompt,
            sourceImage: sourceImage
        )
        generatedImages.insert(entry, at: 0)
        
        // Persist to storage
        Task {
            await historyManager.saveImageToHistory(entry)
        }
    }
    
    // Save a generated image to history
    func saveToHistory(image: UIImage, prompt: String, sourceImage: UIImage? = nil) {
        // Add to in-memory array for immediate display
        let entry = ImageEntry(
            image: image,
            prompt: prompt,
            sourceImage: sourceImage
        )
        generatedImages.insert(entry, at: 0)
        
        // Persist to storage
        Task {
            await historyManager.saveImageToHistory(entry)
        }
    }
    
    // Remove a generated image from history
    func removeFromHistory(_ entry: ImageEntry) {
        Task {
            await historyManager.removeImageFromHistory(entry)
            await loadHistory()
        }
    }
    
    // Clear history
    func clearHistory() {
        Task {
            await historyManager.clearHistory()
            DispatchQueue.main.async {
                self.generatedImages = []
            }
        }
    }
    
    // Save the generated image to the photo library
    func saveGeneratedImage() async -> Result<Void, Error> {
        guard let generatedImage = imageModel.generatedImage else {
            return .failure(SaveError.noImageToSave)
        }
        
        do {
            try await imageCaptureService.saveImageToLibrary(generatedImage)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // Reset the generation state
    func resetGeneration() {
        imageModel = ImageModel()
    }
    
    // Custom errors
    enum SaveError: Error, LocalizedError {
        case noImageToSave
        
        var errorDescription: String? {
            switch self {
            case .noImageToSave:
                return "No image available to save"
            }
        }
    }
} 