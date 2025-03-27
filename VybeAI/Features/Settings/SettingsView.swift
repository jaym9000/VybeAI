// SettingsView.swift
// VybeAI
//
// Created by JM Mahoro on 2025-03-26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showingResetConfirmation = false
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            Group {
                if colorScheme == .dark {
                    Color(hex: "1A1A1A").ignoresSafeArea()
                } else {
                    Color(hex: "F8F8F8").ignoresSafeArea()
                }
            }
            
            // Content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                    
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        NotificationCenter.default.post(name: Notification.Name("HideSettings"), object: nil)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color(hex: "666666"))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                // Settings sections
                ScrollView {
                    VStack(spacing: 24) {
                        // App theme section
                        SettingsSection(title: "Appearance") {
                            VStack(spacing: 0) {
                                ForEach(AppSettings.AppColorScheme.allCases) { theme in
                                    Button(action: {
                                        appSettings.selectedAppearance = theme
                                    }) {
                                        HStack {
                                            Text(theme.title)
                                                .fontWeight(.medium)
                                            
                                            Spacer()
                                            
                                            if appSettings.selectedAppearance == theme {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(colorScheme == .dark ? Color(hex: "2C2C2E") : Color.white)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if theme != AppSettings.AppColorScheme.allCases.last {
                                        Divider()
                                            .background(Color.gray.opacity(0.2))
                                            .padding(.horizontal)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(hex: "2C2C2E") : Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                        }
                        
                        // Subscription section
                        SettingsSection(title: "Subscription") {
                            VStack(spacing: 20) {
                                // Current plan
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Current Plan")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        if subscriptionManager.currentSubscription != .free {
                                            Image(systemName: "crown.fill")
                                                .foregroundColor(.yellow)
                                                .font(.system(size: 20))
                                        }
                                        
                                        Text(subscriptionManager.currentSubscription.title)
                                            .font(.headline)
                                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                                    }
                                    
                                    if subscriptionManager.currentSubscription == .free {
                                        Text("Free generations remaining: \(appSettings.hasMadeFirstFreeGeneration ? "0" : "1")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color(hex: "2C2C2E") : Color.white)
                                )
                                
                                // Action buttons
                                if subscriptionManager.currentSubscription == .free {
                                    Button(action: {
                                        NotificationCenter.default.post(name: Notification.Name("HideSettings"), object: nil)
                                        // Show paywall
                                    }) {
                                        HStack {
                                            Image(systemName: "crown.fill")
                                                .font(.headline)
                                            Text("Upgrade Plan")
                                                .fontWeight(.semibold)
                                        }
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
                                        .cornerRadius(12)
                                    }
                                } else {
                                    Button(action: {
                                        subscriptionManager.restorePurchases()
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.headline)
                                            Text("Restore Purchases")
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(
                                            colorScheme == .dark ? Color(hex: "2C2C2E") : Color.white
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        
                        // Legal & Info section
                        SettingsSection(title: "Legal & Info") {
                            VStack(spacing: 0) {
                                // Terms of Service
                                SettingsRow(icon: "doc.text", title: "Terms of Service") {
                                    showingTerms = true
                                }
                                
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                    .padding(.horizontal)
                                
                                // Privacy Policy
                                SettingsRow(icon: "hand.raised", title: "Privacy Policy") {
                                    showingPrivacy = true
                                }
                                
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                    .padding(.horizontal)
                                
                                // App Version
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("App Version")
                                    
                                    Spacer()
                                    
                                    Text("1.0.0")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(hex: "2C2C2E") : Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                        }
                        
                        // Advanced section
                        SettingsSection(title: "Advanced") {
                            Button(action: {
                                showingResetConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .foregroundColor(.red)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("Reset App Settings")
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                }
                                .padding()
                                .foregroundColor(.red)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color(hex: "2C2C2E") : Color.white)
                                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Footer
                        Text("VybeAI © 2025")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .alert("Reset Settings", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                appSettings.resetSettings()
            }
        } message: {
            Text("This will reset all app settings to default values. This action cannot be undone.")
        }
        .sheet(isPresented: $showingTerms) {
            LegalDocumentView(title: "Terms of Service", content: termsOfServiceText)
        }
        .sheet(isPresented: $showingPrivacy) {
            LegalDocumentView(title: "Privacy Policy", content: privacyPolicyText)
        }
    }
    
    // MARK: - Custom Views
    
    // Section header
    struct SettingsSection<Content: View>: View {
        let title: String
        let content: Content
        
        init(title: String, @ViewBuilder content: () -> Content) {
            self.title = title
            self.content = content()
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                
                content
            }
        }
    }
    
    // Settings row
    struct SettingsRow: View {
        let icon: String
        let title: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .frame(width: 24, height: 24)
                    
                    Text(title)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // Sample content for terms and privacy
    private let termsOfServiceText = """
    Terms of Service
    
    1. Acceptance of Terms
    By accessing or using the VybeAI app, you agree to be bound by these Terms of Service.
    
    2. User Content
    You retain all rights to the images you upload. We do not claim ownership of your content.
    
    3. Prohibited Use
    You may not use this service for generating illegal, harmful, or explicitly offensive content.
    
    4. Subscriptions
    Subscription charges will automatically renew unless canceled at least 24 hours before the end of the current period.
    
    5. Changes to Terms
    We reserve the right to modify these terms at any time. Continued use of the app constitutes acceptance of modified terms.
    
    6. Termination
    We reserve the right to terminate or suspend your access to our service at our sole discretion.
    """
    
    private let privacyPolicyText = """
    Privacy Policy
    
    1. Information Collection
    We collect minimal information necessary to provide our services, including images you upload for processing.
    
    2. Use of Data
    Your images are only used for processing your specific requests and are not shared with third parties.
    
    3. Data Storage
    Your images are temporarily stored for processing and are deleted from our servers after 7 days.
    
    4. API Usage
    We use OpenAI's API for image generation, and your images are handled according to their privacy policy as well.
    
    5. Analytics
    We collect anonymous usage data to improve our service.
    
    6. Third-Party Services
    We use RevenueCat for subscription management.
    
    7. Changes to Policy
    We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page.
    """
}

struct LegalDocumentView: View {
    let title: String
    let content: String
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.blue)
            }
            .padding()
            .background(colorScheme == .dark ? Color(hex: "1A1A1A") : Color.white)
            
            // Content
            ScrollView {
                Text(content)
                    .padding()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
        .environmentObject(SubscriptionManager())
} 