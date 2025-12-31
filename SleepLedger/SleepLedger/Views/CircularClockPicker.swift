//
//  CircularClockPicker.swift
//  SleepLedger
//
//  Circular clock-style time picker for smart alarm
//

import SwiftUI

struct CircularClockPicker: View {
    @Binding var selectedTime: Date
    @State private var dragAngle: Double = 0
    
    private let clockSize: CGFloat = 260
    private let lineWidth: CGFloat = 32
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.sleepCardBorder, lineWidth: lineWidth)
                .frame(width: clockSize, height: clockSize)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: progressValue)
                .stroke(
                    LinearGradient(
                        colors: [.sleepPrimary, .sleepSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: clockSize, height: clockSize)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragAngle)
            
            // Hour markers (simplified - only key hours)
            ForEach([0, 3, 6, 9, 12, 15, 18, 21], id: \.self) { hour in
                HourMarker(hour: hour, clockSize: clockSize)
            }
            
            // Center content
            VStack(spacing: 12) {
                Text(selectedTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.sleepTextPrimary)
                    .monospacedDigit()
                
                Text("Wake up time")
                    .font(.subheadline)
                    .foregroundColor(.sleepTextSecondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.caption2)
                    Text("30 min window")
                        .font(.caption)
                }
                .foregroundColor(.sleepPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.sleepPrimary.opacity(0.15))
                .cornerRadius(12)
            }
            
            // Draggable knob
            Circle()
                .fill(Color.white)
                .frame(width: 28, height: 28)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .overlay(
                    Circle()
                        .stroke(Color.sleepPrimary, lineWidth: 3)
                )
                .offset(y: -(clockSize / 2 + lineWidth / 2))
                .rotationEffect(.degrees(dragAngle))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateAngle(at: value.location)
                        }
                )
        }
        .frame(width: clockSize + 60, height: clockSize + 60)
        .onAppear {
            dragAngle = calculateAngle(from: selectedTime)
        }
    }
    
    private var progressValue: Double {
        (dragAngle + 90) / 360.0
    }
    
    private func updateAngle(at location: CGPoint) {
        // Calculate center of the circle
        let center = CGPoint(x: (clockSize + 60) / 2, y: (clockSize + 60) / 2)
        
        // Calculate angle from center to touch point
        let deltaX = location.x - center.x
        let deltaY = location.y - center.y
        
        var angle = atan2(deltaY, deltaX) * 180 / .pi
        angle += 90 // Adjust so 0° is at top
        
        if angle < 0 {
            angle += 360
        }
        
        // Snap to 15-minute intervals for smoother UX
        let minuteAngle = angle / 360.0 * 1440.0 // Total minutes in day
        let snappedMinutes = round(minuteAngle / 15.0) * 15.0
        angle = (snappedMinutes / 1440.0) * 360.0
        
        dragAngle = angle
        updateTime(from: angle)
    }
    
    private func calculateAngle(from date: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        let totalMinutes = Double(hour * 60 + minute)
        return (totalMinutes / 1440.0) * 360.0
    }
    
    private func updateTime(from angle: Double) {
        let totalMinutes = Int((angle / 360.0) * 1440.0)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hours
        components.minute = minutes
        components.second = 0
        
        if let newTime = calendar.date(from: components) {
            selectedTime = newTime
        }
    }
}

struct HourMarker: View {
    let hour: Int
    let clockSize: CGFloat
    
    private var displayHour: String {
        if hour == 0 {
            return "12am"
        } else if hour < 12 {
            return "\(hour)am"
        } else if hour == 12 {
            return "12pm"
        } else {
            return "\(hour - 12)pm"
        }
    }
    
    private var angle: Double {
        Double(hour) * 15.0 // 360° / 24 hours = 15° per hour
    }
    
    var body: some View {
        Text(displayHour)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.sleepTextTertiary)
            .offset(y: -(clockSize / 2 + 35))
            .rotationEffect(.degrees(angle))
    }
}

#Preview {
    CircularClockPicker(selectedTime: .constant(Date()))
        .preferredColorScheme(.dark)
        .padding()
        .background(Color.sleepBackground)
}
