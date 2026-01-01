import SwiftUI
import SwiftData
import Combine

struct SleepView: View {
    // MARK: - Data & State
    @StateObject private var sleepManager: SleepTrackingService
    @Query(sort: \SleepSession.startTime, order: .reverse) private var allSessions: [SleepSession]
    @AppStorage("userName") private var userName = "Sleeper"
    
    // For live updates (duration timer)
    @State private var currentTime = Date()
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Session Config
    @State private var enableSmartAlarm = false
    @State private var targetWakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date().addingTimeInterval(86400)) ?? Date()
    
    // Layout Constants
    private let statsRowOffset: CGFloat = 90 // Adjust this value to move the stats row Up (-) or Down (+)
    private let ringOffset: CGFloat = 50 // Adjust this value to move the Ring Up (-) or Down (+)
    private let headerTopPadding: CGFloat = 10 // Adjust this value to move the Header Down (+)
    private let ringDiameter: CGFloat = 100 // Adjust this value to change the Ring Size (Diameter)
    
    // Theme
    // Alternative to Purple ("6B35F6"): "3D5AFE" (Indigo), "00E5FF" (Cyan), "FF4081" (Pink)
    private let accentColor = Color(hex: "3D5AFE") // Currently: Indigo/Blue
    
    init() {
        let context = ModelContext(ModelContainer.shared)
        _sleepManager = StateObject(wrappedValue: SleepTrackingService(modelContext: context))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "020014") // Deep dark purple/black
                .ignoresSafeArea()
            
            // Ambient Glow
            Circle()
                .fill(Color(hex: "FF4B4B").opacity(0.1))
                .blur(radius: 60)
                .frame(width: 300, height: 300)
                .offset(y: -100)
            
            VStack(spacing: 0) {
                ScrollView {
                    // Tighter spacing to allow overlap effect
                    VStack(spacing: 10) {
                        headerView
                            .padding(.top, headerTopPadding)
                        
                        sleepDebtRing
                            .offset(y: ringOffset) // Allow adjusting the ring position
                            .zIndex(0)
                        
                        // Check tracking state
                        if !sleepManager.isTracking {
                            statsRow
                                .padding(.top, statsRowOffset) // Move up to overlay the ring
                                .zIndex(1)
                        }
                        
                        Spacer()
                        
                        // Alarm Configuration
                        if !sleepManager.isTracking {
                            VStack(spacing: 12) {
                                Toggle(isOn: $enableSmartAlarm) {
                                    HStack {
                                        Image(systemName: enableSmartAlarm ? "alarm.fill" : "alarm")
                                            .foregroundStyle(enableSmartAlarm ? .white : .gray)
                                        Text("Smart Alarm")
                                            .foregroundStyle(.white)
                                            .fontWeight(.medium)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: accentColor))
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                if enableSmartAlarm {
                                    DatePicker("Wake Up Time", selection: $targetWakeTime, displayedComponents: .hourAndMinute)
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                        .environment(\.colorScheme, .dark)
                                        .padding(.vertical, 4)
                                }
                            }
                            .padding(.horizontal, 40)
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        Spacer().frame(height: 80)
                        
                        pulseButton
                            .padding(.bottom, 20)
                    }
                    .animation(.spring, value: sleepManager.isTracking)
                    .padding(.bottom, 120) // Space for tab bar
                }
            }
        }
        .onReceive(timer) { input in
            currentTime = input
        }
    }
    
    var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(date: .complete, time: .omitted).uppercased())
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.white.opacity(0.6))
                
                // Greeting with User Name
                Text(greeting)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    var sleepDebtRing: some View {
        // Logic: Full Circle
        let debt = sleepManager.getCumulativeSleepDebt(days: 7)
        let isSurplus = debt >= 0
        
        return ZStack {
            // Background Track (Full Circle)
            Circle()
                .stroke(Color.white.opacity(0.05), style: StrokeStyle(lineWidth: 25, lineCap: .round))
            
            // Progress Track (Full Circle)
            // If Surplus (Balanced), show full green circle.
            // If Deficit (Debt), show full red circle.
            Circle()
                .stroke(
                    LinearGradient(
                        colors: getRingGradientColors(debt: debt),
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    ),
                    style: StrokeStyle(lineWidth: 25, lineCap: .round)
                )
                .shadow(color: (isSurplus ? Color(hex: "4CD964") : Color(hex: "FF4B4B")).opacity(0.3), radius: 20, x: 0, y: 0)
            
            VStack(spacing: 8) {
                if sleepManager.isTracking {
                    Text("CURRENT SLEEP")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.white.opacity(0.6))
                    
                    Text(currentDurationString)
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.white)
                        .fontDesign(.monospaced)
                } else {
                    Text(isSurplus ? "SLEEP BALANCE" : "SLEEP DEBT")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.white.opacity(0.6))
                    
                    let hours = Int(abs(debt))
                    let minutes = Int((abs(debt) - Double(hours)) * 60)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(debt < 0 ? "-" : "+") 
                            .font(.system(size: 32, weight: .light))
                            .foregroundStyle(isSurplus ? Color(hex: "4CD964") : Color(hex: "FF4B4B"))
                        Text("\(hours)")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(.white)
                        Text("h")
                            .font(.title3)
                            .foregroundStyle(Color.white.opacity(0.6))
                        Text("\(minutes)")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(.white)
                        Text("m")
                            .font(.title3)
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                    
                    Text(isSurplus ? "Well Rested" : "Deficit")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(isSurplus ? Color(hex: "4CD964") : Color(hex: "FF6B6B"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background((isSurplus ? Color(hex: "4CD964") : Color(hex: "FF4B4B")).opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(width: sleepManager.isTracking ? 280 : 220, height: sleepManager.isTracking ? 280 : 220)
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: sleepManager.isTracking)
    }
    
    var statsRow: some View {
        HStack(spacing: 12) {
            let avgDuration = sleepManager.getAverageSleepDuration(days: 7)
            let avgQuality = sleepManager.getAverageSleepQuality(days: 7)
            let consistency = sleepManager.calculateSleepConsistency(days: 7)
            
            statCard(title: "7-DAY AVG", value: formatDuration(avgDuration), color: .white)
            statCard(title: "QUALITY", value: String(format: "%.0f", avgQuality), color: .white)
            statCard(title: "CONSISTENCY", value: "\(consistency)%", color: Color(hex: "4CD964"))
        }
        .padding(.horizontal)
    }
    

    
    func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.5))
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    var pulseButton: some View {
        Button(action: {
            withAnimation {
                // Toggle logic
                if sleepManager.isTracking {
                    sleepManager.punchOut()
                } else {
                    sleepManager.punchIn(
                        smartAlarmEnabled: enableSmartAlarm,
                        targetWakeTime: enableSmartAlarm ? targetWakeTime : nil
                    )
                }
            }
        }) {
            ZStack {
                Circle()
                    .fill(sleepManager.isTracking ? Color(hex: "FF4B4B") : accentColor)
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: (sleepManager.isTracking ? Color(hex: "FF4B4B") : accentColor).opacity(0.4),
                        radius: 20, x: 0, y: 10
                    )
                
                Image(systemName: sleepManager.isTracking ? "stop.fill" : "moon.fill")
                    .font(.title)
                    .foregroundStyle(.white)
            }
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Helpers
    
    private var greeting: String {
        if sleepManager.isTracking {
            return "Sweet Dreams, \(userName)"
        }
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12: return "Good Morning, \(userName)"
        case 12..<17: return "Good Afternoon, \(userName)"
        default: return "Good Evening, \(userName)"
        }
    }
    
    private var currentDurationString: String {
        guard sleepManager.isTracking, let start = sleepManager.currentSession?.startTime else {
            return "00:00:00"
        }
        let diff = currentTime.timeIntervalSince(start)
        let h = Int(diff) / 3600
        let m = (Int(diff) % 3600) / 60
        let s = Int(diff) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    private func formatDuration(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }

    private func getRingGradientColors(debt: Double) -> [Color] {
        // Surplus (Positive Debt)
        if debt >= 0 {
            if debt > 5.0 {
                // High Surplus: Very Light/Bright Green (Faded to Green)
                return [Color(hex: "69F0AE"), Color(hex: "B9F6CA")]
            } else if debt > 2.0 {
                // Medium Surplus: Standard Vibrant Green
                return [Color(hex: "00C853"), Color(hex: "69F0AE")]
            } else {
                // Low Surplus: Darker/Standard Green
                return [Color(hex: "2E7D32"), Color(hex: "00C853")]
            }
        } 
        // Deficit (Negative Debt)
        else {
            if debt < -5.0 {
                // High Deficit: Vibrant Deep Red (Less Black)
                return [Color(hex: "C62828"), Color(hex: "FF5252")] 
            } else if debt < -2.0 {
                // Medium Deficit: Standard Red
                return [Color(hex: "D32F2F"), Color(hex: "F44336")]
            } else {
                // Low Deficit: Lighter Red/Orange-ish
                return [Color(hex: "EF5350"), Color(hex: "FF8A80")]
            }
        }
    }
}

extension View {
    func purpleIconStyle() -> some View {
        self
            .font(.system(size: 14))
            .foregroundStyle(Color(hex: "3D5AFE"))
    }
}

#Preview {
    SleepView()
        .modelContainer(ModelContainer.shared)
}
