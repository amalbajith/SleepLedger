//
//  RingGauge.swift
//  SleepLedger
//
//  Circular gauge for sleep debt visualization
//

import SwiftUI

struct RingGauge: View {
    let debtHours: Double
    let goalHours: Double
    
    private var percentage: Double {
        let debt = abs(debtHours)
        return min(debt / goalHours, 1.0)
    }
    
    private var isDeficit: Bool {
        debtHours < 0
    }
    
    var body: some View {
        ZStack {
            // Background Track
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 8)
                .frame(width: 200, height: 200)
            
            // Progress Arc
            Circle()
                .trim(from: 0, to: percentage)
                .stroke(
                    isDeficit ? Color.sleepError : Color.sleepSuccess,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .shadow(color: (isDeficit ? Color.sleepError : Color.sleepSuccess).opacity(0.4), radius: 8)
            
            // Center Content
            VStack(spacing: 4) {
                Text("SLEEP BALANCE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.sleepTextTertiary)
                    .tracking(2)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    let hours = Int(abs(debtHours))
                    let minutes = Int((abs(debtHours) - Double(hours)) * 60)
                    
                    Text("\(isDeficit ? "-" : "+")\(hours)")
                        .font(.system(size: 48, weight: .thin))
                    Text("h")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.sleepTextTertiary)
                    
                    Text("\(minutes)")
                        .font(.system(size: 48, weight: .thin))
                    Text("m")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.sleepTextTertiary)
                }
                .foregroundColor(.white)
                
                // Status Chip
                Text(isDeficit ? "Deficit" : "Surplus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isDeficit ? .sleepError : .sleepSuccess)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background((isDeficit ? Color.sleepError : Color.sleepSuccess).opacity(0.1))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke((isDeficit ? Color.sleepError : Color.sleepSuccess).opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 40) {
            RingGauge(debtHours: -1.33, goalHours: 8.0)
            RingGauge(debtHours: 0.5, goalHours: 8.0)
        }
    }
}
