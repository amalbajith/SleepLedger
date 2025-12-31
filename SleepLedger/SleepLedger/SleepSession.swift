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
    private func calculateSleepMetrics() {
        guard !movementData.isEmpty else { return }
        
        var lightSleepMinutes: Double = 0
        var deepSleepMinutes: Double = 0
        var totalMovement: Double = 0
        
        // Analyze movement data to determine sleep stages
        for data in movementData {
            totalMovement += data.movementIntensity
            
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
        // Higher deep sleep % = better quality
        let totalSleepMinutes = lightSleepMinutes + deepSleepMinutes
        if totalSleepMinutes > 0 {
            let deepSleepPercentage = deepSleepMinutes / totalSleepMinutes
            let averageMovement = totalMovement / Double(movementData.count)
            
            // Quality = 70% based on deep sleep ratio, 30% based on low movement
            let deepSleepScore = deepSleepPercentage * 70
            let movementScore = max(0, (1.0 - averageMovement) * 30)
            
            self.sleepQualityScore = min(100, deepSleepScore + movementScore)
        }
    }
    
    /// Calculate sleep debt based on goal
    /// Only calculates debt for sessions longer than 1 hour to prevent abuse
    private func calculateSleepDebt() {
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
    
    /// Raw accelerometer data (x, y, z)
    var accelerometerX: Double
    var accelerometerY: Double
    var accelerometerZ: Double
    
    /// Calculated magnitude of movement
    var magnitude: Double
    
    init(
        timestamp: Date = Date(),
        movementIntensity: Double,
        durationMinutes: Double = 1.0,
        accelerometerX: Double = 0,
        accelerometerY: Double = 0,
        accelerometerZ: Double = 0
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.movementIntensity = movementIntensity
        self.durationMinutes = durationMinutes
        self.accelerometerX = accelerometerX
        self.accelerometerY = accelerometerY
        self.accelerometerZ = accelerometerZ
        self.magnitude = sqrt(accelerometerX * accelerometerX +
                            accelerometerY * accelerometerY +
                            accelerometerZ * accelerometerZ)
    }
}
