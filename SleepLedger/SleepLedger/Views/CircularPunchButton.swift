//
//  CircularPunchButton.swift
//  SleepLedger
//
//  Minimalistic circular punch button
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
                    .frame(width: 220, height: 220)
                    .shadow(color: .sleepError.opacity(0.5), radius: 20, x: 0, y: 10)
                
                VStack(spacing: 16) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                    
                    Text("Punch Out")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
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
        .padding(.vertical, 40)
    }
    
    // MARK: - Punch In View
    
    private var punchInView: some View {
        VStack(spacing: 20) {
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
                        .frame(width: 220, height: 220)
                        .shadow(color: .sleepPrimary.opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    VStack(spacing: 16) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.white)
                        
                        Text("Punch In")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
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
            
            // Subtle hint
            Text("Smart alarm configured in Settings")
                .font(.caption)
                .foregroundColor(.sleepTextTertiary)
        }
        .padding(.vertical, 40)
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
