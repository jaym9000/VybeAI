// AppSettings.swift
// VybeAI - Shock-Style Content Generator
//
// Created by JM Mahoro on 2025-03-26.
//

import SwiftUI
import Combine

class AppSettings: ObservableObject {
    enum AppColorScheme: String, CaseIterable, Identifiable {
        case system
        case light
        case dark
        
        var id: String { self.rawValue }
        
        var title: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }
    
    // Published properties for app settings
    @Published var selectedAppearance: AppColorScheme {
        didSet {
            UserDefaults.standard.set(selectedAppearance.rawValue, forKey: "selectedAppearance")
        }
    }
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    @Published var hasMadeFirstFreeGeneration: Bool {
        didSet {
            UserDefaults.standard.set(hasMadeFirstFreeGeneration, forKey: "hasMadeFirstFreeGeneration")
        }
    }
    
    // Computed property for SwiftUI color scheme
    var colorScheme: ColorScheme? {
        switch selectedAppearance {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
    
    init() {
        // Load saved settings or use defaults
        let appearanceString = UserDefaults.standard.string(forKey: "selectedAppearance") ?? "system"
        self.selectedAppearance = AppColorScheme(rawValue: appearanceString) ?? .system
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.hasMadeFirstFreeGeneration = UserDefaults.standard.bool(forKey: "hasMadeFirstFreeGeneration")
    }
    
    func resetSettings() {
        selectedAppearance = .system
        hasCompletedOnboarding = false
        hasMadeFirstFreeGeneration = false
    }
} 