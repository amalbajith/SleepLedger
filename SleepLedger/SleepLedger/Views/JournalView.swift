import SwiftUI
import SwiftData

struct JournalView: View {
    @State private var selectedFilter = "This Week"
    // Removed "This Month" to avoid redundancy
    let filters = ["This Week", "Last 30 Days", "All Time"]
    
    @Query(sort: \SleepSession.startTime, order: .reverse) private var sessions: [SleepSession]
    @AppStorage("sleepGoalHours") private var sleepGoalHours: Double = 8.0
    
    // Derived Sessions based on filter
    var filteredSessions: [SleepSession] {
        let now = Date()
        let calendar = Calendar.current
        
        switch selectedFilter {
        case "This Week":
            let startDate = calendar.date(byAdding: .day, value: -7, to: now)!
            return sessions.filter { $0.startTime >= startDate }
        case "Last 30 Days":
            let startDate = calendar.date(byAdding: .day, value: -30, to: now)!
            return sessions.filter { $0.startTime >= startDate }
        default: // All Time
            return sessions
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        filterTabs
                        
                        trendsSection
                        
                        summarySection
                        
                        ledgerSection
                    }
                    .padding(.bottom, 100) // Space for tab bar
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    var headerView: some View {
        HStack {
            Spacer()
            
            Text("History")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.leading, 24)
            
            Spacer()
            
            Image(systemName: "calendar")
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: "6B35F6"))
        }
        .overlay(alignment: .center) {
            Text("History")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            }
        .padding()
        .background(Color.black)
    }
    
    var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filters, id: \.self) { filter in
                    Button(action: { 
                        withAnimation {
                            selectedFilter = filter 
                        }
                    }) {
                        Text(filter)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(selectedFilter == filter ? .white : .gray)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ? Color(hex: "6B35F6") : Color(hex: "1C1C1E"))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Trends Section
    
    var trendsSection: some View {
        let (avgDuration, pctChange, isUp) = calculateTrends()
        let label = selectedFilter == "All Time" ? "AVG SLEEP (Total)" : "AVG SLEEP (\(selectedFilter))"
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trends")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(label.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gray)
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Average Duration")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        HStack(spacing: 8) {
                            Text(avgDuration)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            // Only show trend percentage if not "All Time" (since previous period comparison is weird for all time)
                            if selectedFilter != "All Time" && filteredSessions.count > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                                    Text("\(String(format: "%.1f", abs(pctChange)))%")
                                }
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(isUp ? Color(hex: "4CD964") : Color(hex: "FF6B6B"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background((isUp ? Color(hex: "4CD964") : Color(hex: "FF6B6B")).opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    Spacer()
                }
                
                // Graph
                let graphPoints = calculateGraphPoints()
                WaveGraphView(dataPoints: graphPoints)
                    .frame(height: 100)
                
                // X-Axis
                HStack {
                    ForEach(getGraphLabels(), id: \.self) { label in
                        Text(label)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color(hex: "1C1C1E"), Color(hex: "101012")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }
    
    // MARK: - Summary Section
    
    var summarySection: some View {
        let active = filteredSessions
        let count = Double(active.count)
        
        let avgQuality = active.isEmpty ? 0 : Int(active.compactMap { $0.sleepQualityScore }.reduce(0, +) / count)
        let deepSleepAvg = calculateAverageDeepSleep(for: active)
        let avgDurationVal = active.isEmpty ? 0 : (active.compactMap { $0.durationInHours }.reduce(0, +) / count)
        let goalPct = min(avgDurationVal / sleepGoalHours, 1.0) * 100
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                summaryCard(title: "Duration", value: "\(Int(goalPct))% Goal", icon: "clock.fill", color: Color(hex: "6B35F6"), progress: avgDurationVal / sleepGoalHours)
                
                summaryCard(title: "Quality", value: "\(avgQuality)% Avg", icon: "star.fill", color: Color(hex: "8B5CF6"), progress: Double(avgQuality) / 100.0)
                
                summaryCard(title: "Deep", value: deepSleepAvg, icon: "water.waves", color: Color(hex: "22D3EE"), progress: 0.25)
            }
            .padding(.horizontal)
        }
    }
    
    func summaryCard(title: String, value: String, icon: String, color: Color, progress: Double) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
            }
            .frame(width: 48, height: 48)
            .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 0)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Text(value)
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(hex: "1C1C1E"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Ledger Section
    
    var ledgerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ledger")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(filteredSessions.count) ENTRIES")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gray)
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                if filteredSessions.isEmpty {
                    Text("No sleep sessions found for this period.")
                    .foregroundStyle(.gray)
                    .padding()
                } else {
                    ForEach(filteredSessions) { session in
                        if let endTime = session.endTime {
                            ledgerRow(
                                day: session.startTime.formatted(.dateTime.weekday(.abbreviated)).uppercased(),
                                date: session.startTime.formatted(.dateTime.day()),
                                status: scoreToStatus(Int(session.sleepQualityScore ?? 0)),
                                time: "\(session.startTime.formatted(date: .omitted, time: .shortened)) - \(endTime.formatted(date: .omitted, time: .shortened))",
                                duration: formatDuration(endTime.timeIntervalSince(session.startTime)),
                                score: "\(Int(session.sleepQualityScore ?? 0))%",
                                dotColor: scoreToColor(Int(session.sleepQualityScore ?? 0)),
                                scoreColor: scoreToColor(Int(session.sleepQualityScore ?? 0))
                            )
                        } else {
                            // Active Session
                            HStack {
                                Circle()
                                    .fill(Color(hex: "4CD964"))
                                    .frame(width: 8, height: 8)
                                    .pulseEffect()
                                Text("Sleeping now...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("Started " + session.startTime.formatted(date: .omitted, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            .padding()
                            .background(Color(hex: "1C1C1E"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "4CD964").opacity(0.3), lineWidth: 1))
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .animation(.default, value: selectedFilter)
    }
    
    // MARK: - Logic Helpers
    
    private func calculateTrends() -> (String, Double, Bool) {
        let periodDays = (selectedFilter == "Last 30 Days") ? 30 : 7
        if selectedFilter == "All Time" {
            let active = filteredSessions
            let avg = active.isEmpty ? 0 : (active.compactMap { $0.durationInHours }.reduce(0, +) / Double(active.count))
            return (formatDuration(avg * 3600), 0, true)
        }
        
        let completed = sessions.filter { $0.endTime != nil }.sorted(by: { $0.startTime > $1.startTime })
        let now = Date()
        let calendar = Calendar.current
        
        let currentPeriodStart = calendar.date(byAdding: .day, value: -periodDays, to: now)!
        let previousPeriodStart = calendar.date(byAdding: .day, value: -(periodDays * 2), to: now)!
        
        // This Period
        let currentSessions = completed.filter { $0.startTime >= currentPeriodStart }
        let prevSessions = completed.filter { $0.startTime < currentPeriodStart && $0.startTime >= previousPeriodStart }
        
        let currentAvg = currentSessions.isEmpty ? 0 : (currentSessions.compactMap { $0.durationInHours }.reduce(0, +) / Double(currentSessions.count))
        let prevAvg = prevSessions.isEmpty ? 0 : (prevSessions.compactMap { $0.durationInHours }.reduce(0, +) / Double(prevSessions.count))
        
        let diff = currentAvg - prevAvg
        var pctChange = 0.0
        if prevAvg > 0 {
            pctChange = (diff / prevAvg) * 100
        } else if currentAvg > 0 {
            pctChange = 100
        }
        
        return (formatDuration(currentAvg * 3600), pctChange, diff >= 0)
    }
    
    private func calculateGraphPoints() -> [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var points: [Double] = []
        
        let daysToCheck = (selectedFilter == "Last 30 Days") ? 30 : 7
        
        // Optimization: Create a dictionary of sessions keyed by start of day
        let sessionMap = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startTime)
        }
        
        // We want points from oldest to newest (Left to Right)
        for i in (0..<daysToCheck).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                if let daysSessions = sessionMap[date], let first = daysSessions.first {
                    // Normalize score 0-100 to 0.0-1.0
                    points.append(Double(first.sleepQualityScore ?? 0) / 100.0)
                } else {
                    points.append(0.0)
                }
            } else {
                points.append(0.0)
            }
        }
        return points
    }
    
    private func getGraphLabels() -> [String] {
        let calendar = Calendar.current
        var labels: [String] = []
        
        if selectedFilter == "Last 30 Days" {
            // Show roughly 4 weeks labels or similar? 
            // Better: Show Start, Mid, End
            let today = Date()
            labels.append(calendar.date(byAdding: .day, value: -30, to: today)!.formatted(.dateTime.day().month()))
            labels.append(calendar.date(byAdding: .day, value: -15, to: today)!.formatted(.dateTime.day().month()))
            labels.append("Today")
        } else if selectedFilter == "All Time" {
             labels.append("First")
             labels.append("Latest")
        } else {
            // Week labels (Mon, Tue, etc)
            for i in (0..<7).reversed() {
                if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                    labels.append(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                }
            }
        }
        return labels
    }
    
    private func calculateAverageDeepSleep(for relevantSessions: [SleepSession]) -> String {
        guard !relevantSessions.isEmpty else { return "0h 0m" }
        let totalDeep = relevantSessions.compactMap { $0.deepSleepDuration }.reduce(0, +) 
        let avgDeepMinutes = totalDeep / Double(relevantSessions.count)
        
        let h = Int(avgDeepMinutes) / 60
        let m = Int(avgDeepMinutes) % 60
        return "\(h)h \(m)m"
    }
    
    // MARK: - UI Helpers
    
    func scoreToStatus(_ score: Int) -> String {
        switch score {
        case 90...100: return "Excellent Sleep"
        case 75..<90: return "Good Sleep"
        case 50..<75: return "Fair Sleep"
        default: return "Poor Sleep"
        }
    }
    
    func scoreToColor(_ score: Int) -> Color {
        switch score {
        case 90...100: return Color(hex: "4CD964")
        case 75..<90: return Color(hex: "8B5CF6")
        case 50..<75: return Color(hex: "F6AD55")
        default: return Color(hex: "FF6B6B")
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    func ledgerRow(day: String, date: String, status: String, time: String, duration: String, score: String, dotColor: Color, scoreColor: Color) -> some View {
        HStack(spacing: 16) {
            VStack {
                Text(day)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.gray)
                Text(date)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            .frame(width: 50, height: 50)
            .background(Color(hex: "252529"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                    .fill(dotColor)
                    .frame(width: 8, height: 8)
                    Text(status)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
                Text(time)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .fontDesign(.monospaced)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(duration)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text(score)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(scoreColor)
            }
        }
        .padding()
        .background(Color(hex: "1C1C1E"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Dynamic Wave Graph
struct WaveGraphView: View {
    var dataPoints: [Double] // Generalized 0.0 to 1.0 values
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            // Draw gradient area
            LinearGradient(
                colors: [Color(hex: "6B35F6").opacity(0.3), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .mask(
                GraphPath(dataPoints: dataPoints, width: width, height: height, closePath: true)
            )
            
            // Draw line
            GraphPath(dataPoints: dataPoints, width: width, height: height, closePath: false)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "6B35F6"), Color(hex: "9F7AEA")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: Color(hex: "6B35F6").opacity(0.5), radius: 10, x: 0, y: 5)
            
            // Draw points
            if !dataPoints.allSatisfy({ $0 == 0 }) { // Only show dots if we have data
                ForEach(0..<dataPoints.count, id: \.self) { index in
                    let x = width * (CGFloat(index) / CGFloat(max(1, dataPoints.count - 1)))
                    // Invert Y because 0 is top
                    // Pad top/bottom by 10% so points aren't cut off
                    let normalizedY = 1.0 - dataPoints[index]
                    let y = (height * 0.1) + (normalizedY * height * 0.8)
                    
                    if dataPoints[index] > 0 {
                        Circle()
                            .fill(.white)
                            .frame(width: 6, height: 6)
                            .position(x: x, y: y)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                }
            }
        }
    }
}

struct GraphPath: Shape {
    let dataPoints: [Double]
    let width: CGFloat
    let height: CGFloat
    let closePath: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard dataPoints.count > 1 else { return path }
        
        let stepX = width / CGFloat(dataPoints.count - 1)
        
        // Helper to map 0...1 data to height with padding
        func mapY(_ value: Double) -> CGFloat {
            let normalized = 1.0 - value
            return (height * 0.1) + (normalized * height * 0.8)
        }
        
        let p1 = CGPoint(x: 0, y: mapY(dataPoints[0]))
        path.move(to: p1)
        
        for i in 1..<dataPoints.count {
            let p2 = CGPoint(x: stepX * CGFloat(i), y: mapY(dataPoints[i]))
            // Simple straight lines for robustness, or could do curves
            // Using straight lines looks cleaner for daily discrete points usually
            path.addLine(to: p2)
        }
        
        if closePath {
            path.addLine(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.closeSubpath()
        }
        
        return path
    }
}

extension View {
    func pulseEffect() -> some View {
        self.modifier(PulseModifier())
    }
}

struct PulseModifier: ViewModifier {
    @State private var isOn = false
    func body(content: Content) -> some View {
        content
            .opacity(isOn ? 0.5 : 1.0)
            .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isOn)
            .onAppear { isOn = true }
    }
}

#Preview {
    JournalView()
        .modelContainer(ModelContainer.shared)
}
