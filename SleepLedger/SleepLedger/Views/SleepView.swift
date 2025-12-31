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
        GeometryReader { outerGeometry in
            ZStack {
                // Abstract Background Ambience
                backgroundAmbience
                
                ScrollView {
                    VStack(spacing: outerGeometry.size.height * 0.03) {
                        // Header
                        headerSection
                            .padding(.top, 20)
                        
                        // Calculated Metrics (using @Query data to avoid blocking fetches)
                        let filtered = allSessions.filter { $0.endTime != nil }
                        let recentSessions = filtered.filter { $0.startTime >= Calendar.current.date(byAdding: .day, value: -7, to: Date())! }
                        
                        let totalDebt = recentSessions.compactMap { $0.sleepDebt }.reduce(0, +)
                        let hours = Int(abs(totalDebt))
                        let minutes = Int((abs(totalDebt) - Double(hours)) * 60)
                        let progress = min(abs(totalDebt) / (sleepGoalHours * 7), 1.0)
                        
                        let avgDuration = recentSessions.isEmpty ? 0 : (recentSessions.compactMap { $0.durationInHours }.reduce(0, +) / Double(recentSessions.count))
                        let avgQuality = recentSessions.isEmpty ? 0 : (recentSessions.compactMap { $0.sleepQualityScore }.reduce(0, +) / Double(recentSessions.count))
                        
                        // Sleep Debt Ring
                        let ringSize = min(outerGeometry.size.width * 0.6, outerGeometry.size.height * 0.28)
                        
                        SleepDebtRing(
                            debtHours: hours,
                            debtMinutes: minutes,
                            progress: progress,
                            isDeficit: totalDebt < 0
                        )
                        .frame(width: ringSize, height: ringSize)
                        .padding(.vertical, 10)
                        
                        // Stats Row (Passing pre-calculated values)
                        HStack(spacing: 8) {
                            StatChip(label: "Average", value: formatDuration(avgDuration))
                            StatChip(label: "Quality", value: String(format: "%.0f%%", avgQuality))
                            StatChip(label: "Consistency", value: "92%", valueColor: .sleepSuccess)
                        }
                        
                        // Main Action Button
                        PulseButton(isTracking: trackingService.isTracking) {
                            handlePunchAction()
                        }
                        .scaleEffect(outerGeometry.size.height < 700 ? 0.85 : 1.0)
                        .padding(.vertical, 5)
                        
                        // Recent Session Card
                        if let lastSession = filtered.first {
                            TactileTimeCard(lastSession: lastSession)
                                .scaleEffect(outerGeometry.size.height < 700 ? 0.9 : 1.0)
                        }
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)
            }
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
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.sleepTextTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 68)
        .padding(12)
        .background(.ultraThinMaterial.opacity(0.5))
        .background(Color.sleepGlassBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.sleepGlassBorder, lineWidth: 1)
        )
    }
}

#Preview {
    SleepView()
        .preferredColorScheme(.dark)
}
