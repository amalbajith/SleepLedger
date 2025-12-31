//
//  CircularPunchButton.swift
//  SleepLedger
//
//  Circular punch in/out button with integrated smart alarm
//

import SwiftUI

struct CircularPunchButton: View {
    let isTracking: Bool
    let onPunchIn: (Date, Bool) -> Void
    let onPunchOut: () -> Void
    
    @State private var showingAlarmPicker = false
    @State private var smartAlarmEnabled = true
    @State private var wakeTime: Date = {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    @State private var isPressing = false
    
    var body: some View {
        VStack(spacing: 0) {
            if isTracking {
                trackingView
            } else {
                alarmSetupView
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
    }
    
    // MARK: - Alarm Setup View (Before Punch In)
    
    private var alarmSetupView: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text("Set Your Wake Time")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.sleepTextPrimary)
                
                Text("Smart alarm will wake you during light sleep")
                    .font(.caption)
                    .foregroundColor(.sleepTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Circular clock picker
            CircularClockPicker(selectedTime: $wakeTime)
            
            // Smart alarm toggle
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.sleepPrimary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Smart Alarm")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.sleepTextPrimary)
                    
                    Text("Wake during light sleep (30 min window)")
                        .font(.caption)
                        .foregroundColor(.sleepTextSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $smartAlarmEnabled)
                    .labelsHidden()
                    .tint(.sleepPrimary)
            }
            .padding()
            .sleepCard()
            
            // Punch In Button
            Button(action: handlePunchIn) {
                HStack(spacing: 12) {
                    Image(systemName: "moon.stars.fill")
                        .font(.title2)
                    
                    Text("Start Sleep Tracking")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        colors: [.sleepPrimary, .sleepSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .sleepPrimary.opacity(0.5), radius: 15, x: 0, y: 8)
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
    
    // MARK: - Actions
    
    private func handlePunchIn() {
        // Calculate wake time (30 minutes before selected time for the window)
        let calendar = Calendar.current
        let targetWakeTime = smartAlarmEnabled ? wakeTime : nil
        
        onPunchIn(targetWakeTime ?? Date(), smartAlarmEnabled)
    }
}

#Preview {
    VStack {
        CircularPunchButton(
            isTracking: false,
            onPunchIn: { _, _ in },
            onPunchOut: { }
        )
    }
    .preferredColorScheme(.dark)
    .background(Color.sleepBackground)
}
