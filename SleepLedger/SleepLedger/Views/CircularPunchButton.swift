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
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.sleepPrimary, .sleepSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Set Your Wake Time")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.sleepTextPrimary)
                
                Text("Smart alarm will wake you during light sleep")
                    .font(.caption)
                    .foregroundColor(.sleepTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Time Picker Card
            VStack(spacing: 16) {
                // Smart Alarm Toggle
                HStack {
                    Image(systemName: smartAlarmEnabled ? "brain.head.profile.fill" : "brain.head.profile")
                        .foregroundColor(.sleepPrimary)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Smart Alarm")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.sleepTextPrimary)
                        
                        Text("30 min window before wake time")
                            .font(.caption)
                            .foregroundColor(.sleepTextSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $smartAlarmEnabled)
                        .labelsHidden()
                        .tint(.sleepPrimary)
                }
                
                if smartAlarmEnabled {
                    Divider()
                        .background(Color.sleepCardBorder)
                    
                    // Time Picker
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "alarm.fill")
                                .foregroundColor(.sleepSecondary)
                            Text("Wake Time")
                                .font(.subheadline)
                                .foregroundColor(.sleepTextPrimary)
                            Spacer()
                        }
                        
                        DatePicker(
                            "",
                            selection: $wakeTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .tint(.sleepPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding()
            .sleepCard()
            
            // Large Circular Punch In Button
            Button(action: handlePunchIn) {
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.sleepPrimary.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 90,
                                endRadius: 130
                            )
                        )
                        .frame(width: 260, height: 260)
                    
                    // Main button
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.sleepPrimary, .sleepSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 180, height: 180)
                        .shadow(color: .sleepPrimary.opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 50))
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
