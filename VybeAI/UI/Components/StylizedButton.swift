// StylizedButton.swift
// VybeAI - Shock-Style Content Generator
//
// Created by JM Mahoro on 2025-03-26.
//

import SwiftUI

struct StylizedButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isPrimary: Bool
    let isLoading: Bool
    let fullWidth: Bool
    
    init(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void,
        isPrimary: Bool = true,
        isLoading: Bool = false,
        fullWidth: Bool = false
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isPrimary = isPrimary
        self.isLoading = isLoading
        self.fullWidth = fullWidth
    }
    
    var body: some View {
        Button(action: {
            if !isLoading {
                action()
            }
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: isPrimary ? .white : .primary))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(minWidth: 44, minHeight: 44)
            .padding(.horizontal, 20)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                isPrimary
                    ? AnyView(primaryBackground)
                    : AnyView(secondaryBackground)
            )
            .foregroundColor(isPrimary ? .white : .primary)
            .cornerRadius(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
    
    var primaryBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.purple, Color.blue]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .shadow(color: Color.purple.opacity(0.3), radius: 5, x: 0, y: 3)
    }
    
    var secondaryBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            .background(
                Color.gray.opacity(0.05)
                    .cornerRadius(12)
            )
    }
}

// Primary action button
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isLoading: Bool
    let fullWidth: Bool
    
    init(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void,
        isLoading: Bool = false,
        fullWidth: Bool = true
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isLoading = isLoading
        self.fullWidth = fullWidth
    }
    
    var body: some View {
        StylizedButton(
            title: title,
            icon: icon,
            action: action,
            isPrimary: true,
            isLoading: isLoading,
            fullWidth: fullWidth
        )
    }
}

// Secondary action button
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isLoading: Bool
    let fullWidth: Bool
    
    init(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void,
        isLoading: Bool = false,
        fullWidth: Bool = false
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isLoading = isLoading
        self.fullWidth = fullWidth
    }
    
    var body: some View {
        StylizedButton(
            title: title,
            icon: icon,
            action: action,
            isPrimary: false,
            isLoading: isLoading,
            fullWidth: fullWidth
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        StylizedButton(title: "Primary Button", icon: "wand.and.stars", action: {})
        StylizedButton(title: "Secondary Button", icon: "photo", action: {}, isPrimary: false)
        StylizedButton(title: "Loading Button", action: {}, isLoading: true)
        StylizedButton(title: "Full Width Button", action: {}, fullWidth: true)
    }
    .padding()
} 