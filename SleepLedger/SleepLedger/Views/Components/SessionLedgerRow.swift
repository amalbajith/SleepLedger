//
//  SessionLedgerRow.swift
//  SleepLedger
//
//  A detailed row for the session history list
//

import SwiftUI

struct SessionLedgerRow: View {
    let session: SleepSession
    
    var body: some View {
        HStack(spacing: 16) {
            // Date Box
            VStack(spacing: 2) {
                Text(session.startTime.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                Text(session.startTime.formatted(.dateTime.day()))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 48, height: 48)
            .background(Color(white: 0.15))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(qualityColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: qualityColor.opacity(0.5), radius: 4)
                    
                    Text(qualityLabel)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Text("\(session.startTime.formatted(date: .omitted, time: .shortened)) - \(session.endTime?.formatted(date: .omitted, time: .shortened) ?? "--:--")")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1fh", session.durationInHours ?? 0))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                if let quality = session.sleepQualityScore {
                    Text(String(format: "%.0f%%", quality))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(qualityColor)
                }
            }
        }
        .padding(16)
        .background(Color.sleepCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private var qualityColor: Color {
        guard let quality = session.sleepQualityScore else { return .gray }
        if quality >= 85 { return .sleepSuccess }
        if quality >= 70 { return .sleepPrimary }
        return .orange
    }
    
    private var qualityLabel: String {
        guard let quality = session.sleepQualityScore else { return "Unknown" }
        if quality >= 85 { return "Excellent Sleep" }
        if quality >= 70 { return "Good Sleep" }
        return "Fair Sleep"
    }
}
