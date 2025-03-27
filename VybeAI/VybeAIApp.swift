// VybeAIApp.swift
// VybeAI - Shock-Style Content Generator
//
// Created by JM Mahoro on 2025-03-26.
//

import SwiftUI

// Add camera and photo library permissions to Info.plist
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set up required permissions
        let permissionsInfo = [
            "NSCameraUsageDescription": "VybeAI needs access to your camera to capture images for AI-powered transformations",
            "NSPhotoLibraryUsageDescription": "VybeAI needs access to your photo library to save generated images and to select source images for transformations",
            "NSPhotoLibraryAddUsageDescription": "VybeAI needs permission to save generated images to your photo library"
        ]
        
        // Log permissions for debugging
        for (key, value) in permissionsInfo {
            print("Setting \(key): \(value)")
        }
        
        return true
    }
}

@main
struct VybeAIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Initial app setup
        print("VybeAI is initializing...")
        
        // Register defaults if needed
        UserDefaults.standard.register(defaults: [
            "hasCompletedOnboarding": false,
            "hasMadeFirstFreeGeneration": false,
            "selectedAppearance": 0
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Just to make sure the Info.plist has been updated with our permissions
                    print("Camera usage description: \(Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") ?? "Not set")")
                    print("Photo Library usage description: \(Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryUsageDescription") ?? "Not set")")
                }
        }
    }
}
