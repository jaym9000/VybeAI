// ImageCaptureService.swift
// VybeAI - Shock-Style Content Generator
//
// Created by JM Mahoro on 2025-03-26.
//

import SwiftUI
import PhotosUI
import AVFoundation
import Photos
import Combine

enum ImageSource {
    case camera
    case photoLibrary
}

// Protocol for dependency injection and testability
protocol ImageCaptureServiceProtocol {
    func requestPermission(for source: ImageSource) async -> Bool
    func saveImageToLibrary(_ image: UIImage) async throws
    
    // Add nonisolated keyword for synchronous functions
    nonisolated func checkCameraPermission() -> AVAuthorizationStatus
    nonisolated func checkPhotoLibraryPermission() -> PHAuthorizationStatus
}

// Mark as @MainActor for Sendable conformance
@MainActor
class ImageCaptureService: ObservableObject, ImageCaptureServiceProtocol {
    // Published properties to track service state
    @Published var isSaving = false
    @Published var cameraAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var photoLibraryAuthorizationStatus: PHAuthorizationStatus = .notDetermined
    
    init() {
        // Initialize with current permission statuses
        cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        photoLibraryAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
    }
    
    // Static methods need to be nonisolated to be called from nonisolated context
    private static nonisolated func checkCameraPermissionStatic() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    private static nonisolated func checkPhotoLibraryPermissionStatic() -> PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus()
    }
    
    // Check current camera permission status - nonisolated implementation
    nonisolated func checkCameraPermission() -> AVAuthorizationStatus {
        return Self.checkCameraPermissionStatic()
    }
    
    // Check current photo library permission status - nonisolated implementation
    nonisolated func checkPhotoLibraryPermission() -> PHAuthorizationStatus {
        return Self.checkPhotoLibraryPermissionStatic()
    }
    
    // Update permission state - internal method that should be called on MainActor
    func updateCameraAuthorizationStatus(_ status: AVAuthorizationStatus) {
        self.cameraAuthorizationStatus = status
    }
    
    func updatePhotoLibraryAuthorizationStatus(_ status: PHAuthorizationStatus) {
        self.photoLibraryAuthorizationStatus = status
    }
    
    // Request permission for camera or photo library
    func requestPermission(for source: ImageSource) async -> Bool {
        switch source {
        case .camera:
            return await requestCameraPermission()
        case .photoLibrary:
            return await requestPhotoLibraryPermission()
        }
    }
    
    private func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        // Return true if already authorized
        if status == .authorized {
            self.cameraAuthorizationStatus = .authorized
            return true
        }
        
        // Request permission if not determined yet
        if status == .notDetermined {
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    Task { @MainActor in
                        self?.cameraAuthorizationStatus = granted ? .authorized : .denied
                    }
                    continuation.resume(returning: granted)
                }
            }
        }
        
        // Permission denied or restricted
        self.cameraAuthorizationStatus = status
        return false
    }
    
    private func requestPhotoLibraryPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus()
        
        // Return true if already authorized
        if status == .authorized || status == .limited {
            self.photoLibraryAuthorizationStatus = status
            return true
        }
        
        // Request permission if not determined yet
        if status == .notDetermined {
            return await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization { [weak self] status in
                    Task { @MainActor in
                        self?.photoLibraryAuthorizationStatus = status
                    }
                    continuation.resume(returning: status == .authorized || status == .limited)
                }
            }
        }
        
        // Permission denied or restricted
        self.photoLibraryAuthorizationStatus = status
        return false
    }
    
    // Save the generated image to the photo library
    func saveImageToLibrary(_ image: UIImage) async throws {
        // Set saving state
        self.isSaving = true
        
        // Check permission first
        let hasPermission = await requestPermission(for: .photoLibrary)
        guard hasPermission else {
            self.isSaving = false
            throw ImageSaveError.permissionDenied
        }
        
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                } completionHandler: { [weak self] success, error in
                    Task { @MainActor in
                        self?.isSaving = false
                    }
                    
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if success {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: ImageSaveError.saveFailed)
                    }
                }
            }
        } catch {
            self.isSaving = false
            throw error
        }
    }
    
    enum ImageSaveError: Error, LocalizedError {
        case saveFailed
        case permissionDenied
        
        var errorDescription: String? {
            switch self {
            case .saveFailed:
                return "Failed to save image to photo library"
            case .permissionDenied:
                return "Cannot save image - photo library access denied"
            }
        }
    }
} 