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
                // Background gradient
                LinearGradient(
                    gradient: Gradient(
                        colors: colorScheme == .dark ?
                            [Color(hex: "121212"), Color(hex: "1D1D1D")] :
                            [Color(hex: "F8F8F8"), Color.white]
                    ),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(colorScheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F2F2F7"))
                                )
                        }
                        
                        Spacer()
                        
                        Text("Chat to Image")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Spacer()
                        
                        // Empty view for balance
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 36, height: 36)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    
                    // Chat area
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.messages) { message in
                                    MessageView(message: message, isGenerating: viewModel.isGenerating)
                                }
                                .onChange(of: viewModel.messages.count) { _, _ in
                                    scrollToBottom(proxy: scrollProxy)
                                }
                                .id(scrollViewID)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // Input area
                    HStack(spacing: 12) {
                        TextField("Describe an image...", text: $prompt)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(colorScheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F2F2F7"))
                            )
                            .focused($isTextFieldFocused)
                        
                        // Send/Listen button
                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: prompt.isEmpty ? (viewModel.isListening ? "mic.fill" : "mic") : "arrow.up.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(colorScheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F2F2F7"))
                                )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(
                        Rectangle()
                            .fill(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
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
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    )
                    .foregroundColor(.white)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    if !message.text.isEmpty {
                        Text(message.text)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(colorScheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F2F2F7"))
                            )
                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                    }
                    
                    if let image = message.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 240)
                            .cornerRadius(12)
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
                    .fill(Color.gray)
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