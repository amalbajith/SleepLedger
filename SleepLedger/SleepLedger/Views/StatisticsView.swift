//
//  StatisticsView.swift
//  SleepLedger
//
//  Sleep statistics and trends visualization
//

import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SleepSession.startTime, order: .reverse) private var allSessions: [SleepSession]
    
    @State private var selectedPeriod: TimePeriod = .week
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .all: return 365
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Period Selector
                    periodSelector
                    
                    // Overview Stats
                    overviewStats
                    
                    // Sleep Duration Chart
                    sleepDurationChart
                    
                    // Quality Trend Chart
                    qualityTrendChart
                    
                    // Sleep Debt Chart
                    sleepDebtChart
                    
                    // Insights
                    insightsSection
                }
                .padding()
            }
            .background(Color.sleepBackground)
            .navigationTitle("Statistics")
        }
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
    
    // MARK: - Overview Stats
    
    private var overviewStats: some View {
        VStack(spacing: 16) {
            Text("Overview")
                .font(.headline)
                .foregroundColor(.sleepTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                OverviewCard(
                    icon: "moon.fill",
                    label: "Avg Sleep",
                    value: String(format: "%.1fh", averageSleepDuration),
                    color: .sleepPrimary
                )
                
                OverviewCard(
                    icon: "star.fill",
                    label: "Avg Quality",
                    value: String(format: "%.0f%%", averageQuality),
                    color: .sleepSecondary
                )
            }
            
            HStack(spacing: 12) {
                OverviewCard(
                    icon: "chart.line.downtrend.xyaxis",
                    label: "Total Debt",
                    value: String(format: "%+.1fh", totalSleepDebt),
                    color: totalSleepDebt >= 0 ? .sleepSuccess : .sleepError
                )
                
                OverviewCard(
                    icon: "bed.double.fill",
                    label: "Sessions",
                    value: "\(filteredSessions.count)",
                    color: .sleepPrimary
                )
            }
        }
    }
    
    // MARK: - Sleep Duration Chart
    
    private var sleepDurationChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Duration")
                .font(.headline)
                .foregroundColor(.sleepTextPrimary)
            
            if filteredSessions.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart {
                    ForEach(filteredSessions.reversed()) { session in
                        if let duration = session.durationInHours {
                            BarMark(
                                x: .value("Date", session.startTime, unit: .day),
                                y: .value("Hours", duration)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.sleepPrimary, .sleepSecondary],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .cornerRadius(4)
                            
                            // Goal line
                            RuleMark(y: .value("Goal", session.sleepGoalHours))
                                .foregroundStyle(Color.sleepSuccess.opacity(0.5))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        }
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.sleepCardBorder)
                        AxisValueLabel()
                            .foregroundStyle(Color.sleepTextSecondary)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(Color.sleepTextSecondary)
                    }
                }
            }
        }
        .padding()
        .sleepCard()
    }
    
    // MARK: - Quality Trend Chart
    
    private var qualityTrendChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Quality Trend")
                .font(.headline)
                .foregroundColor(.sleepTextPrimary)
            
            if filteredSessions.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart {
                    ForEach(filteredSessions.reversed()) { session in
                        if let quality = session.sleepQualityScore {
                            LineMark(
                                x: .value("Date", session.startTime, unit: .day),
                                y: .value("Quality", quality)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.sleepPrimary, .sleepSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                            
                            AreaMark(
                                x: .value("Date", session.startTime, unit: .day),
                                y: .value("Quality", quality)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.sleepPrimary.opacity(0.3), .sleepSecondary.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.sleepCardBorder)
                        AxisValueLabel()
                            .foregroundStyle(Color.sleepTextSecondary)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(Color.sleepTextSecondary)
                    }
                }
            }
        }
        .padding()
        .sleepCard()
    }
    
    // MARK: - Sleep Debt Chart
    
    private var sleepDebtChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Debt Accumulation")
                .font(.headline)
                .foregroundColor(.sleepTextPrimary)
            
            if filteredSessions.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart {
                    ForEach(Array(filteredSessions.reversed().enumerated()), id: \.offset) { index, session in
                        if let debt = session.sleepDebt {
                            let cumulativeDebt = cumulativeDebtUpTo(index: index)
                            
                            LineMark(
                                x: .value("Date", session.startTime, unit: .day),
                                y: .value("Cumulative Debt", cumulativeDebt)
                            )
                            .foregroundStyle(cumulativeDebt >= 0 ? Color.sleepSuccess : Color.sleepError)
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                            
                            AreaMark(
                                x: .value("Date", session.startTime, unit: .day),
                                y: .value("Cumulative Debt", cumulativeDebt)
                            )
                            .foregroundStyle(
                                (cumulativeDebt >= 0 ? Color.sleepSuccess : Color.sleepError).opacity(0.2)
                            )
                        }
                    }
                    
                    // Zero line
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(Color.sleepTextTertiary)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.sleepCardBorder)
                        AxisValueLabel()
                            .foregroundStyle(Color.sleepTextSecondary)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(Color.sleepTextSecondary)
                    }
                }
            }
        }
        .padding()
        .sleepCard()
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.headline)
                .foregroundColor(.sleepTextPrimary)
            
            VStack(spacing: 12) {
                if let bestSession = bestSession {
                    InsightCard(
                        icon: "star.fill",
                        title: "Best Sleep",
                        description: "Your best sleep was on \(bestSession.startTime.formatted(date: .abbreviated, time: .omitted)) with \(String(format: "%.0f%%", bestSession.sleepQualityScore ?? 0)) quality",
                        color: .sleepSuccess
                    )
                }
                
                if averageSleepDuration < 7.0 {
                    InsightCard(
                        icon: "exclamationmark.triangle.fill",
                        title: "Sleep Duration",
                        description: "Your average sleep is below 7 hours. Try to get more rest!",
                        color: .sleepWarning
                    )
                }
                
                if totalSleepDebt < -5.0 {
                    InsightCard(
                        icon: "chart.line.downtrend.xyaxis",
                        title: "High Sleep Debt",
                        description: "You have accumulated \(String(format: "%.1f", abs(totalSleepDebt))) hours of sleep debt. Consider catching up!",
                        color: .sleepError
                    )
                }
                
                if filteredSessions.count >= 7 {
                    let consistency = calculateConsistency()
                    if consistency > 0.8 {
                        InsightCard(
                            icon: "checkmark.circle.fill",
                            title: "Great Consistency",
                            description: "You're maintaining a consistent sleep schedule. Keep it up!",
                            color: .sleepSuccess
                        )
                    }
                }
            }
        }
        .padding()
        .sleepCard()
    }
    
    private var emptyChartPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(.sleepTextTertiary)
            
            Text("Not enough data")
                .font(.subheadline)
                .foregroundColor(.sleepTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    // MARK: - Computed Properties
    
    private var filteredSessions: [SleepSession] {
        let completedSessions = allSessions.filter { $0.endTime != nil }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedPeriod.days, to: Date()) ?? Date()
        return completedSessions.filter { $0.startTime >= cutoffDate }
    }
    
    private var averageSleepDuration: Double {
        let durations = filteredSessions.compactMap { $0.durationInHours }
        guard !durations.isEmpty else { return 0 }
        return durations.reduce(0, +) / Double(durations.count)
    }
    
    private var averageQuality: Double {
        let qualities = filteredSessions.compactMap { $0.sleepQualityScore }
        guard !qualities.isEmpty else { return 0 }
        return qualities.reduce(0, +) / Double(qualities.count)
    }
    
    private var totalSleepDebt: Double {
        filteredSessions.compactMap { $0.sleepDebt }.reduce(0, +)
    }
    
    private var bestSession: SleepSession? {
        filteredSessions.max { ($0.sleepQualityScore ?? 0) < ($1.sleepQualityScore ?? 0) }
    }
    
    private func cumulativeDebtUpTo(index: Int) -> Double {
        let reversedSessions = filteredSessions.reversed()
        return Array(reversedSessions.prefix(index + 1))
            .compactMap { $0.sleepDebt }
            .reduce(0, +)
    }
    
    private func calculateConsistency() -> Double {
        guard filteredSessions.count >= 2 else { return 0 }
        
        let durations = filteredSessions.compactMap { $0.durationInHours }
        let mean = durations.reduce(0, +) / Double(durations.count)
        let variance = durations.reduce(0) { sum, value in
            sum + pow(value - mean, 2)
        } / Double(durations.count)
        let stdDev = sqrt(variance)
        
        // Lower standard deviation = higher consistency
        return max(0, 1.0 - (stdDev / mean))
    }
}

// MARK: - Supporting Views

struct OverviewCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.sleepTextPrimary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.sleepTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .sleepCard()
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.sleepTextPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.sleepTextSecondary)
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    StatisticsView()
        .preferredColorScheme(.dark)
}
