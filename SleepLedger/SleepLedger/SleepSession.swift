//
//  SleepSession.swift
//  SleepLedger
//
//  Privacy-focused sleep tracking data model
//

import Foundation
import SwiftData

@Model
final class SleepSession {
    // MARK: - Core Properties
    
    /// Unique identifier for the session
    var id: UUID
    
    /// When the user punched in (started tracking)
    var startTime: Date
    
    /// When the user punched out (ended tracking), nil if session is active
    var endTime: Date?
    
    /// Whether this session is currently active
    var isActive: Bool
    
    // MARK: - Movement Data
    
    /// Array of movement data points collected during the session
    /// Each MovementData contains timestamp and movement intensity
    @Relationship(deleteRule: .cascade)
    var movementData: [MovementData]
    
    /// Calculated sleep quality score (0-100)
    var sleepQualityScore: Double?
    
    /// Total time spent in light sleep (minutes)
    var lightSleepDuration: Double?
    
    /// Total time spent in deep sleep (minutes)
    var deepSleepDuration: Double?
    
    // MARK: - Smart Alarm
    
    /// User's desired wake time
    var targetWakeTime: Date?
    
    /// Whether smart alarm is enabled for this session
    var smartAlarmEnabled: Bool
    
    /// Actual time the alarm was triggered (within the 20-min window)
    var actualWakeTime: Date?
    
    // MARK: - Sleep Debt Tracking
    
    /// User's sleep goal in hours (e.g., 8.0)
    var sleepGoalHours: Double
    
    /// Calculated sleep debt for this session (negative = deficit, positive = surplus)
    var sleepDebt: Double?
    
    // MARK: - Notes & Metadata
    
    /// Optional user notes about the session
    var notes: String?
    
    /// Tags for categorizing sleep sessions (e.g., "weekend", "stressed", "caffeine")
    var tags: [String]
    
    // MARK: - Initialization
    
    init(
        startTime: Date = Date(),
        sleepGoalHours: Double = 8.0,
        smartAlarmEnabled: Bool = false,
        targetWakeTime: Date? = nil
    ) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = nil
        self.isActive = true
        self.movementData = []
        self.sleepQualityScore = nil
        self.lightSleepDuration = nil
        self.deepSleepDuration = nil
        self.targetWakeTime = targetWakeTime
        self.smartAlarmEnabled = smartAlarmEnabled
        self.actualWakeTime = nil
        self.sleepGoalHours = sleepGoalHours
        self.sleepDebt = nil
        self.notes = nil
        self.tags = []
    }
    
    // MARK: - Computed Properties
    
    /// Total duration of the sleep session in hours
    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }
    
    /// Duration in hours (convenience)
    var durationInHours: Double? {
        guard let duration = duration else { return nil }
        return duration / 3600.0
    }
    
    /// Whether the session met the sleep goal
    var metSleepGoal: Bool {
        guard let hours = durationInHours else { return false }
        return hours >= sleepGoalHours
    }
    
    // MARK: - Methods
    
    /// End the sleep session and calculate metrics
    func endSession() {
        endTime = Date()
        isActive = false
        calculateSleepMetrics()
        calculateSleepDebt()
    }
    
    /// Calculate sleep quality and sleep stage durations
    /// Calculate sleep quality and sleep stage durations
    func calculateSleepMetrics() {
        // Basic Mode (No Motion Data)
        if movementData.isEmpty {
            // If we have duration but no data, calculate score based purely on duration
            if let hours = durationInHours {
                // Duration Score (100% weight in Basic Mode)
                let durationScore = calculateDurationPenalty(hours: hours) * 100.0
                self.sleepQualityScore = min(100, durationScore)
            } else {
                self.sleepQualityScore = 0
            }
            
            // No stages tracked
            self.lightSleepDuration = 0
            self.deepSleepDuration = 0
            return
        }
        
        // Advanced Mode (Motion Data Exists)
        var lightSleepMinutes: Double = 0
        var deepSleepMinutes: Double = 0
        var totalMovement: Double = 0
        var totalTrackedMinutes: Double = 0
        
        // Analyze movement data to determine sleep stages
        for data in movementData {
            totalMovement += data.movementIntensity
            totalTrackedMinutes += data.durationMinutes
            
            // Deep sleep: very low movement (< 0.3)
            // Light sleep: moderate movement (0.3 - 0.7)
            // Awake/restless: high movement (> 0.7)
            if data.movementIntensity < 0.3 {
                deepSleepMinutes += data.durationMinutes
            } else if data.movementIntensity < 0.7 {
                lightSleepMinutes += data.durationMinutes
            }
        }
        
        self.lightSleepDuration = lightSleepMinutes
        self.deepSleepDuration = deepSleepMinutes
        
        // Calculate quality score (0-100)
        let totalSleepMinutes = lightSleepMinutes + deepSleepMinutes
        
        if totalTrackedMinutes > 0 {
            // 1. Efficiency Score (30%)
            // Ratio of time asleep vs total time in bed
            let efficiency = totalSleepMinutes / totalTrackedMinutes
            let efficiencyScore = efficiency * 30.0
            
            // 2. Deep Sleep Score (30%)
            // Target: 25% of sleep time should be deep sleep
            // If totalSleepMinutes is 0, this is 0
            var deepSleepScore: Double = 0
            if totalSleepMinutes > 0 {
                let deepSleepRatio = deepSleepMinutes / totalSleepMinutes
                // Normalize: 25% ratio gives full score (1.0). Cap at 1.0.
                let normalizedRatio = min(1.0, deepSleepRatio / 0.25)
                deepSleepScore = normalizedRatio * 30.0
            }
            
            // 3. Duration Score (30%)
            // Based on goal (usually 8 hours)
            var durationScore: Double = 0
            if let hours = durationInHours {
                 durationScore = calculateDurationPenalty(hours: hours) * 30.0
            }
            
            // 4. Restfulness Score (10%)
            // Based on average movement intensity
            let averageMovement = totalMovement / Double(movementData.count)
            let movementScore = max(0, (1.0 - averageMovement) * 10.0)
            
            // Total Score
            let totalScore = efficiencyScore + deepSleepScore + durationScore + movementScore
            self.sleepQualityScore = min(100, totalScore)
        }
    }
    
    /// Calculate duration penalty factor (0.0 - 1.0)
    /// Returns lower values for very short or very long sleep
    private func calculateDurationPenalty(hours: Double) -> Double {
        switch hours {
        case 0..<1:
            // < 1 hour: Very poor (0-20%)
            return hours * 0.2
        case 1..<3:
            // 1-3 hours: Poor (20-50%)
            return 0.2 + ((hours - 1) / 2) * 0.3
        case 3..<5:
            // 3-5 hours: Fair (50-70%)
            return 0.5 + ((hours - 3) / 2) * 0.2
        case 5..<7:
            // 5-7 hours: Good (70-90%)
            return 0.7 + ((hours - 5) / 2) * 0.2
        case 7..<9:
            // 7-9 hours: Excellent (90-100%)
            return 0.9 + ((hours - 7) / 2) * 0.1
        case 9..<11:
            // 9-11 hours: Good but long (90-80%)
            return 0.9 - ((hours - 9) / 2) * 0.1
        default:
            // > 11 hours: Too long (80-60%)
            return max(0.6, 0.8 - ((hours - 11) / 2) * 0.1)
        }
    }
    
    /// Calculate sleep debt based on goal
    /// Only calculates debt for sessions longer than 1 hour to prevent abuse
    func calculateSleepDebt() {
        guard let hours = durationInHours else { return }
        
        // Ignore sessions shorter than 1 hour (prevents rapid punch in/out creating fake deficit)
        if hours < 1.0 {
            self.sleepDebt = 0.0
            return
        }
        
        self.sleepDebt = hours - sleepGoalHours
    }
    
    /// Find the optimal wake time within the smart alarm window
    /// Returns the timestamp of light sleep closest to target wake time
    func findOptimalWakeTime() -> Date? {
        guard smartAlarmEnabled,
              let targetWake = targetWakeTime,
              !movementData.isEmpty else { return nil }
        
        // 30-minute window before target wake time
        let windowStart = targetWake.addingTimeInterval(-30 * 60)
        
        // Find movement data points in the window
        let windowData = movementData.filter { data in
            data.timestamp >= windowStart && data.timestamp <= targetWake
        }
        
        // Find the point with highest movement (lightest sleep)
        let optimalPoint = windowData.max { $0.movementIntensity < $1.movementIntensity }
        
        return optimalPoint?.timestamp ?? targetWake
    }
}

// MARK: - MovementData Model

@Model
final class MovementData {
    /// Unique identifier
    var id: UUID
    
    /// When this movement was recorded
    var timestamp: Date
    
    /// Movement intensity (0.0 = no movement, 1.0 = high movement)
    var movementIntensity: Double
    
    /// Duration this measurement represents (in minutes)
    var durationMinutes: Double
    
    init(
        timestamp: Date = Date(),
        movementIntensity: Double,
        durationMinutes: Double = 1.0
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.movementIntensity = movementIntensity
        self.durationMinutes = durationMinutes
    }
}
