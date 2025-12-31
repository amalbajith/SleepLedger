//
//  Theme.swift
//  SleepLedger
//
//  Apple Health inspired color scheme and styling
//

import SwiftUI

extension Color {
    // MARK: - Apple Health Inspired Colors
    
    /// Pure black background for OLED
    static let sleepBackground = Color(hex: "#000000")
    
    /// Card background (very dark gray)
    static let sleepCardBackground = Color(hex: "#1C1C1E")
    
    /// Card border (subtle gray)
    static let sleepCardBorder = Color(hex: "#38383A")
    
    /// Primary accent (Health app pink/coral)
    static let sleepPrimary = Color(hex: "#FF2D55")
    
    /// Secondary accent (Health app orange)
    static let sleepSecondary = Color(hex: "#FF9500")
    
    /// Deep sleep indicator (Health app blue)
    static let sleepDeepSleep = Color(hex: "#007AFF")
    
    /// Light sleep indicator (Health app purple)
    static let sleepLightSleep = Color(hex: "#AF52DE")
    
    /// Awake indicator (Health app yellow)
    static let sleepAwake = Color(hex: "#FFCC00")
    
    /// Success/positive (Health app green)
    static let sleepSuccess = Color(hex: "#34C759")
    
    /// Warning (Health app orange)
    static let sleepWarning = Color(hex: "#FF9500")
    
    /// Error/negative (Health app red)
    static let sleepError = Color(hex: "#FF3B30")
    
    /// Primary text (white)
    static let sleepTextPrimary = Color(hex: "#FFFFFF")
    
    /// Secondary text (light gray)
    static let sleepTextSecondary = Color(hex: "#AEAEB2")
    
    /// Tertiary text (medium gray)
    static let sleepTextTertiary = Color(hex: "#636366")
    
    // MARK: - Hex Color Initializer
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Custom View Modifiers

extension View {
    func sleepCard() -> some View {
        self
            .background(Color.sleepCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.sleepCardBorder, lineWidth: 0.5)
            )
    }
}
