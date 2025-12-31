//
//  TactileTimeCard.swift
//  SleepLedger
//
//  Display for bedtime and wake up time with a tactile look
//

import SwiftUI

struct TactileTimeCard: View {
    let lastSession: SleepSession?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Previous Night", systemImage: "clock.arrow.2.circlepath")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(spacing: 20) {
                // Bedtime Row
                TimeRow(
                    label: "Fell Asleep",
                    timeString: lastSession?.startTime.formatted(date: .omitted, time: .shortened) ?? "--:--",
                    offset: -20
                )
                
                // Wake Up Row
                TimeRow(
                    label: "Woke Up",
                    timeString: lastSession?.endTime?.formatted(date: .omitted, time: .shortened) ?? "--:--",
                    offset: -50
                )
            }
        }
        .padding(20)
        .sleepCard()
    }
}

private struct TimeRow: View {
    let label: String
    let timeString: String
    let offset: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Spacer()
                Text(timeString)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            // Tactile Ruler
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.05))
                    .frame(height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                
                // Ruler Ticks Pattern
                HStack(spacing: 12) {
                    ForEach(0..<20) { i in
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 1, height: i % 5 == 0 ? 20 : 10)
                    }
                }
                .offset(x: offset)
                .mask(
                    LinearGradient(
                        colors: [.clear, .black, .black, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                // Center Indicator
                Rectangle()
                    .fill(Color.sleepPrimary)
                    .frame(width: 2, height: 48)
                    .shadow(color: Color.sleepPrimary.opacity(0.8), radius: 4)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        TactileTimeCard(lastSession: nil)
            .padding()
    }
}
