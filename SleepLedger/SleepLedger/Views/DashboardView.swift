//
//  DashboardView.swift
//  SleepLedger
//
//  Main dashboard with punch in/out and current session status
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var trackingService: SleepTrackingService
    @StateObject private var motionService = MotionDetectionService()
    
    @State private var showingSmartAlarmSheet = false
    @State private var targetWakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var smartAlarmEnabled = false
    
    init() {
        // This will be properly initialized in onAppear
        let context = ModelContext(try! ModelContainer(for: SleepSession.self, MovementData.self))
        _trackingService = StateObject(wrappedValue: SleepTrackingService(modelContext: context))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Main Punch In/Out Button
                    punchButton
                    
                    // Alarm Settings Info (when not tracking)
                    if !trackingService.isTracking {
                        alarmInfoCard
                    }
                    
                    // Current Session Info
                    if trackingService.isTracking, let session = trackingService.currentSession {
                        currentSessionCard(session: session)
                    }
                    
                    // Sleep Debt Summary
                    sleepDebtCard
                    
                    // Quick Stats
                    quickStatsCard
                }
                .padding()
            }
            .background(Color.sleepBackground)
            .navigationTitle("SleepLedger")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Set default sleep goal
                trackingService.defaultSleepGoalHours = 8.0
            }
        }
    }
    
    // MARK: - Punch Button
    
    private var punchButton: some View {
        CircularPunchButton(
            isTracking: trackingService.isTracking,
            onPunchIn: {
                // Read settings from AppStorage
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
                Image(systemName: "bed.double.fill")
                    .foregroundColor(.sleepPrimary)
                Text("Current Session")
                    .font(.headline)
                    .foregroundColor(.sleepTextPrimary)
                Spacer()
                Text(motionService.sleepStage.emoji)
                    .font(.title2)
            }
            
            Divider()
                .background(Color.sleepCardBorder)
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "clock.fill",
                    label: "Duration",
                    value: durationString(from: session.startTime),
                    color: .sleepPrimary
                )
                
                InfoRow(
                    icon: "waveform.path.ecg",
                    label: "Sleep Stage",
                    value: motionService.sleepStage.rawValue,
                    color: sleepStageColor(motionService.sleepStage)
                )
                
                InfoRow(
                    icon: "chart.bar.fill",
                    label: "Movement",
                    value: String(format: "%.0f%%", motionService.currentMovementIntensity * 100),
                    color: .sleepSecondary
                )
                
                if session.smartAlarmEnabled, let wakeTime = session.targetWakeTime {
                    InfoRow(
                        icon: "alarm.fill",
                        label: "Smart Alarm",
                        value: wakeTime.formatted(date: .omitted, time: .shortened),
                        color: .sleepSuccess
                    )
                }
            }
        }
        .padding()
        .sleepCard()
    }
    
    // MARK: - Sleep Debt Card
    
    private var sleepDebtCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .foregroundColor(.sleepSecondary)
                Text("7-Day Sleep Debt")
                    .font(.headline)
                    .foregroundColor(.sleepTextPrimary)
                Spacer()
            }
            
            let debt = trackingService.getCumulativeSleepDebt(days: 7)
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(String(format: "%.1f", abs(debt)))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(debt >= 0 ? .sleepSuccess : .sleepError)
                
                Text("hours")
                    .font(.title3)
                    .foregroundColor(.sleepTextSecondary)
            }
            
            Text(debt >= 0 ? "Sleep Surplus 🎉" : "Sleep Deficit ⚠️")
                .font(.subheadline)
                .foregroundColor(.sleepTextSecondary)
        }
        .padding()
        .sleepCard()
    }
    
    // MARK: - Quick Stats Card
    
    private var quickStatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.sleepPrimary)
                Text("7-Day Average")
                    .font(.headline)
                    .foregroundColor(.sleepTextPrimary)
                Spacer()
            }
            
            let quality = trackingService.getAverageSleepQuality(days: 7)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quality")
                        .font(.caption)
                        .foregroundColor(.sleepTextSecondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.0f", quality))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.sleepPrimary)
                        Text("%")
                            .font(.headline)
                            .foregroundColor(.sleepTextSecondary)
                    }
                }
                
                Spacer()
                
                qualityIndicator(quality: quality)
            }
        }
        .padding()
        .sleepCard()
    }
    
    // MARK: - Alarm Info Card
    
    private var alarmInfoCard: some View {
        NavigationLink(destination: SettingsView()) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "alarm.fill")
                        .foregroundColor(.sleepPrimary)
                    Text("Smart Alarm")
                        .font(.headline)
                        .foregroundColor(.sleepTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.sleepTextTertiary)
                }
                
                let smartAlarmEnabled = UserDefaults.standard.bool(forKey: "smartAlarmEnabled")
                let wakeTimeInterval = UserDefaults.standard.double(forKey: "wakeTimeInterval")
                
                if smartAlarmEnabled && wakeTimeInterval > 0 {
                    let wakeTime = Date(timeIntervalSinceReferenceDate: wakeTimeInterval)
                    HStack {
                        Text("Wake at")
                            .font(.subheadline)
                            .foregroundColor(.sleepTextSecondary)
                        Text(wakeTime.formatted(date: .omitted, time: .shortened))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.sleepPrimary)
                    }
                    
                    Text("30 min window for light sleep")
                        .font(.caption)
                        .foregroundColor(.sleepTextSecondary)
                } else {
                    Text("Tap to configure alarm in Settings")
                        .font(.subheadline)
                        .foregroundColor(.sleepTextSecondary)
                }
            }
            .padding()
            .sleepCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Smart Alarm Sheet
    
    private var smartAlarmSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable Smart Alarm", isOn: $smartAlarmEnabled)
                        .tint(.sleepPrimary)
                    
                    if smartAlarmEnabled {
                        DatePicker("Wake Time", selection: $targetWakeTime, displayedComponents: .hourAndMinute)
                            .tint(.sleepPrimary)
                        
                        Text("The alarm will trigger during light sleep within 20 minutes before your target time.")
                            .font(.caption)
                            .foregroundColor(.sleepTextSecondary)
                    }
                }
            }
            .navigationTitle("Smart Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingSmartAlarmSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Helper Functions
    
    private func handlePunchAction() {
        if trackingService.isTracking {
            trackingService.punchOut()
        } else {
            if smartAlarmEnabled {
                showingSmartAlarmSheet = true
            }
            trackingService.punchIn(
                smartAlarmEnabled: smartAlarmEnabled,
                targetWakeTime: smartAlarmEnabled ? targetWakeTime : nil
            )
        }
    }
    
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<6: return "Good Night"
        case 6..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    private var currentDateString: String {
        Date().formatted(date: .complete, time: .omitted)
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m ago"
        } else {
            return "\(minutes)m ago"
        }
    }
    
    private func durationString(from startDate: Date) -> String {
        let interval = Date().timeIntervalSince(startDate)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        return String(format: "%dh %02dm", hours, minutes)
    }
    
    private func sleepStageColor(_ stage: MotionDetectionService.SleepStage) -> Color {
        switch stage {
        case .deepSleep: return .sleepDeepSleep
        case .lightSleep: return .sleepLightSleep
        case .awake: return .sleepAwake
        }
    }
    
    private func qualityIndicator(quality: Double) -> some View {
        ZStack {
            Circle()
                .stroke(Color.sleepCardBorder, lineWidth: 8)
                .frame(width: 80, height: 80)
            
            Circle()
                .trim(from: 0, to: quality / 100)
                .stroke(
                    LinearGradient(
                        colors: [.sleepPrimary, .sleepSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
            
            Text(qualityEmoji(quality: quality))
                .font(.title)
        }
    }
    
    private func qualityEmoji(quality: Double) -> String {
        switch quality {
        case 90...100: return "🌟"
        case 70..<90: return "😊"
        case 50..<70: return "😐"
        default: return "😴"
        }
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.sleepTextSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.sleepTextPrimary)
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
}
