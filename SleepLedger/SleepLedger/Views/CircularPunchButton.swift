//
//  CircularPunchButton.swift
//  SleepLedger
//
//  Circular punch in/out button - simplified
//

import SwiftUI

struct CircularPunchButton: View {
    let isTracking: Bool
    let onPunchIn: () -> Void
    let onPunchOut: () -> Void
    
    @State private var isPressing = false
    
    var body: some View {
        VStack(spacing: 0) {
            if isTracking {
                trackingView
            } else {
                punchInView
            }
        }
    }
    
    // MARK: - Tracking View (When Session Active)
    
    private var trackingView: some View {
        VStack(spacing: 32) {
            Text("Sleep Session Active")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.sleepTextPrimary)
            
            // Large circular stop button
            Button(action: onPunchOut) {
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.sleepError.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 100,
                                endRadius: 140
                            )
                        )
                        .frame(width: 280, height: 280)
                    
                    // Main button
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.sleepError, .sleepWarning],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .shadow(color: .sleepError.opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("Punch Out")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("End Sleep Session")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .scaleEffect(isPressing ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressing)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressing = true }
                    .onEnded { _ in isPressing = false }
            )
        }
        .padding()
    }
    
    // MARK: - Punch In View
    
    private var punchInView: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.sleepPrimary, .sleepSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Ready to Sleep?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.sleepTextPrimary)
                
                Text("Tap to start tracking your sleep")
                    .font(.subheadline)
                    .foregroundColor(.sleepTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Large Circular Punch In Button
            Button(action: onPunchIn) {
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.sleepPrimary.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 100,
                                endRadius: 140
                            )
                        )
                        .frame(width: 280, height: 280)
                    
                    // Main button
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.sleepPrimary, .sleepSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .shadow(color: .sleepPrimary.opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("Punch In")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Start Tracking")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .scaleEffect(isPressing ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressing)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressing = true }
                    .onEnded { _ in isPressing = false }
            )
            
            // Hint about settings
            Text("Configure smart alarm in Settings")
                .font(.caption)
                .foregroundColor(.sleepTextTertiary)
        }
        .padding()
    }
}

#Preview {
    VStack {
        CircularPunchButton(
            isTracking: false,
            onPunchIn: { },
            onPunchOut: { }
        )
    }
    .preferredColorScheme(.dark)
    .background(Color.sleepBackground)
}
