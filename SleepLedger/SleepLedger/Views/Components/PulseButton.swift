//
//  PulseButton.swift
//  SleepLedger
//
//  Main action button with breathing animation
//

import SwiftUI

struct PulseButton: View {
    let isTracking: Bool
    let action: () -> Void
    
    @State private var animatePulse = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background Glow
                Circle()
                    .fill(Color.sleepPrimary.opacity(0.3))
                    .frame(width: 88, height: 88)
                    .scaleEffect(animatePulse ? 1.2 : 1.0)
                    .opacity(animatePulse ? 0.0 : 0.6)
                
                // Main Circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.sleepPrimary, .sleepPrimaryGlow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.sleepPrimary.opacity(0.5), radius: 20)
                
                // Icon
                Image(systemName: isTracking ? "stop.fill" : "bed.double.fill")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundColor(.white)
                    .symbolVariant(.fill)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false)) {
                animatePulse = true
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 50) {
            PulseButton(isTracking: false) {}
            PulseButton(isTracking: true) {}
        }
    }
}
