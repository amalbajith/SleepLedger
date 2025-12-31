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
            backgroundAmbience
            
            ScrollView {
                VStack(spacing: 24) {          // fixed spacing instead of geometry-based
                    headerSection
                        .padding(.top, 20)
                    
                    // --- Metrics ---
                    let filtered = allSessions.filter { $0.endTime != nil }
                    let recentSessions = filtered.filter {
                        $0.startTime >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                    }
                    
                    let totalDebt = recentSessions.compactMap { $0.sleepDebt }.reduce(0, +)
                    let hours = Int(abs(totalDebt))
                    let minutes = Int((abs(totalDebt) - Double(hours)) * 60)
                    let progress = min(abs(totalDebt) / (sleepGoalHours * 7), 1.0)
                    
                    let avgDuration = recentSessions.isEmpty
                        ? 0
                        : (recentSessions.compactMap { $0.durationInHours }.reduce(0, +)
                           / Double(recentSessions.count))
                    let avgQuality = recentSessions.isEmpty
                        ? 0
                        : (recentSessions.compactMap { $0.sleepQualityScore }.reduce(0, +)
                           / Double(recentSessions.count))
                    
                    // Sleep Debt Ring
                    SleepDebtRing(
                        debtHours: hours,
                        debtMinutes: minutes,
                        progress: progress,
                        isDeficit: totalDebt < 0
                    )
                    .frame(maxWidth: 260, maxHeight: 260)  // cap the size
                    .frame(maxWidth: .infinity)            // center horizontally
                    .padding(.vertical, 10)
                    
                    // Stats row
                    HStack(spacing: 8) {
                        StatChip(label: "Average", value: formatDuration(avgDuration))
                        StatChip(label: "Quality", value: String(format: "%.0f%%", avgQuality))
                        StatChip(label: "Consistency", value: "92%", valueColor: .sleepSuccess)
                    }
                    
                    // Main action button
                    PulseButton(isTracking: trackingService.isTracking) {
                        handlePunchAction()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    
                    // Recent session card
                    if let lastSession = filtered.first {
                        TactileTimeCard(lastSession: lastSession)
                    }
                    
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.sleepBackground)
        .ignoresSafeArea(.all, edges: .top)
    }
    
    // MARK: - Background
    
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
