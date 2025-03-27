// SettingsComponents.swift
// VybeAI
//
// Created by JM Mahoro on 2025-03-27.
//

import SwiftUI

// A section header for settings
struct SettingsSection<Content: View>: View {
    var title: String
    let content: Content
    @Environment(\.colorScheme) var colorScheme
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color(hex: "555555"))
                .padding(.horizontal, 24)
            
            content
                .padding(.horizontal, 24)
        }
    }
}

// A single clickable settings row with icon
struct SettingsRow: View {
    var icon: String
    var title: String
    var action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
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
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding()
            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        SettingsSection(title: "Example Section") {
            VStack(spacing: 0) {
                SettingsRow(icon: "gear", title: "Settings Option") {
                    print("Settings option tapped")
                }
                
                Divider()
                    .background(Color.gray.opacity(0.2))
                    .padding(.horizontal)
                
                SettingsRow(icon: "person", title: "Profile") {
                    print("Profile tapped")
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
} 