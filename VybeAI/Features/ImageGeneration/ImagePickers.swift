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

// Custom camera picker using UIImagePickerController with improved error handling
struct VybeCameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        
        // Check if camera is available on this device
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            // Check if accessing the camera is allowed
            let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
            if cameraStatus != .authorized {
                // Request camera access
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if !granted {
                        DispatchQueue.main.async {
                            self.dismiss()
                            // Notify the user they need to enable camera access
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            // No camera available on this device
            DispatchQueue.main.async {
                self.dismiss()
                NotificationCenter.default.post(
                    name: Notification.Name("ShowCameraError"),
                    object: "This device doesn't have a camera."
                )
            }
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Nothing to update
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
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
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