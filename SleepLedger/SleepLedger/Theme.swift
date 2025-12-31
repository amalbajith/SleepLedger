//
//  Theme.swift
//  SleepLedger
//
//  Vibrant dark theme with glassmorphism
//

import SwiftUI

extension Color {
    // MARK: - Dark UI Palette
    
    /// Pure black background
    static let sleepBackground = Color(hex: "#000000")
    
    /// Card background (dark gray/tactile)
    static let sleepCardBackground = Color(hex: "#121212")
    
    /// Glass panel background
    static let sleepGlassBackground = Color(white: 1, opacity: 0.05)
    
    /// Primary accent (vibrant purple)
    static let sleepPrimary = Color(hex: "#5b13ec")
    static let sleepPrimaryGlow = Color(hex: "#7c3aed")
    
    /// Functional colors
    static let sleepSuccess = Color(hex: "#10b981") // surplus green
    static let sleepError = Color(hex: "#ff4d4d")   // debt red
    static let sleepWarning = Color(hex: "#fbbf24") // amber
    
    /// Text hierarchy
    static let sleepTextPrimary = Color.white
    static let sleepTextSecondary = Color.gray.opacity(0.8)
    static let sleepTextTertiary = Color.gray.opacity(0.5)
    
    /// Border colors
    static let sleepGlassBorder = Color(white: 1, opacity: 0.08)
    
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
    func sleepGlassPanel() -> some View {
        self
            .background(.ultraThinMaterial.opacity(0.5))
            .background(Color.sleepGlassBackground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.sleepGlassBorder, lineWidth: 1)
            )
    }
    
    func sleepCard() -> some View {
        self
            .background(Color.sleepCardBackground)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.sleepGlassBorder, lineWidth: 1)
            )
    }
}
