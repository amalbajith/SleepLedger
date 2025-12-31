//
//  SessionDetailView.swift
//  SleepLedger
//
//  Detailed view for a specific sleep session
//

import SwiftUI

struct SessionDetailView: View {
    let session: SleepSession
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Quality Score
                    qualitySection
                    
                    // Time Info
                    timeInfoSection
                    
                    // Sleep Stages
                    sleepStagesSection
                    
                    // Movement Chart
                    movementChartSection
                    
                    // Notes
                    if let notes = session.notes, !notes.isEmpty {
                        notesSection(notes: notes)
                    }
                }
                .padding()
            }
            .background(Color.sleepBackground)
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var qualitySection: some View {
        VStack(spacing: 16) {
            if let quality = session.sleepQualityScore {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 12)
                        .frame(width: 150, height: 150)
                    
                    Circle()
                        .trim(from: 0, to: quality / 100)
                        .stroke(
                            LinearGradient(
                                colors: [.sleepPrimary, .sleepPrimaryGlow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: .sleepPrimary.opacity(0.3), radius: 10)
                    
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f", quality))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Quality")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Text(qualityDescription(quality: quality))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .sleepCard()
    }
    
    private var timeInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time Information")
                .font(.headline)
                .foregroundColor(.white)
            
            Divider().background(Color.white.opacity(0.05))
            
            DetailInfoRow(
                icon: "bed.double.fill",
                label: "Bedtime",
                value: session.startTime.formatted(date: .abbreviated, time: .shortened),
                color: .sleepPrimary
            )
            
            if let endTime = session.endTime {
                DetailInfoRow(
                    icon: "sunrise.fill",
                    label: "Wake Time",
                    value: endTime.formatted(date: .abbreviated, time: .shortened),
                    color: .sleepPrimaryGlow
                )
            }
            
            DetailInfoRow(
                icon: "clock.fill",
                label: "Total Duration",
                value: String(format: "%.1f hours", session.durationInHours ?? 0),
                color: .sleepPrimary
            )
            
            DetailInfoRow(
                icon: "target",
                label: "Sleep Goal",
                value: String(format: "%.1f hours", session.sleepGoalHours),
                color: .gray
            )
            
            if let debt = session.sleepDebt {
                DetailInfoRow(
                    icon: "chart.line.downtrend.xyaxis",
                    label: "Sleep Debt",
                    value: String(format: "%+.1f hours", debt),
                    color: debt >= 0 ? .sleepSuccess : .sleepError
                )
            }
        }
        .padding()
        .sleepCard()
    }
    
    private var sleepStagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Stages")
                .font(.headline)
                .foregroundColor(.white)
            
            Divider().background(Color.white.opacity(0.05))
            
            if let deepSleep = session.deepSleepDuration {
                DetailInfoRow(
                    icon: "moon.fill",
                    label: "Deep Sleep",
                    value: String(format: "%.0f minutes", deepSleep),
                    color: Color(hex: "#06b6d4")
                )
            }
            
            if let lightSleep = session.lightSleepDuration {
                DetailInfoRow(
                    icon: "moon.stars.fill",
                    label: "Light Sleep",
                    value: String(format: "%.0f minutes", lightSleep),
                    color: .sleepPrimary
                )
            }
        }
        .padding()
        .sleepCard()
    }
    
    private var movementChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Movement Activity")
                .font(.headline)
                .foregroundColor(.white)
            
            Divider().background(Color.white.opacity(0.05))
            
            if session.movementData.isEmpty {
                Text("No movement data available")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                SessionMovementChart(movementData: session.movementData)
                    .frame(height: 150)
            }
        }
        .padding()
        .sleepCard()
    }
    
    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(.white)
            
            Divider().background(Color.white.opacity(0.05))
            
            Text(notes)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .sleepCard()
    }
    
    private func qualityDescription(quality: Double) -> String {
        switch quality {
        case 90...100: return "Excellent sleep quality! 🌟"
        case 70..<90: return "Good sleep quality 😊"
        case 50..<70: return "Fair sleep quality 😐"
        default: return "Poor sleep quality 😴"
        }
    }
}

// MARK: - Supporting Views

struct DetailInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .font(.subheadline)
    }
}

struct SessionMovementChart: View {
    let movementData: [MovementData]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background grid
                VStack(spacing: 0) {
                    ForEach(0..<5) { _ in
                        Divider()
                            .background(Color.white.opacity(0.05))
                        Spacer()
                    }
                }
                
                // Movement bars
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(Array(movementData.enumerated()), id: \.offset) { index, data in
                        Rectangle()
                            .fill(movementColor(intensity: data.movementIntensity))
                            .frame(height: geometry.size.height * data.movementIntensity)
                    }
                }
            }
        }
    }
    
    private func movementColor(intensity: Double) -> Color {
        switch intensity {
        case 0.0..<0.3: return Color(hex: "#06b6d4") // Deep
        case 0.3..<0.7: return .sleepPrimary // Light
        default: return .white // Awake
        }
    }
}
