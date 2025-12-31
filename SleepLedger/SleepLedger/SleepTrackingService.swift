//
//  SleepTrackingService.swift
//  SleepLedger
//
//  Orchestrates sleep tracking, integrating motion detection with data persistence
//

import Foundation
import SwiftData
import UserNotifications
import Combine

class SleepTrackingService: ObservableObject {
    // MARK: - Properties
    
    @Published var currentSession: SleepSession?
    @Published var isTracking = false
    
    private let motionService: MotionDetectionService
    private let modelContext: ModelContext
    
    /// User's default sleep goal (can be customized per session)
    var defaultSleepGoalHours: Double = 8.0
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, motionService: MotionDetectionService = MotionDetectionService()) {
        self.modelContext = modelContext
        self.motionService = motionService
        
        // Set up motion data callback
        self.motionService.onMovementDataCollected = { [weak self] movementData in
            Task { @MainActor in
                self?.handleMovementData(movementData)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Punch in - Start a new sleep session
    func punchIn(sleepGoalHours: Double? = nil, smartAlarmEnabled: Bool = false, targetWakeTime: Date? = nil) {
        guard currentSession == nil else {
            print("⚠️ Session already active")
            return
        }
        
        let session = SleepSession(
            startTime: Date(),
            sleepGoalHours: sleepGoalHours ?? defaultSleepGoalHours,
            smartAlarmEnabled: smartAlarmEnabled,
            targetWakeTime: targetWakeTime
        )
        
        modelContext.insert(session)
        currentSession = session
        
        // Start motion tracking
        motionService.startTracking()
        isTracking = true
        
        // Save context
        try? modelContext.save()
        
        print("✅ Sleep session started at \(session.startTime)")
        
        // Schedule smart alarm if enabled
        if smartAlarmEnabled, let wakeTime = targetWakeTime {
            scheduleSmartAlarm(for: session, targetWakeTime: wakeTime)
        }
    }
    
    /// Punch out - End the current sleep session
    func punchOut() {
        guard let session = currentSession else {
            print("⚠️ No active session to end")
            return
        }
        
        // Stop motion tracking
        motionService.stopTracking()
        isTracking = false
        
        // End the session
        session.endSession()
        
        // Check minimum duration (5 minutes) - delete if too short
        let minimumDurationMinutes: Double = 5.0
        if let durationHours = session.durationInHours, durationHours < (minimumDurationMinutes / 60.0) {
            print("⚠️ Session too short (< \(Int(minimumDurationMinutes)) min), deleting from history")
            modelContext.delete(session)
            try? modelContext.save()
            currentSession = nil
            cancelSmartAlarm()
            return
        }
        
        // Save context
        try? modelContext.save()
        
        print("✅ Sleep session ended at \(session.endTime!)")
        print("📊 Duration: \(String(format: "%.1f", session.durationInHours ?? 0)) hours")
        print("💤 Quality: \(String(format: "%.0f", session.sleepQualityScore ?? 0))%")
        print("📉 Sleep Debt: \(String(format: "%.1f", session.sleepDebt ?? 0)) hours")
        
        // Cancel any pending alarms
        cancelSmartAlarm()
        
        currentSession = nil
    }
    
    /// Get cumulative sleep debt over the last N days
    func getCumulativeSleepDebt(days: Int = 7) -> Double {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        
        let descriptor = FetchDescriptor<SleepSession>(
            predicate: #Predicate { session in
                session.startTime >= startDate && session.endTime != nil
            }
        )
        
        do {
            let sessions = try modelContext.fetch(descriptor)
            let totalDebt = sessions.compactMap { $0.sleepDebt }.reduce(0, +)
            return totalDebt
        } catch {
            print("❌ Error fetching sleep debt: \(error)")
            return 0.0
        }
    }
    
    /// Get average sleep quality over the last N days
    func getAverageSleepQuality(days: Int = 7) -> Double {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        
        let descriptor = FetchDescriptor<SleepSession>(
            predicate: #Predicate { session in
                session.startTime >= startDate && session.endTime != nil
            }
        )
        
        do {
            let sessions = try modelContext.fetch(descriptor)
            let qualities = sessions.compactMap { $0.sleepQualityScore }
            guard !qualities.isEmpty else { return 0.0 }
            return qualities.reduce(0, +) / Double(qualities.count)
        } catch {
            print("❌ Error fetching sleep quality: \(error)")
            return 0.0
        }
    }
    
    /// Get average sleep duration over the last N days
    func getAverageSleepDuration(days: Int = 7) -> Double {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        
        let descriptor = FetchDescriptor<SleepSession>(
            predicate: #Predicate { session in
                session.startTime >= startDate && session.endTime != nil
            }
        )
        
        do {
            let sessions = try modelContext.fetch(descriptor)
            let durations = sessions.compactMap { $0.durationInHours }
            guard !durations.isEmpty else { return 0.0 }
            return durations.reduce(0, +) / Double(durations.count)
        } catch {
            print("❌ Error fetching avg duration: \(error)")
            return 0.0
        }
    }
    
    /// Calculate sleep consistency score (0-100%) based on variance in start times
    func calculateSleepConsistency(days: Int = 7) -> Int {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        
        let descriptor = FetchDescriptor<SleepSession>(
            predicate: #Predicate { session in
                session.startTime >= startDate && session.endTime != nil
            }
        )
        
        do {
            let sessions = try modelContext.fetch(descriptor)
            guard sessions.count >= 2 else { return 100 } // Default to 100 if not enough data
            
            // Convert start times to minutes from midnight (adjusted for late night)
            let startTimes = sessions.map { session -> Double in
                let components = calendar.dateComponents([.hour, .minute], from: session.startTime)
                let minutes = Double(components.hour! * 60 + components.minute!)
                // If time is before noon (e.g. 1 AM), treat it as next day (add 24h) roughly for variance calc logic
                return minutes < 1080 ? minutes + 1440 : minutes
            }
            
            let meanStart = startTimes.reduce(0, +) / Double(startTimes.count)
            let varianceStart = startTimes.map { pow($0 - meanStart, 2) }.reduce(0, +) / Double(startTimes.count)
            let stdDevStart = sqrt(varianceStart) // In minutes
            
            // Score Calculation:
            // 0-30 min deviation = 100%
            // Every 15 mins extra deviation reduces score by 5%
            let excessVariance = max(0, stdDevStart - 30)
            let penalty = (excessVariance / 15.0) * 5.0
            
            return Int(max(0, 100 - penalty))
            
        } catch {
            print("❌ Error calculating consistency: \(error)")
            return 100
        }
    }
    
    // MARK: - Private Methods
    
    /// Handle incoming movement data from motion service
    private func handleMovementData(_ movementData: MovementData) {
        guard let session = currentSession else { return }
        
        // Add movement data to session
        session.movementData.append(movementData)
        
        // Save context periodically (every 5 data points to avoid excessive writes)
        if session.movementData.count % 5 == 0 {
            try? modelContext.save()
        }
        
        // Check if we should trigger smart alarm
        if session.smartAlarmEnabled {
            checkSmartAlarmTrigger(for: session)
        }
    }
    
    /// Schedule smart alarm notification
    private func scheduleSmartAlarm(for session: SleepSession, targetWakeTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = "SleepLedger Smart Alarm"
        content.body = "Time to wake up! You're in light sleep."
        content.sound = .default
        content.categoryIdentifier = "SMART_ALARM"
        
        // Schedule for the target wake time (will be adjusted in real-time)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: targetWakeTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: "smart_alarm_\(session.id.uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling smart alarm: \(error)")
            } else {
                print("⏰ Smart alarm scheduled for \(targetWakeTime)")
            }
        }
    }
    
    /// Check if we should trigger the smart alarm based on current movement
    private func checkSmartAlarmTrigger(for session: SleepSession) {
        guard let targetWake = session.targetWakeTime else { return }
        
        let now = Date()
        let windowStart = targetWake.addingTimeInterval(-30 * 60) // 30 minutes before
        
        // Only check if we're within the window
        guard now >= windowStart && now <= targetWake else { return }
        
        // Check if current movement indicates light sleep
        if motionService.sleepStage == .lightSleep || motionService.sleepStage == .awake {
            // Trigger alarm now
            triggerSmartAlarm(for: session)
        }
    }
    
    /// Trigger the smart alarm immediately
    private func triggerSmartAlarm(for session: SleepSession) {
        session.actualWakeTime = Date()
        
        let content = UNMutableNotificationContent()
        content.title = "SleepLedger Smart Alarm"
        content.body = "Perfect timing! You're in light sleep. Time to wake up! 🌅"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "smart_alarm_trigger_\(session.id.uuidString)", content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request)
        print("⏰ Smart alarm triggered at \(session.actualWakeTime!)")
    }
    
    /// Cancel any pending smart alarms
    private func cancelSmartAlarm() {
        guard let session = currentSession else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["smart_alarm_\(session.id.uuidString)"])
    }
}
