//
//  SleepView.swift
//  SleepLedger
//
//  Main sleep tracking screen - optimized for quick punch in/out
//

import SwiftUI
import SwiftData

struct SleepView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var trackingService: SleepTrackingService
    @StateObject private var motionService = MotionDetectionService()
    
    @Query(sort: \SleepSession.startTime, order: .reverse) private var allSessions: [SleepSession]
    
    init() {
        let context = ModelContext(ModelContainer.shared)
        let motion = MotionDetectionService()
        _trackingService = StateObject(wrappedValue: SleepTrackingService(modelContext: context, motionService: motion))
        _motionService = StateObject(wrappedValue: motion)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero: Punch Button
                    punchButton
                        .padding(.top, 20)
                    
                    // Current Session or Last Night Summary
                    if trackingService.isTracking, let session = trackingService.currentSession {
                        currentSessionCard(session: session)
                    } else if let lastSession = completedSessions.first {
                        lastNightSummary(session: lastSession)
                    }
                    
                    // Quick Recent Sessions (last 3)
                    if !completedSessions.isEmpty {
                        recentSessionsSection
                    }
                }
                .padding()
            }
            .background(Color.sleepBackground)
            .navigationTitle("Sleep")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.sleepTextSecondary)
                    }
                }
            }
            .onAppear {
                trackingService.defaultSleepGoalHours = 8.0
            }
        }
    }
    
    // MARK: - Punch Button
    
    private var punchButton: some View {
        CircularPunchButton(
            isTracking: trackingService.isTracking,
            onPunchIn: {
                let smartAlarmEnabled = UserDefaults.standard.bool(forKey: "smartAlarmEnabled")
                let wakeTimeInterval = UserDefaults.standard.double(forKey: "wakeTimeInterval")
                
                let wakeTime: Date?
                if smartAlarmEnabled && wakeTimeInterval > 0 {
                    wakeTime = Date(timeIntervalSinceReferenceDate: wakeTimeInterval)
                } else {
                    wakeTime = nil
                }
                
                trackingService.punchIn(
                    smartAlarmEnabled: smartAlarmEnabled,
                    targetWakeTime: wakeTime
                )
            },
            onPunchOut: {
                trackingService.punchOut()
            }
        )
    }
    
    // MARK: - Current Session Card
    
    private func currentSessionCard(session: SleepSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "moon.zzz.fill")
                    .foregroundColor(.sleepPrimary)
                Text("Tracking Sleep")
                    .font(.headline)
                    .foregroundColor(.sleepTextPrimary)
                Spacer()
                Circle()
                    .fill(Color.sleepSuccess)
                    .frame(width: 8, height: 8)
            }
            
            Divider().background(Color.sleepCardBorder)
            
            HStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Started")
                        .font(.caption)
                        .foregroundColor(.sleepTextSecondary)
                    Text(session.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.sleepTextPrimary)
                }
                
                if let duration = session.duration {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.sleepTextSecondary)
                        Text(formatDuration(duration))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.sleepPrimary)
                    }
                }
            }
        }
        .padding()
        .sleepCard()
    }
    
    // MARK: - Last Night Summary
    
    private func lastNightSummary(session: SleepSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sunrise.fill")
                    .foregroundColor(.sleepSecondary)
                Text("Last Night")
                    .font(.headline)
                    .foregroundColor(.sleepTextPrimary)
                Spacer()
                if let quality = session.sleepQualityScore {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(qualityColor(quality))
                            .frame(width: 8, height: 8)
                        Text(String(format: "%.0f%%", quality))
                            .font(.subheadline)
                            .foregroundColor(.sleepTextSecondary)
                    }
                }
            }
            
            Divider().background(Color.sleepCardBorder)
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.sleepTextSecondary)
                    Text(String(format: "%.1fh", session.durationInHours ?? 0))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.sleepPrimary)
                }
                
                if let debt = session.sleepDebt, debt != 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("vs Goal")
                            .font(.caption)
                            .foregroundColor(.sleepTextSecondary)
                        HStack(spacing: 4) {
                            Image(systemName: debt >= 0 ? "arrow.up" : "arrow.down")
                                .font(.caption)
                            Text(String(format: "%.1fh", abs(debt)))
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(debt >= 0 ? .sleepSuccess : .sleepError)
                    }
                }
            }
        }
        .padding()
        .sleepCard()
    }
    
    // MARK: - Recent Sessions Section
    
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent")
                    .font(.headline)
                    .foregroundColor(.sleepTextPrimary)
                Spacer()
                NavigationLink(destination: JournalView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.sleepPrimary)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(Array(completedSessions.prefix(3))) { session in
                    CompactSessionRow(session: session)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var completedSessions: [SleepSession] {
        allSessions.filter { $0.endTime != nil }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    private func qualityColor(_ quality: Double) -> Color {
        switch quality {
        case 80...100: return .sleepSuccess
        case 60..<80: return .sleepPrimary
        default: return .sleepWarning
        }
    }
}

// MARK: - Compact Session Row

struct CompactSessionRow: View {
    let session: SleepSession
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(session.startTime.formatted(.dateTime.day()))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.sleepTextPrimary)
                Text(session.startTime.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption2)
                    .foregroundColor(.sleepTextSecondary)
            }
            .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "%.1fh", session.durationInHours ?? 0))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.sleepTextPrimary)
                
                Text(session.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.sleepTextSecondary)
            }
            
            Spacer()
            
            if let quality = session.sleepQualityScore {
                HStack(spacing: 4) {
                    Circle()
                        .fill(qualityColor(quality))
                        .frame(width: 6, height: 6)
                    Text(String(format: "%.0f%%", quality))
                        .font(.caption)
                        .foregroundColor(.sleepTextSecondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.sleepCardBackground)
        .cornerRadius(8)
    }
    
    private func qualityColor(_ quality: Double) -> Color {
        switch quality {
        case 80...100: return .sleepSuccess
        case 60..<80: return .sleepPrimary
        default: return .sleepWarning
        }
    }
}

#Preview {
    SleepView()
        .preferredColorScheme(.dark)
}
