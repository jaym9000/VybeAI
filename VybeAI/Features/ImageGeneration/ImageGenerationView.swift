// ImageGenerationView.swift
// VybeAI - Shock-Style Content Generator
//
// Created by JM Mahoro on 2025-03-26.
//

import SwiftUI
import PhotosUI
import AVFoundation

struct ImageGenerationView: View {
    @StateObject private var viewModel: ImageGenerationViewModel
    @State private var showingSaveSuccess = false
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    @State private var isSaving = false
    @State private var showingPromptSheet = false
    @Environment(\.colorScheme) var colorScheme
    @State private var imageSource: UIImagePickerController.SourceType = .camera
    @State private var showingCameraView = false
    @State private var showingImagePicker = false
    @State private var showingHistoryView = false
    @State private var showingHelpInfo = false
    @State private var selectedImage: UIImage?
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showCameraPermissionAlert = false
    
    // Services are now injected rather than created internally
    private let imageCaptureService: ImageCaptureServiceProtocol
    private let openAIService: OpenAIServiceProtocol
    
    init(
        openAIService: OpenAIServiceProtocol,
        imageCaptureService: ImageCaptureServiceProtocol,
        subscriptionManager: SubscriptionManager
    ) {
        self.openAIService = openAIService
        self.imageCaptureService = imageCaptureService
        
        // Initialize the view model with injected services
        _viewModel = StateObject(wrappedValue: ImageGenerationViewModel(
            openAIService: openAIService,
            imageCaptureService: imageCaptureService,
            subscriptionManager: subscriptionManager
        ))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                backgroundGradient
                    .ignoresSafeArea()
                
                // Main content
                VStack(spacing: 0) {
                    // Header
                    header
                        .padding(.top, geometry.safeAreaInsets.top > 0 ? 0 : 16)
                    
                    Spacer(minLength: 0)
                    
                    // Main content area
                    ZStack {
                        if viewModel.imageModel.sourceImage == nil {
                            // Image selection view
                            imageSelectionView
                                .transition(.opacity)
                                
                            // Help button in the empty space
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    helpButton
                                        .padding()
                                }
                            }
                        } else if viewModel.imageModel.generatedImage != nil {
                            // Result view
                            resultView
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        } else {
                            // Processing or image selected view
                            processingView
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Spacer(minLength: 0)
                }
                .padding(.horizontal)
                .sheet(isPresented: $showingImagePicker) {
                    VybePhotoPicker(selectedImage: $selectedImage)
                }
                .sheet(isPresented: $showingCameraView) {
                    VybeCameraPicker(selectedImage: $selectedImage)
                }
                .sheet(isPresented: $showingHistoryView) {
                    ImageHistoryView(imageCaptureService: imageCaptureService)
                        .environmentObject(viewModel)
                        .environmentObject(appSettings)
                        .environmentObject(subscriptionManager)
                }
                
                // Paywall overlay
                if viewModel.showPaywall {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .overlay(
                            PaywallView(isPresented: $viewModel.showPaywall)
                                .transition(.opacity)
                        )
                        .zIndex(1)
                }
                
                // Prompt sheet overlay
                if showingPromptSheet {
                    promptSheet
                        .transition(.move(edge: .bottom))
                        .zIndex(2)
                }
                
                // Help info overlay
                if showingHelpInfo {
                    helpInfoOverlay
                        .transition(.opacity)
                        .zIndex(3)
                }
            }
            .alert("Camera Access Required", isPresented: $showCameraPermissionAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("VybeAI needs access to your camera to take photos. Please grant permission in your device settings.")
            }
            .alert("Saved Successfully", isPresented: $showingSaveSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your image has been saved to your photo library.")
            }
            .alert("Save Failed", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveErrorMessage)
            }
        }
        .animation(.spring(), value: viewModel.imageModel.sourceImage)
        .animation(.spring(), value: viewModel.imageModel.generatedImage)
        .animation(.spring(), value: viewModel.imageModel.status)
        .animation(.spring(), value: showingPromptSheet)
        .animation(.spring(), value: showingHelpInfo)
        .onChange(of: selectedImage) { oldImage, newImage in
            if let image = newImage {
                viewModel.imageModel.sourceImage = image
            }
        }
    }
    
    // MARK: - Components
    
    // Gradient background similar to TikTok/Snapchat
    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(
                colors: colorScheme == .dark ?
                    [Color(hex: "121212"), Color(hex: "1D1D1D")] :
                    [Color(hex: "F8F8F8"), Color.white]
            ),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // Header with title and buttons
    private var header: some View {
        HStack {
            Text("VybeAI")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
            
            Spacer()
            
            // History button
            Button(action: {
                showingHistoryView = true
            }) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 20))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F2F2F7"))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 8)
            
            // Chat button
            NavigationLink(destination: ChatToImageView(openAIService: openAIService)
                .environmentObject(appSettings)
                .environmentObject(subscriptionManager)) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 20))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F2F2F7"))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 8)
            
            // Settings button
            Button(action: {
                // Post notification to show settings
                NotificationCenter.default.post(name: Notification.Name("ShowSettings"), object: nil)
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F2F2F7"))
                    )
            }
        }
        .padding(.vertical, 16)
    }
    
    // Help button for floating in empty space
    private var helpButton: some View {
        Button(action: {
            withAnimation {
                showingHelpInfo = true
            }
        }) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.purple.opacity(0.7))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    // Help info overlay
    private var helpInfoOverlay: some View {
        ZStack {
            // Dimming background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showingHelpInfo = false
                    }
                }
            
            // Help info card
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("How to Use VybeAI")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showingHelpInfo = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                // Help content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        helpTip(icon: "1.circle.fill", title: "Select an Image", description: "Take a photo with your camera or select one from your photo library")
                        
                        helpTip(icon: "2.circle.fill", title: "Customize Transformation", description: "Describe how you want AI to transform your image using the prompt field")
                        
                        helpTip(icon: "3.circle.fill", title: "Create", description: "Tap 'Transform Image' and wait while our AI generates your creation")
                        
                        helpTip(icon: "4.circle.fill", title: "Save & Share", description: "Save your transformed image to your photos or share it with friends")
                        
                        helpTip(icon: "star.circle.fill", title: "Pro Tip", description: "Try different prompts for unique results. Be specific about styles, colors, and moods!")
                        
                        helpTip(icon: "arrow.counterclockwise.circle.fill", title: "View History", description: "Tap the clock icon in the top right to see your previous creations")
                    }
                    .padding(.bottom, 16)
                }
                
                // Got it button
                Button(action: {
                    withAnimation {
                        showingHelpInfo = false
                    }
                }) {
                    Text("Got it!")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colorScheme == .dark ? Color(hex: "1A1A1A") : Color.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
            )
            .padding(24)
        }
    }
    
    // Helper for help tips
    private func helpTip(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.purple)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // Image selection view (initial state)
    var imageSelectionView: some View {
        VStack(spacing: 32) {
            // App icon/branding
            VStack(spacing: 16) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 64))
                    .foregroundColor(.purple)
                    .padding()
                    .background(
                        Circle()
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 120, height: 120)
                    )
                
                Text("Transform your photos with AI")
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                Text("Create viral-style content in seconds")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            // Selection buttons
            VStack(spacing: 16) {
                Button(action: {
                    checkCameraPermissionAndProceed()
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.headline)
                        Text("Take a Photo")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
                }
                
                Button(action: {
                    // Open photo library
                    imageSource = .photoLibrary
                    showingImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.headline)
                        Text("Choose from Library")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        colorScheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F2F2F7")
                    )
                    .cornerRadius(28)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // Processing/Selected Image View
    var processingView: some View {
        VStack(spacing: 24) {
            if let sourceImage = viewModel.imageModel.sourceImage {
                // Selected image with circular crop (like Snapchat)
                ZStack {
                    Image(uiImage: sourceImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 280, height: 280)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        
                    
                    // Loading overlay
                    if viewModel.imageModel.status.isLoading {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 280, height: 280)
                            .overlay(
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(.white)
                                    
                                    Text(viewModel.imageModel.status == .uploading ? "Uploading..." : "Transforming...")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            )
                    }
                }
                
                // Error message if present
                if let errorMessage = viewModel.imageModel.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    // Customize button
                    Button(action: {
                        withAnimation {
                            showingPromptSheet = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .font(.headline)
                            Text("Customize")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                    }
                    
                    // Generate button
                    Button(action: {
                        viewModel.generateImage()
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .font(.headline)
                            Text("Transform Image")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                    }
                    .disabled(viewModel.imageModel.status.isLoading)
                    .opacity(viewModel.imageModel.status.isLoading ? 0.6 : 1)
                    
                    // Start over button
                    Button(action: {
                        viewModel.resetGeneration()
                    }) {
                        Text("Start Over")
                            .fontWeight(.medium)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : Color(hex: "666666"))
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal)
            }
        }
    }
    
    // Result view with generated image
    var resultView: some View {
        VStack(spacing: 24) {
            if let generatedImage = viewModel.imageModel.generatedImage {
                // Generated image with fancy border
                ZStack {
                    Image(uiImage: generatedImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 3
                                )
                        )
                        .padding(.horizontal, 16)
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    // Save button
                    Button(action: {
                        saveImage()
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.to.line")
                                .font(.headline)
                            Text(isSaving ? "Saving..." : "Save to Photos")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                    }
                    .disabled(isSaving)
                    .opacity(isSaving ? 0.6 : 1)
                    
                    // Share button
                    Button(action: {
                        shareImage(generatedImage)
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.headline)
                            Text("Share")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "4A66FB"), Color(hex: "5D8CF9")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                    }
                    
                    // New creation button
                    Button(action: {
                        viewModel.resetGeneration()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .font(.headline)
                            Text("New Creation")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            colorScheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F2F2F7")
                        )
                        .cornerRadius(28)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // Prompt sheet
    var promptSheet: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 20) {
                    // Handle
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 40, height: 5)
                        .padding(.top, 8)
                    
                    Text("Customize Transformation")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    // Prompt text field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transformation Prompt")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Describe your transformation style", text: $viewModel.imageModel.prompt)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F2F2F7"))
                            )
                    }
                    
                    // Button
                    Button(action: {
                        withAnimation {
                            showingPromptSheet = false
                        }
                    }) {
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                    }
                    .padding(.top, 8)
                    
                    // Bottom spacing for safe area
                    Spacer()
                        .frame(height: geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : 16)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: -5)
                )
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.height > 50 {
                                withAnimation {
                                    showingPromptSheet = false
                                }
                            }
                        }
                )
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    // MARK: - Functions
    
    // Helper for camera permission
    private func checkCameraPermissionAndProceed() {
        let status = imageCaptureService.checkCameraPermission()
        
        switch status {
        case .authorized:
            // Camera is authorized
            imageSource = .camera
            showingCameraView = true
            
        case .notDetermined:
            // Request permission
            Task {
                let granted = await imageCaptureService.requestPermission(for: .camera)
                
                await MainActor.run {
                    if granted {
                        imageSource = .camera
                        showingCameraView = true
                    } else {
                        showCameraPermissionAlert = true
                    }
                }
            }
            
        case .denied, .restricted:
            // Show alert to direct to settings
            showCameraPermissionAlert = true
            
        @unknown default:
            // Handle future cases
            showCameraPermissionAlert = true
        }
    }
    
    private func saveImage() {
        guard !isSaving else { return }
        
        isSaving = true
        
        Task {
            let result = await viewModel.saveGeneratedImage()
            
            await MainActor.run {
                isSaving = false
                
                switch result {
                case .success:
                    showingSaveSuccess = true
                case .failure(let error):
                    saveErrorMessage = error.localizedDescription
                    showingSaveError = true
                }
            }
        }
    }
    
    private func shareImage(_ image: UIImage) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        // Present the activity view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// MARK: - History View
struct ImageHistoryView: View {
    @EnvironmentObject private var viewModel: ImageGenerationViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    private let imageCaptureService: ImageCaptureServiceProtocol
    
    init(imageCaptureService: ImageCaptureServiceProtocol) {
        self.imageCaptureService = imageCaptureService
    }
    
    var body: some View {
        NavigationView {
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
                
                // Content
                VStack(spacing: 0) {
                    if viewModel.generatedImages.isEmpty {
                        // Empty state
                        VStack(spacing: 20) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 70))
                                .foregroundColor(.gray)
                                .padding()
                            
                            Text("No Image History")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Your AI-generated images will appear here")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.bottom, 40)
                    } else {
                        // Grid of images
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(viewModel.generatedImages) { imageEntry in
                                    HistoryImageCell(imageEntry: imageEntry)
                                }
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(colorScheme == .dark ? .white : .gray)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.generatedImages.isEmpty {
                        Button(action: {
                            viewModel.clearHistory()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }
}

// Cell for history grid
struct HistoryImageCell: View {
    let imageEntry: ImageEntry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                if let image = imageEntry.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .cornerRadius(12)
                        .clipped()
                } else {
                    // Fallback if image is nil
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 160)
                        .cornerRadius(12)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
                
                // Date indicator
                Text(formattedDate)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(8)
            }
            
            // Prompt text (limited)
            let promptText = imageEntry.prompt
            if !promptText.isEmpty {
                Text(promptText)
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .gray)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: imageEntry.date)
    }
}

#Preview {
    let subscriptionManager = SubscriptionManager()
    let openAIService = OpenAIService()
    let imageCaptureService = ImageCaptureService()
    
    return ImageGenerationView(
        openAIService: openAIService,
        imageCaptureService: imageCaptureService,
        subscriptionManager: subscriptionManager
    )
        .environmentObject(AppSettings())
        .environmentObject(subscriptionManager)
} 