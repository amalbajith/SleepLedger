//
//  SummaryRing.swift
//  SleepLedger
//
//  Circular ring component for metrics summary
//

import SwiftUI

struct SummaryRing: View {
    let progress: Double // 0.0 to 1.0
    let label: String
    let sublabel: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: 6)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.4), radius: 4)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            .frame(width: 80, height: 80)
            
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(sublabel)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.sleepCardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: 12) {
            SummaryRing(progress: 0.85, label: "Duration", sublabel: "85% Goal", icon: "clock", color: .sleepPrimary)
            SummaryRing(progress: 0.92, label: "Quality", sublabel: "92% Avg", icon: "star.fill", color: Color(hex: "#7c3aed"))
            SummaryRing(progress: 0.25, label: "Deep", sublabel: "1h 45m", icon: "waveform.path.ecg", color: Color(hex: "#06b6d4"))
        }
        .padding()
    }
}
