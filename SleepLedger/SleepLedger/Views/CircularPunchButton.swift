//
//  CircularPunchButton.swift
//  SleepLedger
//
//  Minimalistic punch button - black & white
//

import SwiftUI

struct CircularPunchButton: View {
    let isTracking: Bool
    let onPunchIn: () -> Void
    let onPunchOut: () -> Void
    
    @State private var isPressing = false
    
    var body: some View {
        Button(action: isTracking ? onPunchOut : onPunchIn) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 240, height: 240)
                
                // Main button
                Circle()
                    .fill(isTracking ? Color.white : Color.clear)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .frame(width: 200, height: 200)
                
                // Content
                VStack(spacing: 12) {
                    Image(systemName: isTracking ? "stop.fill" : "moon.fill")
                        .font(.system(size: 50))
                        .foregroundColor(isTracking ? .black : .white)
                    
                    Text(isTracking ? "Punch Out" : "Punch In")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(isTracking ? .black : .white)
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
}

#Preview {
    VStack {
        CircularPunchButton(
            isTracking: false,
            onPunchIn: { },
            onPunchOut: { }
        )
        
        CircularPunchButton(
            isTracking: true,
            onPunchIn: { },
            onPunchOut: { }
        )
    }
    .preferredColorScheme(.dark)
    .background(Color.black)
}
