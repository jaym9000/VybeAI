// MainView.swift
// VybeAI
//
// Created by JM Mahoro on 2025-03-26.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var openAIService: OpenAIService
    @EnvironmentObject var imageCaptureService: ImageCaptureService
    @State private var isShowingSettings = false
    
    var body: some View {
        ZStack {
            // Check if onboarding is completed
            if !appSettings.hasCompletedOnboarding {
                // Show onboarding
                OnboardingView()
                    .transition(.opacity)
            } else {
                // Main app content
                ZStack {
                    // Main content
                    NavigationView {
                        ImageGenerationView(openAIService: openAIService, imageCaptureService: imageCaptureService, subscriptionManager: subscriptionManager)
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    
                    // Settings overlay
                    if isShowingSettings {
                        // Dimming overlay
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    isShowingSettings = false
                                }
                            }
                        
                        // Settings view
                        SettingsView()
                            .transition(.move(edge: .trailing))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                            .background(Color.clear)
                    }
                }
                .animation(.spring(), value: isShowingSettings)
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowSettings"))) { _ in
                    withAnimation {
                        isShowingSettings = true
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("HideSettings"))) { _ in
                    withAnimation {
                        isShowingSettings = false
                    }
                }
            }
        }
        .animation(.spring(), value: appSettings.hasCompletedOnboarding)
        .accentColor(.blue)
        .preferredColorScheme(getPreferredColorScheme())
    }
    
    private func getPreferredColorScheme() -> ColorScheme? {
        switch appSettings.selectedAppearance {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AppSettings())
        .environmentObject(SubscriptionManager())
        .environmentObject(OpenAIService())
        .environmentObject(ImageCaptureService())
} 