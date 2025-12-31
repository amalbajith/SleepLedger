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
    
    // Layout Constants
    private let statsRowOffset: CGFloat = 90 // Adjust this value to move the stats row Up (-) or Down (+)
    private let ringOffset: CGFloat = 50 // Adjust this value to move the Ring Up (-) or Down (+)
    private let headerTopPadding: CGFloat = 10 // Adjust this value to move the Header Down (+)
    
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
                        if sleepManager.isTracking {
                            activeSleepView
                        } else {
                            statsRow
                                .padding(.top, statsRowOffset) // Move up to overlay the ring
                                .zIndex(1)
                        }
                        
                        Spacer().frame(height: 20)
                        
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
            
            Button(action: {}) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
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
                        colors: isSurplus 
                            ? [Color(hex: "4CD964"), Color(hex: "34D399")] 
                            : [Color(hex: "FF4B4B"), Color(hex: "FF8F70")],
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
        .frame(height: 260) // Standard size for full circle
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
    
    var activeSleepView: some View {
        VStack {
            Text("Tracking Sleep Stages...")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
            
            // Placeholder for real-time accelerometer visualization
            HStack(spacing: 4) {
                ForEach(0..<10) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "6B35F6"))
                        .frame(width: 4, height: CGFloat.random(in: 10...30))
                }
            }
            .frame(height: 40)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                    sleepManager.punchIn()
                }
            }
        }) {
            ZStack {
                Circle()
                    .fill(sleepManager.isTracking ? Color(hex: "FF4B4B") : Color(hex: "6B35F6"))
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: (sleepManager.isTracking ? Color(hex: "FF4B4B") : Color(hex: "6B35F6")).opacity(0.4),
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
}

extension View {
    func purpleIconStyle() -> some View {
        self
            .font(.system(size: 14))
            .foregroundStyle(Color(hex: "6B35F6"))
    }
}

#Preview {
    SleepView()
        .modelContainer(ModelContainer.shared)
}
