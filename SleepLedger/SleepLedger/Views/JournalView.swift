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
    @AppStorage("sleepGoalHours") private var sleepGoalHours: Double = 8.0
    
    @State private var selectedPeriod: TimePeriod = .week
    @State private var selectedSession: SleepSession?
    @State private var showingClearAlert = false
    
    enum TimePeriod: String, CaseIterable {
        case week = "This Week"
        case month = "Last 30 Days"
        case all = "All Time"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .all: return 3650
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.sleepBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Trends Section
                        trendsSection
                        
                        // Summary Section (Rings)
                        summarySection
                        
                        // Ledger Section (List)
                        ledgerSection
                        
                        Spacer(minLength: 120) // Extra padding for tab bar
                    }
                    .padding(24)
                }
                .scrollIndicators(.hidden)
            }
        }
        .fullScreenCover(item: $selectedSession) { session in
            SessionDetailView(session: session)
        }
        .alert("Clear All History?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAllHistory()
            }
        } message: {
            Text("This will permanently delete all your sleep records. This cannot be undone.")
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Text("History")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                
                Button {
                    showingClearAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(.sleepPrimary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Period Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPeriod = period
                            }
                        } label: {
                            Text(period.rawValue)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(selectedPeriod == period ? .white : .gray)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(selectedPeriod == period ? Color.sleepPrimary : Color(white: 0.1))
                                .cornerRadius(20)
                                .shadow(color: selectedPeriod == period ? Color.sleepPrimary.opacity(0.3) : .clear, radius: 10)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 16)
            
            Divider()
                .background(Color.white.opacity(0.05))
        }
        .background(Color.sleepBackground.opacity(0.8).blur(radius: 10))
    }
    
    // MARK: - Trends
    
    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                Text("Trends")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("Avg Sleep")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                    .tracking(1)
            }
            
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Average Duration")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        Text(formatDuration(averageSleepDuration))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Trend Indicator
                        HStack(spacing: 2) {
                            Image(systemName: "trending.up")
                                .font(.system(size: 12))
                            Text("15%")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "#0bda6f"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#0bda6f").opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                
                HistoryTrendsChart(sessions: filteredSessions)
            }
            .padding(20)
            .background(Color.sleepCardBackground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Summary
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                SummaryRing(
                    progress: min(averageSleepDuration / sleepGoalHours, 1.0),
                    label: "Duration",
                    sublabel: "\(Int(min(averageSleepDuration / sleepGoalHours, 1.0) * 100))% Goal",
                    icon: "clock.fill",
                    color: .sleepPrimary
                )
                
                SummaryRing(
                    progress: averageQuality / 100.0,
                    label: "Quality",
                    sublabel: "\(Int(averageQuality))% Avg",
                    icon: "star.fill",
                    color: Color(hex: "#7c3aed")
                )
                
                SummaryRing(
                    progress: 0.25, // Concept filler
                    label: "Deep",
                    sublabel: "1h 45m",
                    icon: "waveform.path.ecg",
                    color: Color(hex: "#06b6d4")
                )
            }
        }
    }
    
    // MARK: - Ledger
    
    private var ledgerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                Text("Ledger")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button("Export CSV") {
                    // Export functionality
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.sleepPrimary)
                .textCase(.uppercase)
            }
            
            VStack(spacing: 12) {
                if filteredSessions.isEmpty {
                    Text("No records found for this period.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.vertical, 40)
                } else {
                    ForEach(filteredSessions) { session in
                        SessionLedgerRow(session: session)
                            .onTapGesture {
                                selectedSession = session
                            }
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers & Data
    
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
    
    private func formatDuration(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }
    
    private func clearAllHistory() {
        for session in sessions {
            modelContext.delete(session)
        }
        try? modelContext.save()
    }
}

#Preview {
    JournalView()
        .preferredColorScheme(.dark)
}

