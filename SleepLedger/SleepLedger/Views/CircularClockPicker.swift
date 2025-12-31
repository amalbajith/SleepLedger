//
//  CircularClockPicker.swift
//  SleepLedger
//
//  Circular clock-style time picker for smart alarm
//

import SwiftUI

struct CircularClockPicker: View {
    @Binding var selectedTime: Date
    @State private var angle: Double = 0
    
    private let clockSize: CGFloat = 280
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.sleepPrimary.opacity(0.3), .sleepSecondary.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 40
                )
                .frame(width: clockSize, height: clockSize)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progressValue)
                .stroke(
                    LinearGradient(
                        colors: [.sleepPrimary, .sleepSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 40, lineCap: .round)
                )
                .frame(width: clockSize, height: clockSize)
                .rotationEffect(.degrees(-90))
            
            // Hour markers
            ForEach(0..<12) { hour in
                HourMarker(hour: hour, size: clockSize)
            }
            
            // Center content
            VStack(spacing: 8) {
                Text(selectedTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.sleepTextPrimary)
                
                Text("Wake up time")
                    .font(.caption)
                    .foregroundColor(.sleepTextSecondary)
                
                Text("30 min window")
                    .font(.caption2)
                    .foregroundColor(.sleepPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.sleepPrimary.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Draggable handle
            Circle()
                .fill(Color.white)
                .frame(width: 24, height: 24)
                .shadow(color: .sleepPrimary.opacity(0.5), radius: 8, x: 0, y: 4)
                .offset(y: -clockSize / 2)
                .rotationEffect(.degrees(angle))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let vector = CGVector(dx: value.location.x - clockSize / 2, dy: value.location.y - clockSize / 2)
                            let radians = atan2(vector.dy, vector.dx)
                            var newAngle = radians * 180 / .pi + 90
                            if newAngle < 0 { newAngle += 360 }
                            
                            angle = newAngle
                            updateTime(from: newAngle)
                        }
                )
        }
        .onAppear {
            angle = angleFromTime(selectedTime)
        }
    }
    
    private var progressValue: Double {
        angle / 360.0
    }
    
    private func angleFromTime(_ time: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        let totalMinutes = Double(hour * 60 + minute)
        return (totalMinutes / 1440.0) * 360.0 // 1440 minutes in a day
    }
    
    private func updateTime(from angle: Double) {
        let totalMinutes = Int((angle / 360.0) * 1440.0)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        let calendar = Calendar.current
        if let newTime = calendar.date(bySettingHour: hours, minute: minutes, second: 0, of: selectedTime) {
            selectedTime = newTime
        }
    }
}

struct HourMarker: View {
    let hour: Int
    let size: CGFloat
    
    var body: some View {
        VStack {
            Text("\(hour == 0 ? 12 : hour)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.sleepTextTertiary)
            Spacer()
        }
        .frame(height: size / 2 - 30)
        .rotationEffect(.degrees(Double(hour) * 30))
        .offset(y: -size / 2 + 15)
        .rotationEffect(.degrees(Double(hour) * -30))
    }
}

#Preview {
    CircularClockPicker(selectedTime: .constant(Date()))
        .preferredColorScheme(.dark)
        .padding()
        .background(Color.sleepBackground)
}
