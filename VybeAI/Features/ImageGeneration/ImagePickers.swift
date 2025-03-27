// ImagePickers.swift
// VybeAI
//
// Created by JM Mahoro on 2025-03-26.
//

import SwiftUI
import PhotosUI
import AVFoundation

// Custom photo picker using PHPickerViewController
struct VybePhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VybePhotoPicker
        
        init(_ parent: VybePhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                        self.parent.dismiss()
                    }
                }
            }
        }
    }
}

// Custom camera picker using UIImagePickerController
struct VybeCameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var showingCameraAlert = false
    @State private var alertMessage = ""
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        // First check if device has a camera
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            DispatchQueue.main.async {
                self.alertMessage = "This device doesn't have a camera."
                self.showingCameraAlert = true
                self.dismiss()
            }
            return picker
        }
        
        // Check camera permission status
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            // Camera access already granted, set up the picker
            picker.sourceType = .camera
            picker.delegate = context.coordinator
            
        case .notDetermined:
            // Request camera permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        // Permission granted, but we need to dismiss and the user will need to try again
                        picker.sourceType = .camera
                        picker.delegate = context.coordinator
                    } else {
                        // Permission denied
                        self.alertMessage = "VybeAI needs camera access to take pictures. Please enable it in Settings."
                        self.showingCameraAlert = true
                        self.dismiss()
                    }
                }
            }
            
        case .denied, .restricted:
            // Camera access denied or restricted
            DispatchQueue.main.async {
                self.alertMessage = "VybeAI needs camera access to take pictures. Please enable it in Settings > Privacy > Camera."
                self.showingCameraAlert = true
                self.dismiss()
            }
            
        @unknown default:
            DispatchQueue.main.async {
                self.alertMessage = "Unknown camera permission status. Please try again."
                self.showingCameraAlert = true
                self.dismiss()
            }
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Handle alert presentation
        if showingCameraAlert {
            DispatchQueue.main.async {
                uiViewController.dismiss(animated: true)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: VybeCameraPicker
        
        init(_ parent: VybeCameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            
            picker.dismiss(animated: true)
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            parent.dismiss()
        }
    }
}

// Alert wrapper for camera permissions
struct CameraPermissionAlert: ViewModifier {
    @Binding var isPresented: Bool
    var message: String
    var onDismiss: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("Camera Permission", isPresented: $isPresented) {
                Button("Settings", role: .none) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    onDismiss()
                }
                Button("Cancel", role: .cancel) {
                    onDismiss()
                }
            } message: {
                Text(message)
            }
    }
}

extension View {
    func cameraPermissionAlert(isPresented: Binding<Bool>, message: String, onDismiss: @escaping () -> Void) -> some View {
        self.modifier(CameraPermissionAlert(isPresented: isPresented, message: message, onDismiss: onDismiss))
    }
} 