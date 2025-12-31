//
//  HistoryView.swift
//  SleepLedger
//
//  Sleep session history with detailed view
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SleepSession.startTime, order: .reverse) private var sessions: [SleepSession]
    
    @State private var selectedSession: SleepSession?
    
    var body: some View {
        NavigationStack {
            Group {
                if sessions.filter({ $0.endTime != nil }).isEmpty {
                    emptyState
                } else {
                    sessionsList
                }
            }
            .background(Color.sleepBackground)
            .navigationTitle("Sleep History")
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.sleepPrimary, .sleepSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("No Sleep Sessions Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.sleepTextPrimary)
            
            Text("Start tracking your sleep from the Dashboard")
                .font(.subheadline)
                .foregroundColor(.sleepTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Sessions List
    
    private var sessionsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(completedSessions) { session in
                    SessionCard(session: session)
                        .onTapGesture {
                            selectedSession = session
                        }
                }
            }
            .padding()
        }
    }
    
    private var completedSessions: [SleepSession] {
        sessions.filter { $0.endTime != nil }
    }
}

// MARK: - Session Card

struct SessionCard: View {
    let session: SleepSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.startTime.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline)
                        .foregroundColor(.sleepTextPrimary)
                    
                    Text("\(session.startTime.formatted(date: .omitted, time: .shortened)) - \(session.endTime?.formatted(date: .omitted, time: .shortened) ?? "")")
                        .font(.caption)
                        .foregroundColor(.sleepTextSecondary)
                }
                
                Spacer()
                
                if let quality = session.sleepQualityScore {
                    QualityBadge(quality: quality)
                }
            }
            
            Divider()
                .background(Color.sleepCardBorder)
            
            // Stats Grid
            HStack(spacing: 20) {
                StatItem(
                    icon: "clock.fill",
                    label: "Duration",
                    value: String(format: "%.1fh", session.durationInHours ?? 0),
                    color: .sleepPrimary
                )
                
                if let debt = session.sleepDebt {
                    StatItem(
                        icon: "chart.line.downtrend.xyaxis",
                        label: "Debt",
                        value: String(format: "%+.1fh", debt),
                        color: debt >= 0 ? .sleepSuccess : .sleepError
                    )
                }
                
                if let deepSleep = session.deepSleepDuration {
                    StatItem(
                        icon: "moon.fill",
                        label: "Deep",
                        value: String(format: "%.0fm", deepSleep),
                        color: .sleepDeepSleep
                    )
                }
            }
            
            // Tags
            if !session.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(session.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.sleepPrimary.opacity(0.2))
                                .foregroundColor(.sleepPrimary)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding()
        .sleepCard()
    }
}

// MARK: - Session Detail View

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
                        .stroke(Color.sleepCardBorder, lineWidth: 12)
                        .frame(width: 150, height: 150)
                    
                    Circle()
                        .trim(from: 0, to: quality / 100)
                        .stroke(
                            LinearGradient(
                                colors: [.sleepPrimary, .sleepSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f", quality))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.sleepTextPrimary)
                        Text("Quality")
                            .font(.caption)
                            .foregroundColor(.sleepTextSecondary)
                    }
                }
                
                Text(qualityDescription(quality: quality))
                    .font(.subheadline)
                    .foregroundColor(.sleepTextSecondary)
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
                .foregroundColor(.sleepTextPrimary)
            
            Divider().background(Color.sleepCardBorder)
            
            InfoRow(
                icon: "bed.double.fill",
                label: "Bedtime",
                value: session.startTime.formatted(date: .abbreviated, time: .shortened),
                color: .sleepPrimary
            )
            
            if let endTime = session.endTime {
                InfoRow(
                    icon: "sunrise.fill",
                    label: "Wake Time",
                    value: endTime.formatted(date: .abbreviated, time: .shortened),
                    color: .sleepSecondary
                )
            }
            
            InfoRow(
                icon: "clock.fill",
                label: "Total Duration",
                value: String(format: "%.1f hours", session.durationInHours ?? 0),
                color: .sleepPrimary
            )
            
            InfoRow(
                icon: "target",
                label: "Sleep Goal",
                value: String(format: "%.1f hours", session.sleepGoalHours),
                color: .sleepTextSecondary
            )
            
            if let debt = session.sleepDebt {
                InfoRow(
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
                .foregroundColor(.sleepTextPrimary)
            
            Divider().background(Color.sleepCardBorder)
            
            if let deepSleep = session.deepSleepDuration {
                InfoRow(
                    icon: "moon.fill",
                    label: "Deep Sleep",
                    value: String(format: "%.0f minutes", deepSleep),
                    color: .sleepDeepSleep
                )
            }
            
            if let lightSleep = session.lightSleepDuration {
                InfoRow(
                    icon: "moon.stars.fill",
                    label: "Light Sleep",
                    value: String(format: "%.0f minutes", lightSleep),
                    color: .sleepLightSleep
                )
            }
            
            // Sleep stage distribution
            if let deepSleep = session.deepSleepDuration,
               let lightSleep = session.lightSleepDuration {
                let total = deepSleep + lightSleep
                if total > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Distribution")
                            .font(.caption)
                            .foregroundColor(.sleepTextSecondary)
                        
                        GeometryReader { geometry in
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.sleepDeepSleep)
                                    .frame(width: geometry.size.width * (deepSleep / total))
                                
                                Rectangle()
                                    .fill(Color.sleepLightSleep)
                                    .frame(width: geometry.size.width * (lightSleep / total))
                            }
                            .cornerRadius(8)
                        }
                        .frame(height: 20)
                    }
                }
            }
        }
        .padding()
        .sleepCard()
    }
    
    private var movementChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Movement Activity")
                .font(.headline)
                .foregroundColor(.sleepTextPrimary)
            
            Divider().background(Color.sleepCardBorder)
            
            if session.movementData.isEmpty {
                Text("No movement data available")
                    .font(.subheadline)
                    .foregroundColor(.sleepTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                MovementChart(movementData: session.movementData)
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
                .foregroundColor(.sleepTextPrimary)
            
            Divider().background(Color.sleepCardBorder)
            
            Text(notes)
                .font(.subheadline)
                .foregroundColor(.sleepTextSecondary)
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

struct QualityBadge: View {
    let quality: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption)
            Text(String(format: "%.0f%%", quality))
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [.sleepPrimary, .sleepSecondary],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.sleepTextPrimary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.sleepTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MovementChart: View {
    let movementData: [MovementData]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background grid
                VStack(spacing: 0) {
                    ForEach(0..<5) { _ in
                        Divider()
                            .background(Color.sleepCardBorder)
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
        case 0.0..<0.3: return .sleepDeepSleep
        case 0.3..<0.7: return .sleepLightSleep
        default: return .sleepAwake
        }
    }
}

#Preview {
    HistoryView()
        .preferredColorScheme(.dark)
}
