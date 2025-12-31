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
        GeometryReader { geometry in
            ZStack {
                let size = min(geometry.size.width, geometry.size.height)
                
                // Background Track
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: size * 0.033)
                
                // Progress Arc
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isDeficit ? Color.sleepError : Color.sleepSuccess,
                        style: StrokeStyle(lineWidth: size * 0.033, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: (isDeficit ? Color.sleepError : Color.sleepSuccess).opacity(0.4), radius: size * 0.03)
                
                VStack(spacing: size * 0.02) {
                    Text(isDeficit ? "SLEEP DEBT" : "SLEEP SURPLUS")
                        .font(.system(size: size * 0.045, weight: .bold))
                        .foregroundColor(.gray)
                        .tracking(1)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(debtHours)")
                            .font(.system(size: size * 0.2, weight: .thin, design: .rounded))
                        Text("h")
                            .font(.system(size: size * 0.1, weight: .light))
                            .foregroundColor(.gray)
                        
                        Text(" \(debtMinutes)")
                            .font(.system(size: size * 0.2, weight: .thin, design: .rounded))
                        Text("m")
                            .font(.system(size: size * 0.1, weight: .light))
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    
                    Text(isDeficit ? "Deficit" : "Surplus")
                        .font(.system(size: size * 0.045, weight: .bold))
                        .padding(.horizontal, size * 0.05)
                        .padding(.vertical, size * 0.016)
                        .background((isDeficit ? Color.sleepError : Color.sleepSuccess).opacity(0.1))
                        .foregroundColor(isDeficit ? .sleepError : .sleepSuccess)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke((isDeficit ? Color.sleepError : Color.sleepSuccess).opacity(0.2), lineWidth: 1)
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SleepDebtRing(debtHours: 1, debtMinutes: 30, progress: 0.75, isDeficit: true)
    }
}
