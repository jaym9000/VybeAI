// ChatToImageViewModel.swift
// VybeAI
//
// Created by JM Mahoro on 2025-03-26.
//

import SwiftUI
import Combine
import Speech

// Message model for chat
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    var image: UIImage?
    let timestamp = Date()
}

class ChatToImageViewModel: ObservableObject {
    // Published properties
    @Published var messages: [ChatMessage] = []
    @Published var isGenerating = false
    @Published var isListening = false
    @Published var errorMessage = "Failed to generate image. Please try again."
    
    // Services
    private let openAIService: OpenAIServiceProtocol
    
    // Speech recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Store cancellables
    private var cancellables = Set<AnyCancellable>()
    
    init(openAIService: OpenAIServiceProtocol = OpenAIService()) {
        self.openAIService = openAIService
    }
    
    // Send a message and generate an image
    func sendMessage(_ text: String) {
        // Add user message
        let userMessage = ChatMessage(text: text, isFromUser: true)
        messages.append(userMessage)
        
        // Start generating
        isGenerating = true
        
        // Add AI response with generated image
        openAIService.generateImageFromText(prompt: text)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isGenerating = false
                },
                receiveValue: { [weak self] generatedImage in
                    guard let self = self else { return }
                    
                    // Add AI response with the generated image
                    let aiMessage = ChatMessage(
                        text: "Here's your generated image based on: \"\(text)\"",
                        isFromUser: false,
                        image: generatedImage
                    )
                    self.messages.append(aiMessage)
                }
            )
            .store(in: &cancellables)
    }
    
    // Voice recognition for hands-free operation
    func startVoiceRecognition() {
        // Check authorization status
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                guard status == .authorized else {
                    return
                }
                
                self.recognizeVoice()
            }
        }
    }
    
    func stopVoiceRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
    }
    
    private func recognizeVoice() {
        // Cancel existing recognition task
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // Set up audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }
        
        // Create and configure the speech recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Create a recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                let recognizedText = result.bestTranscription.formattedString
                isFinal = result.isFinal
                
                if isFinal && !recognizedText.isEmpty {
                    DispatchQueue.main.async {
                        self.stopVoiceRecognition()
                        self.sendMessage(recognizedText)
                    }
                }
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isListening = false
            }
        }
        
        // Configure the audio input
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start recording
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
        } catch {
            isListening = false
        }
    }
} 