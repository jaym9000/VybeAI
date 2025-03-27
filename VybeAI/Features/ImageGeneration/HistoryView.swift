import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var viewModel: ImageGenerationViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    private let imageCaptureService: ImageCaptureServiceProtocol
    
    @State private var selectedImage: ImageEntry? = nil
    @State private var showingDeleteAlert = false
    @State private var showingClearAllAlert = false
    
    init(imageCaptureService: ImageCaptureServiceProtocol) {
        self.imageCaptureService = imageCaptureService
    }
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.generatedImages.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.generatedImages) { entry in
                                historyImageCell(entry)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Image History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.generatedImages.isEmpty {
                        Button {
                            showingClearAllAlert = true
                        } label: {
                            Text("Clear All")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .background(
                colorScheme == .dark ? Color(hex: "121212") : Color(hex: "F5F5F5")
            )
            .sheet(item: $selectedImage) { entry in
                ImageDetailView(
                    entry: entry,
                    imageCaptureService: imageCaptureService,
                    onDismiss: { selectedImage = nil }
                )
                    .environmentObject(viewModel)
            }
            .alert("Delete All History", isPresented: $showingClearAllAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    viewModel.clearHistory()
                }
            } message: {
                Text("Are you sure you want to delete all image history? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Components
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 70))
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            
            Text("No Generated Images")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Images you generate will appear here for quick access.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            
            Button {
                dismiss()
            } label: {
                Text("Generate Images")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
            .padding(.top, 20)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func historyImageCell(_ entry: ImageEntry) -> some View {
        Button {
            selectedImage = entry
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Image
                ZStack {
                    if let image = entry.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(height: 160)
                            .cornerRadius(12)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(height: 160)
                            .cornerRadius(12)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    if let sourceImage = entry.sourceImage {
                        Image(uiImage: sourceImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(radius: 3)
                            .position(x: 35, y: 35)
                    }
                }
                
                // Date & prompt
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedDate(entry.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(entry.prompt)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                .padding(.horizontal, 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - ImageDetailView

struct ImageDetailView: View {
    let entry: ImageEntry
    let imageCaptureService: ImageCaptureServiceProtocol
    let onDismiss: () -> Void
    
    @EnvironmentObject private var viewModel: ImageGenerationViewModel
    @State private var showShareSheet = false
    @State private var showSaveSuccess = false
    @State private var showDeleteAlert = false
    @State private var isSaving = false
    @State private var saveErrorMessage = ""
    @State private var showSaveError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.opacity(0.9).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if let image = entry.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                            .shadow(radius: 10)
                    }
                    
                    // Prompt used to generate
                    Text(entry.prompt)
                        .font(.caption)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Buttons
                    HStack(spacing: 20) {
                        ActionButton(icon: "square.and.arrow.down", label: isSaving ? "Saving..." : "Save") {
                            if let image = entry.image {
                                saveImage(image)
                            }
                        }
                        .disabled(isSaving)
                        
                        ActionButton(icon: "square.and.arrow.up", label: "Share") {
                            showShareSheet = true
                        }
                        
                        ActionButton(icon: "trash", label: "Delete") {
                            showDeleteAlert = true
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Image Detail")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = entry.image {
                    ShareSheet(items: [image])
                }
            }
            .alert("Image Saved", isPresented: $showSaveSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Image successfully saved to your photo library.")
            }
            .alert("Save Failed", isPresented: $showSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveErrorMessage)
            }
            .alert("Delete Image", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    // Handle image deletion here
                    viewModel.removeFromHistory(entry)
                    onDismiss()
                }
            } message: {
                Text("Are you sure you want to delete this image from your history?")
            }
        }
    }
    
    private func saveImage(_ image: UIImage) {
        guard !isSaving else { return }
        isSaving = true
        
        Task {
            do {
                try await imageCaptureService.saveImageToLibrary(image)
                await MainActor.run {
                    isSaving = false
                    showSaveSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveErrorMessage = error.localizedDescription
                    showSaveError = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    )
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
#Preview {
    let subscriptionManager = SubscriptionManager()
    let openAIService = OpenAIService()
    let imageCaptureService = ImageCaptureService()
    
    // Create the view model and add sample data
    let viewModel = {
        let vm = ImageGenerationViewModel(
            openAIService: openAIService,
            imageCaptureService: imageCaptureService,
            subscriptionManager: subscriptionManager
        )
        
        // Add sample data
        vm.generatedImages = [
            ImageEntry(image: UIImage(systemName: "photo"), prompt: "Example Prompt 1", sourceImage: UIImage(systemName: "camera")),
            ImageEntry(image: UIImage(systemName: "photo.fill"), prompt: "Example Prompt 2")
        ]
        
        return vm
    }()
    
    // Return the view
    HistoryView(imageCaptureService: imageCaptureService)
        .environmentObject(viewModel)
        .environmentObject(AppSettings())
        .environmentObject(subscriptionManager)
} 