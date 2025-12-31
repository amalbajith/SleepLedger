//
//  SleepDebtRing.swift
//  SleepLedger
//
//  A vibrant sleep debt visualization ring
//

import SwiftUI

struct SleepDebtRing: View {
    let debtHours: Int
    let debtMinutes: Int
    let progress: Double // 0.0 to 1.0
    let isDeficit: Bool
    
    var body: some View {
        ZStack {
            // Background Track
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 8)
            
            // Progress Arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    isDeficit ? Color.sleepError : Color.sleepSuccess,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: (isDeficit ? Color.sleepError : Color.sleepSuccess).opacity(0.4), radius: 8)
            
            VStack(spacing: 4) {
                Text(isDeficit ? "SLEEP DEBT" : "SLEEP SURPLUS")
                    .font(.caption2.bold())
                    .foregroundColor(.gray)
                    .tracking(1)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(debtHours)")
                        .font(.system(size: 48, weight: .thin, design: .rounded))
                    Text("h")
                        .font(.title3.weight(.light))
                        .foregroundColor(.gray)
                    
                    Text(" \(debtMinutes)")
                        .font(.system(size: 48, weight: .thin, design: .rounded))
                    Text("m")
                        .font(.title3.weight(.light))
                        .foregroundColor(.gray)
                }
                .foregroundColor(.white)
                
                Text(isDeficit ? "Deficit" : "Surplus")
                    .font(.caption2.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background((isDeficit ? Color.sleepError : Color.sleepSuccess).opacity(0.1))
                    .foregroundColor(isDeficit ? .sleepError : .sleepSuccess)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke((isDeficit ? Color.sleepError : Color.sleepSuccess).opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .frame(width: 240, height: 240)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SleepDebtRing(debtHours: 1, debtMinutes: 30, progress: 0.75, isDeficit: true)
    }
}
