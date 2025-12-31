//
//  SleepView.swift
//  SleepLedger
//
//  Main sleep tracking dashboard - Rebuilt for total UI overhaul
//

import SwiftUI
import SwiftData

struct SleepView: View {
    @StateObject private var trackingService: SleepTrackingService
    
    @Query(sort: \SleepSession.startTime, order: .reverse) private var allSessions: [SleepSession]
    @AppStorage("sleepGoalHours") private var sleepGoalHours: Double = 8.0
    
    init() {
        let context = ModelContext(ModelContainer.shared)
        _trackingService = StateObject(wrappedValue: SleepTrackingService(modelContext: context))
    }
    
    var body: some View {
        ZStack {
            // Abstract Background Ambience
            backgroundAmbience
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection
                        .padding(.top, 40)
                    
                    // Sleep Debt Ring
                    let totalDebt = trackingService.getCumulativeSleepDebt(days: 7)
                    let hours = Int(abs(totalDebt))
                    let minutes = Int((abs(totalDebt) - Double(hours)) * 60)
                    let progress = min(abs(totalDebt) / (sleepGoalHours * 7), 1.0)
                    
                    SleepDebtRing(
                        debtHours: hours,
                        debtMinutes: minutes,
                        progress: progress,
                        isDeficit: totalDebt < 0
                    )
                    .padding(.vertical, 20)
                    
                    // Stats Row
                    statsSummaryRow
                    
                    // Main Action Button
                    PulseButton(isTracking: trackingService.isTracking) {
                        handlePunchAction()
                    }
                    .padding(.vertical, 10)
                    
                    // Recent Session Card
                    if let lastSession = allSessions.filter({ $0.endTime != nil }).first {
                        TactileTimeCard(lastSession: lastSession)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.sleepBackground)
        .ignoresSafeArea(.all, edges: .top)
    }
    
    // MARK: - Background Components
    
    private var backgroundAmbience: some View {
        ZStack {
            Circle()
                .fill(Color.sleepPrimary.opacity(0.15))
                .frame(width: 600, height: 600)
                .blur(radius: 100)
                .offset(x: -200, y: -200)
            
            Circle()
                .fill(Color.sleepPrimaryGlow.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: 200, y: 400)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.sleepTextSecondary)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Text(greeting)
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.white)
            }
            Spacer()
            
            Button {
                // Notifications or Settings
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color(white: 0.1))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.05), lineWidth: 1))
            }
        }
    }
    
    // MARK: - Stats Summary
    
    private var statsSummaryRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                StatChip(label: "7-Day Avg", value: formatDuration(trackingService.getAverageSleepDuration(days: 7)))
                StatChip(label: "Quality", value: String(format: "%.0f", trackingService.getAverageSleepQuality(days: 7)))
                StatChip(label: "Consistency", value: "92%", valueColor: .sleepSuccess)
            }
            
            HStack(spacing: 8) {
                StatChip(label: "Avg", value: formatDuration(trackingService.getAverageSleepDuration(days: 7)), compact: true)
                StatChip(label: "Quality", value: String(format: "%.0f", trackingService.getAverageSleepQuality(days: 7)), compact: true)
                StatChip(label: "Consistency", value: "92%", valueColor: .sleepSuccess, compact: true)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<18: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    private func handlePunchAction() {
        if trackingService.isTracking {
            trackingService.punchOut()
        } else {
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
        }
    }
    
    private func formatDuration(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }
}

// MARK: - Supporting Views

struct StatChip: View {
    let label: String
    let value: String
    var valueColor: Color = .white
    var compact: Bool = false
    
    var body: some View {
        VStack(spacing: compact ? 2 : 4) {
            Text(label)
                .font(.system(size: compact ? 8 : 10, weight: .medium))
                .foregroundColor(.sleepTextTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(value)
                .font(.system(size: compact ? 14 : 16, weight: .semibold))
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, compact ? 12 : 16)
        .sleepGlassPanel()
    }
}

#Preview {
    SleepView()
        .preferredColorScheme(.dark)
}
