//
//  Theme.swift
//  SleepLedger
//
//  Dark OLED-optimized color scheme and design tokens
//

import SwiftUI

extension Color {
    // MARK: - Background Colors
    static let sleepBackground = Color.black
    static let sleepCardBackground = Color(hex: "#0A0A0A")
    static let sleepCardBorder = Color(hex: "#1A1A1A")
    
    // MARK: - Primary Colors
    static let sleepPrimary = Color(hex: "#6366F1") // Indigo
    static let sleepSecondary = Color(hex: "#8B5CF6") // Purple
    
    // MARK: - Sleep Stage Colors
    static let sleepDeepSleep = Color(hex: "#3B82F6") // Blue
    static let sleepLightSleep = Color(hex: "#A78BFA") // Light purple
    static let sleepAwake = Color(hex: "#F59E0B") // Amber
    
    // MARK: - Status Colors
    static let sleepSuccess = Color(hex: "#10B981") // Green
    static let sleepWarning = Color(hex: "#F59E0B") // Amber
    static let sleepError = Color(hex: "#EF4444") // Red
    
    // MARK: - Text Colors
    static let sleepTextPrimary = Color.white.opacity(0.95)
    static let sleepTextSecondary = Color.white.opacity(0.6)
    static let sleepTextTertiary = Color.white.opacity(0.4)
    
    // MARK: - Helper
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
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Custom View Modifiers

struct SleepCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.sleepCardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.sleepCardBorder, lineWidth: 1)
            )
    }
}

extension View {
    func sleepCard() -> some View {
        modifier(SleepCardModifier())
    }
}
