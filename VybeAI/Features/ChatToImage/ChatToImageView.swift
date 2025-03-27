// ChatToImageView.swift
// VybeAI
//
// Created by JM Mahoro on 2025-03-26.
//

import SwiftUI
import AVFoundation

struct ChatToImageView: View {
    @StateObject private var viewModel: ChatToImageViewModel
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var prompt: String = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var showPaywall = false
    @State private var showGenerationFailedAlert = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var scrollViewID = UUID()
    
    // Inject the OpenAIService
    init(openAIService: OpenAIServiceProtocol) {
        _viewModel = StateObject(wrappedValue: ChatToImageViewModel(openAIService: openAIService))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Enhanced background gradient
                LinearGradient(
                    gradient: Gradient(
                        colors: colorScheme == .dark ?
                            [Color(hex: "1A1A2E"), Color(hex: "16213E")] :
                            [Color(hex: "F0F4FF"), Color(hex: "E6EEFF")]
                    ),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Animated background elements
                GeometryReader { geo in
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: geo.size.width * 0.7, height: geo.size.width * 0.7)
                            .blur(radius: 30)
                            .offset(x: -geo.size.width * 0.2, y: -geo.size.height * 0.1)
                        
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: geo.size.width * 0.6, height: geo.size.width * 0.6)
                            .blur(radius: 25)
                            .offset(x: geo.size.width * 0.3, y: geo.size.height * 0.3)
                    }
                }
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                                .padding(10)
                                .background(
                                    Circle()
                                        .fill(colorScheme == .dark ? 
                                            Color(hex: "2C2C4E").opacity(0.8) : 
                                            Color(hex: "F2F2FF").opacity(0.8))
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                        }
                        
                        Spacer()
                        
                        Text("Chat to Image")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                        
                        Spacer()
                        
                        // Empty view for balance
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 38, height: 38)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    
                    // Intro text if no messages
                    if viewModel.messages.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            
                            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                                .font(.system(size: 60))
                                .foregroundColor(colorScheme == .dark ? 
                                    Color.purple.opacity(0.8) : 
                                    Color.purple)
                                .shadow(color: Color.purple.opacity(0.5), radius: 8, x: 0, y: 4)
                                .padding()
                            
                            Text("Chat with AI to Generate Images")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                            
                            Text("Describe the image you'd like to create in detail. Try mentioning styles, colors, subjects, and moods.")
                                .font(.system(size: 16))
                                .multilineTextAlignment(.center)
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color(hex: "666666"))
                                .padding(.horizontal, 40)
                                .padding(.bottom, 10)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                examplePrompt("A futuristic cityscape with neon lights and flying cars")
                                examplePrompt("Portrait of a husky with blue eyes in a snowy mountain")
                                examplePrompt("Surreal landscape with floating islands and waterfalls")
                            }
                            .padding(.horizontal, 20)
                            
                            Spacer()
                        }
                        .padding(.bottom, 60)
                    } else {
                        // Chat area
                        ScrollViewReader { scrollProxy in
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(viewModel.messages) { message in
                                        MessageView(message: message, isGenerating: viewModel.isGenerating)
                                            .transition(.asymmetric(
                                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                                removal: .opacity
                                            ))
                                    }
                                    .onChange(of: viewModel.messages.count) { _, _ in
                                        scrollToBottom(proxy: scrollProxy)
                                    }
                                    .id(scrollViewID)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                            }
                            .scrollIndicators(.hidden)
                        }
                    }
                    
                    // Input area
                    HStack(spacing: 12) {
                        TextField("Describe an image...", text: $prompt)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(colorScheme == .dark ? 
                                          Color(hex: "2A2A3E").opacity(0.7) : 
                                          Color.white.opacity(0.7))
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            .focused($isTextFieldFocused)
                        
                        // Send/Listen button
                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: prompt.isEmpty ? (viewModel.isListening ? "mic.fill" : "mic") : "arrow.up.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                                )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(
                        Rectangle()
                            .fill(colorScheme == .dark ? 
                                  Color(hex: "1C1C2E").opacity(0.8) : 
                                  Color.white.opacity(0.8))
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: -2)
                    )
                    .padding(.bottom, keyboardHeight > 0 ? 0 : geometry.safeAreaInsets.bottom)
                }
                .onAppear {
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                            keyboardHeight = keyboardFrame.height
                        }
                    }
                    
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                        keyboardHeight = 0
                    }
                }
                
                // Paywall overlay
                if showPaywall {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .overlay(
                            PaywallView(isPresented: $showPaywall)
                        )
                        .zIndex(1)
                }
            }
            .alert("Generation Failed", isPresented: $showGenerationFailedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Failed to generate the image. Please try again with a different description.")
            }
        }
    }
    
    // MARK: - Components
    
    // Example prompts with tap to use functionality
    private func examplePrompt(_ text: String) -> some View {
        Button {
            prompt = text
        } label: {
            HStack {
                Text(text)
                    .font(.system(size: 15))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : Color(hex: "333333"))
                    .padding(.leading, 12)
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.purple.opacity(0.8))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? 
                          Color(hex: "2C2C4E").opacity(0.5) : 
                          Color(hex: "F2F2FF").opacity(0.8))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Functions
    
    func sendMessage() {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Check if the user has used all their free generations
        if !subscriptionManager.isSubscribed && subscriptionManager.generationsRemaining <= 0 {
            showPaywall = true
            return
        }
        
        // If we're currently converting speech to text, we don't want to send empty messages
        if viewModel.isListening {
            viewModel.stopVoiceRecognition()
        }
        
        // Decrement generations for free users
        if !subscriptionManager.isSubscribed {
            subscriptionManager.generationsRemaining -= 1
        }
        
        // Send the message to the view model
        viewModel.sendMessage(prompt)
        
        // Clear the prompt after sending
        prompt = ""
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                proxy.scrollTo(scrollViewID, anchor: .bottom)
            }
        }
    }
}

// MARK: - Message View
struct MessageView: View {
    let message: ChatMessage
    let isGenerating: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    )
                    .foregroundColor(.white)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    if !message.text.isEmpty {
                        Text(message.text)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(colorScheme == .dark ? 
                                          Color(hex: "2A2A3E").opacity(0.8) : 
                                          Color.white.opacity(0.8))
                                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                            )
                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                    }
                    
                    if let image = message.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 240)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.4)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    } else if !message.text.isEmpty && isGenerating {
                        LoadingDotsView()
                            .padding(.leading, 16)
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Loading Dots Animation
struct LoadingDotsView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 8, height: 8)
                    .offset(y: isAnimating ? -4 : 0)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(0.2 * Double(index)),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview
#Preview {
    let openAIService = OpenAIService()
    
    return ChatToImageView(openAIService: openAIService)
        .environmentObject(AppSettings())
        .environmentObject(SubscriptionManager())
} 