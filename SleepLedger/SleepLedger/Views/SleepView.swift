import SwiftUI
import SwiftData

struct SleepView: View {
    // MARK: - Data & State
    @StateObject private var trackingService: SleepTrackingService
    @Query(sort: \SleepSession.startTime, order: .reverse) private var allSessions: [SleepSession]
    @AppStorage("sleepGoalHours") private var sleepGoalHours: Double = 8.0
    
    init() {
        let context = ModelContext(ModelContainer.shared)
        _trackingService = StateObject(wrappedValue: SleepTrackingService(modelContext: context))
    }
    
    var body: some View {
        ZStack {
            // 1. Dynamic Background
            backgroundAmbiencePane
            
            // 2. Main Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) { // Fixed spacing 20
                    // Header
                    headerSection
                    
                    // Logic: Derived Metrics
                    let completed = allSessions.filter { $0.endTime != nil }
                    let weekSessions = completed.filter { 
                        $0.startTime >= Calendar.current.date(byAdding: .day, value: -7, to: Date())! 
                    }
                    
                    let totalDebt = weekSessions.compactMap { $0.sleepDebt }.reduce(0, +)
                    let hours = Int(abs(totalDebt))
                    let minutes = Int((abs(totalDebt) - Double(hours)) * 60)
                    let debtProgress = min(abs(totalDebt) / (sleepGoalHours * 7), 1.0)
                    
                    let avgDuration = weekSessions.isEmpty ? 0 : (weekSessions.compactMap { $0.durationInHours }.reduce(0, +) / Double(weekSessions.count))
                    let avgQuality = weekSessions.isEmpty ? 0 : (weekSessions.compactMap { $0.sleepQualityScore }.reduce(0, +) / Double(weekSessions.count))
                    
                    // Hero Section: Sleep Debt Ring
                    SleepDebtRing(
                        debtHours: hours,
                        debtMinutes: minutes,
                        progress: debtProgress,
                        isDeficit: totalDebt < 0
                    )
                    .frame(width: 200, height: 200) // Fixed 200x200
                    
                    // Mid Section: Quick Stats (3-column layout)
                    HStack(spacing: 12) {
                        StatChip(label: "Average", value: formatDuration(avgDuration))
                        StatChip(label: "Quality", value: String(format: "%.0f%%", avgQuality))
                        StatChip(label: "Balance", value: totalDebt >= 0 ? "Surplus" : "Deficit", valueColor: totalDebt >= 0 ? .sleepSuccess : .sleepError)
                    }
                    
                    // Action: Punch Button
                    PulseButton(isTracking: trackingService.isTracking) {
                        handlePunchAction()
                    }
                    .padding(.vertical, 4)
                    
                    // Footer: Last Night Summary
                    if let lastSession = completed.first {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("RECENT HISTORY")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)
                                .padding(.leading, 4)
                            
                            TactileTimeCard(lastSession: lastSession)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 60)       // Exact padding requested
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }
        }
        .background(Color.sleepBackground)
        .ignoresSafeArea(.container, edges: .bottom) // Only bottom ignored
    }
    
    // MARK: - Components
    
    private var backgroundAmbiencePane: some View {
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
    
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(1.0)
                
                Text(greeting)
                    .font(.system(size: 34, weight: .light))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button {
                // Settings action
            } label: {
                Image(systemName: "bell.badge")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.1)))
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

// MARK: - Supporting Components

struct StatChip: View {
    let label: String
    let value: String
    var valueColor: Color = .white
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium)) // Fixed size 11
                .foregroundColor(.white.opacity(0.8))      // Visible text
                .textCase(.uppercase)
                .tracking(0.5)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(value)
                .font(.system(size: 24, weight: .semibold)) // Fixed size 24
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72) // Fixed height 72
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20) // Corner radius 20
                .fill(.ultraThinMaterial.opacity(0.3))
                .background(Color.sleepGlassBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    SleepView()
        .preferredColorScheme(.dark)
}
