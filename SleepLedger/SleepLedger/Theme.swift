//
//  Theme.swift
//  SleepLedger
//
//  Pure black & white monochrome color scheme
//

import SwiftUI

extension Color {
    // MARK: - Black & White Monochrome
    
    /// Pure black background
    static let sleepBackground = Color(hex: "#000000")
    
    /// Card background (very dark gray)
    static let sleepCardBackground = Color(hex: "#1A1A1A")
    
    /// Card border (subtle gray)
    static let sleepCardBorder = Color(hex: "#2A2A2A")
    
    /// Primary accent (white)
    static let sleepPrimary = Color(hex: "#FFFFFF")
    
    /// Secondary accent (light gray)
    static let sleepSecondary = Color(hex: "#E0E0E0")
    
    /// Deep sleep indicator (medium gray)
    static let sleepDeepSleep = Color(hex: "#A0A0A0")
    
    /// Light sleep indicator (light gray)
    static let sleepLightSleep = Color(hex: "#C0C0C0")
    
    /// Awake indicator (white)
    static let sleepAwake = Color(hex: "#FFFFFF")
    
    /// Success/positive (white)
    static let sleepSuccess = Color(hex: "#FFFFFF")
    
    /// Warning (light gray)
    static let sleepWarning = Color(hex: "#B0B0B0")
    
    /// Error/negative (medium gray)
    static let sleepError = Color(hex: "#808080")
    
    /// Primary text (white)
    static let sleepTextPrimary = Color(hex: "#FFFFFF")
    
    /// Secondary text (light gray)
    static let sleepTextSecondary = Color(hex: "#A0A0A0")
    
    /// Tertiary text (dark gray)
    static let sleepTextTertiary = Color(hex: "#505050")
    
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
