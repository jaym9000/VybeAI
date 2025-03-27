// ColorExtensions.swift
// VybeAI
//
// Created by JM Mahoro on 2025-03-27.
//

import SwiftUI

extension String {
    var isValidHexColor: Bool {
        let hexRegEx = "^[0-9A-Fa-f]{3}([0-9A-Fa-f]{3})?([0-9A-Fa-f]{2})?$"
        let hexPredicate = NSPredicate(format: "SELF MATCHES %@", hexRegEx)
        return hexPredicate.evaluate(with: self)
    }
}

extension Color {
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanHex = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString
        
        if !cleanHex.isValidHexColor {
            self.init(.gray)
            return
        }
        
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 128, 128, 128) // Default to gray as fallback
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Additional convenience methods for common operations
    static func dynamicColor(light: String, dark: String) -> Color {
        #if os(iOS)
        let lightColor = Color(hex: light)
        let darkColor = Color(hex: dark)
        
        return Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                UIColor(darkColor) :
                UIColor(lightColor)
        })
        #else
        return Color(hex: light) // Fallback for other platforms
        #endif
    }
} 