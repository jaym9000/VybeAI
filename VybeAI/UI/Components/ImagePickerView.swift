// ImagePickerView.swift
// VybeAI - Shock-Style Content Generator
//
// Created by JM Mahoro on 2025-03-26.
//

import SwiftUI
import PhotosUI

struct ImagePickerView: View {
    @Binding var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCameraView = false
    @State private var imageSource: ImageSource = .photoLibrary
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = selectedImage {
                // Show selected image with option to change
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 300)
                    .cornerRadius(12)
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        selectedImage = nil
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                }
                                .padding(12)
                            }
                        }
                    )
            } else {
                // Show image selection buttons
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 64))
                            .foregroundColor(.purple.opacity(0.8))
                        
                        Text("Select or take a photo to transform")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                    
                    HStack(spacing: 16) {
                        StylizedButton(
                            title: "Camera",
                            icon: "camera",
                            action: {
                                imageSource = .camera
                                showingCameraView = true
                            },
                            isPrimary: true
                        )
                        
                        StylizedButton(
                            title: "Photo Library",
                            icon: "photo.on.rectangle",
                            action: {
                                imageSource = .photoLibrary
                                showingImagePicker = true
                            },
                            isPrimary: false
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.secondary.opacity(0.1))
                )
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            // Use PHPickerViewController via UIViewControllerRepresentable
            PhotoPicker(image: $selectedImage)
        }
        .sheet(isPresented: $showingCameraView) {
            // In a real app, implement a camera view
            // For now, we'll use a placeholder
            CameraPlaceholder(image: $selectedImage)
        }
    }
}

// PHPicker wrapper for SwiftUI
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
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
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

// Placeholder for camera view
// In a real app, implement a proper camera view using AVFoundation
struct CameraPlaceholder: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "Camera functionality would appear here."
        label.textAlignment = .center
        
        let button = UIButton(type: .system)
        button.setTitle("Use Test Image", for: .normal)
        button.addTarget(context.coordinator, action: #selector(Coordinator.useTestImage), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [label, button])
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        controller.view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: controller.view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: controller.view.trailingAnchor, constant: -20)
        ])
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: CameraPlaceholder
        
        init(_ parent: CameraPlaceholder) {
            self.parent = parent
        }
        
        @objc func useTestImage() {
            // For demo, we'll create a simple test image
            // In a real app, this would be the captured photo
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400))
            let image = renderer.image { ctx in
                ctx.cgContext.setFillColor(UIColor.systemBlue.cgColor)
                ctx.cgContext.fill(CGRect(x: 0, y: 0, width: 400, height: 400))
                
                ctx.cgContext.setStrokeColor(UIColor.white.cgColor)
                ctx.cgContext.setLineWidth(5)
                ctx.cgContext.addEllipse(in: CGRect(x: 50, y: 50, width: 300, height: 300))
                ctx.cgContext.drawPath(using: .stroke)
                
                let text = "Test Photo"
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 36),
                    .foregroundColor: UIColor.white
                ]
                
                let size = (text as NSString).size(withAttributes: attributes)
                let rect = CGRect(x: 200 - size.width / 2, y: 200 - size.height / 2, width: size.width, height: size.height)
                (text as NSString).draw(in: rect, withAttributes: attributes)
            }
            
            parent.image = image
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    @Previewable @State var previewImage: UIImage? = nil
    return ImagePickerView(selectedImage: $previewImage)
        .padding()
} 