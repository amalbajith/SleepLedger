//
//  JournalView.swift
//  SleepLedger
//
//  Combined history and statistics view
//

import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SleepSession.startTime, order: .reverse) private var sessions: [SleepSession]
    
    @State private var selectedPeriod: TimePeriod = .week
    @State private var selectedSession: SleepSession?
    
    enum TimePeriod: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case threeMonths = "90 Days"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Period Selector
                    periodSelector
                    
                    // Stats Overview
                    statsOverview
                    
                    // Sleep Trend Chart
                    sleepTrendSection
                    
                    // All Sessions List
                    sessionsListSection
                }
                .padding()
            }
            .background(Color.sleepBackground)
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
        }
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        HStack(spacing: 12) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button(action: { selectedPeriod = period }) {
                    Text(period.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedPeriod == period ? .semibold : .regular)
                        .foregroundColor(selectedPeriod == period ? .white : .sleepTextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedPeriod == period ? Color.sleepPrimary : Color.sleepCardBackground)
                        .cornerRadius(20)
                }
            }
        }
    }
    
    // MARK: - Stats Overview
    
    private var statsOverview: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(
                    icon: "moon.fill",
                    label: "Avg Sleep",
                    value: String(format: "%.1fh", averageSleepDuration),
                    color: .sleepPrimary
                )
                
                StatCard(
                    icon: "star.fill",
                    label: "Avg Quality",
                    value: String(format: "%.0f%%", averageQuality),
                    color: .sleepSecondary
                )
            }
            
            HStack(spacing: 16) {
                StatCard(
                    icon: "chart.line.downtrend.xyaxis",
                    label: "Sleep Debt",
                    value: String(format: "%+.1fh", totalSleepDebt),
                    color: totalSleepDebt >= 0 ? .sleepSuccess : .sleepError
                )
                
                StatCard(
                    icon: "calendar",
                    label: "Sessions",
                    value: "\(filteredSessions.count)",
                    color: .sleepPrimary
                )
            }
        }
    }
    
    // MARK: - Sleep Trend Section
    
    private var sleepTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Duration Trend")
                .font(.headline)
                .foregroundColor(.sleepTextPrimary)
            
            SimpleTrendChart(sessions: filteredSessions)
                .frame(height: 120)
        }
        .padding()
        .sleepCard()
    }
    
    // MARK: - Sessions List Section
    
    private var sessionsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Sessions")
                .font(.headline)
                .foregroundColor(.sleepTextPrimary)
            
            if filteredSessions.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredSessions) { session in
                        SessionCard(session: session)
                            .onTapGesture {
                                selectedSession = session
                            }
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 60))
                .foregroundColor(.sleepTextTertiary)
            
            Text("No sleep sessions yet")
                .font(.subheadline)
                .foregroundColor(.sleepTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Computed Properties
    
    private var filteredSessions: [SleepSession] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: Date())!
        return sessions.filter { session in
            session.endTime != nil && session.startTime >= startDate
        }
    }
    
    private var averageSleepDuration: Double {
        guard !filteredSessions.isEmpty else { return 0 }
        let total = filteredSessions.compactMap { $0.durationInHours }.reduce(0, +)
        return total / Double(filteredSessions.count)
    }
    
    private var averageQuality: Double {
        guard !filteredSessions.isEmpty else { return 0 }
        let total = filteredSessions.compactMap { $0.sleepQualityScore }.reduce(0, +)
        return total / Double(filteredSessions.count)
    }
    
    private var totalSleepDebt: Double {
        filteredSessions.compactMap { $0.sleepDebt }.reduce(0, +)
    }
}

// MARK: - Stat Card

struct StatCard: View {
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

// MARK: - Simple Trend Chart

struct SimpleTrendChart: View {
    let sessions: [SleepSession]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background grid
                VStack(spacing: 0) {
                    ForEach(0..<4) { _ in
                        Divider()
                            .background(Color.sleepCardBorder)
                        Spacer()
                    }
                }
                
                // Bars
                if !sessions.isEmpty {
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(sessions.reversed()) { session in
                            if let hours = session.durationInHours {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(barColor(hours: hours))
                                    .frame(height: geometry.size.height * min(hours / 12.0, 1.0))
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func barColor(hours: Double) -> Color {
        switch hours {
        case 7...9: return .sleepSuccess
        case 5..<7, 9..<11: return .sleepPrimary
        default: return .sleepWarning
        }
    }
}

#Preview {
    JournalView()
        .preferredColorScheme(.dark)
}
