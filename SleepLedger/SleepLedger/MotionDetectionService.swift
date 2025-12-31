//
//  MotionDetectionService.swift
//  SleepLedger
//
//  CoreMotion-based movement detection for sleep tracking
//

import Foundation
import CoreMotion
import Combine

class MotionDetectionService: ObservableObject {
    // MARK: - Properties
    
    private let motionManager = CMMotionManager()
    private let operationQueue = OperationQueue()
    
    @Published var isTracking = false
    @Published var currentMovementIntensity: Double = 0.0
    @Published var sleepStage: SleepStage = .awake
    
    /// Callback for when new movement data is available
    var onMovementDataCollected: ((MovementData) -> Void)?
    
    // MARK: - Configuration
    
    /// How often to sample accelerometer data (in Hz)
    private let samplingFrequency: Double = 50.0 // 50 Hz
    
    /// Window size for calculating movement intensity (in seconds)
    private let analysisWindowSize: TimeInterval = 60.0 // 1 minute
    
    /// Buffer to store recent accelerometer readings
    private var accelerometerBuffer: [AccelerometerReading] = []
    
    /// Timer for periodic analysis
    private var analysisTimer: Timer?
    
    // MARK: - Sleep Stage Classification
    
    enum SleepStage: String {
        case awake = "Awake"
        case lightSleep = "Light Sleep"
        case deepSleep = "Deep Sleep"
        
        var description: String {
            rawValue
        }
        
        var emoji: String {
            switch self {
            case .awake: return "👁️"
            case .lightSleep: return "😴"
            case .deepSleep: return "💤"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .background
    }
    
    // MARK: - Public Methods
    
    /// Start tracking movement
    func startTracking() {
        guard !isTracking else { return }
        
        // Check if accelerometer is available
        guard motionManager.isAccelerometerAvailable else {
            print("❌ Accelerometer not available on this device")
            return
        }
        
        // Configure motion manager
        motionManager.accelerometerUpdateInterval = 1.0 / samplingFrequency
        
        // Start accelerometer updates
        motionManager.startAccelerometerUpdates(to: operationQueue) { [weak self] data, error in
            guard let self = self else { return }
            
            if let data = data {
                Task { @MainActor in
                    self.processAccelerometerData(data)
                }
            } else if let error = error {
                print("❌ Accelerometer error: \(error.localizedDescription)")
            }
        }
        
        // Start periodic analysis timer (every minute)
        analysisTimer = Timer.scheduledTimer(withTimeInterval: analysisWindowSize, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.analyzeMovementWindow()
            }
        }
        
        isTracking = true
        print("✅ Motion tracking started")
    }
    
    /// Stop tracking movement
    func stopTracking() {
        guard isTracking else { return }
        
        motionManager.stopAccelerometerUpdates()
        analysisTimer?.invalidate()
        analysisTimer = nil
        accelerometerBuffer.removeAll()
        
        isTracking = false
        print("🛑 Motion tracking stopped")
    }
    
    // MARK: - Private Methods
    
    /// Process incoming accelerometer data
    private func processAccelerometerData(_ data: CMAccelerometerData) {
        let reading = AccelerometerReading(
            timestamp: Date(),
            x: data.acceleration.x,
            y: data.acceleration.y,
            z: data.acceleration.z
        )
        
        accelerometerBuffer.append(reading)
        
        // Keep buffer size manageable (store last 2 minutes of data)
        let maxBufferSize = Int(samplingFrequency * analysisWindowSize * 2)
        if accelerometerBuffer.count > maxBufferSize {
            accelerometerBuffer.removeFirst(accelerometerBuffer.count - maxBufferSize)
        }
    }
    
    /// Analyze the movement window and classify sleep stage
    private func analyzeMovementWindow() {
        guard !accelerometerBuffer.isEmpty else { return }
        
        // Calculate movement intensity from recent data
        let intensity = calculateMovementIntensity()
        currentMovementIntensity = intensity
        
        // Classify sleep stage based on intensity
        let stage = classifySleepStage(intensity: intensity)
        sleepStage = stage
        
        // Create movement data point
        let movementData = MovementData(
            timestamp: Date(),
            movementIntensity: intensity,
            durationMinutes: analysisWindowSize / 60.0
        )
        
        // Notify callback
        onMovementDataCollected?(movementData)
        
        print("📊 Movement: \(String(format: "%.2f", intensity)) | Stage: \(stage.emoji) \(stage.rawValue)")
    }
    
    /// Calculate movement intensity from accelerometer buffer
    /// Returns a value between 0.0 (no movement) and 1.0 (high movement)
    private func calculateMovementIntensity() -> Double {
        guard !accelerometerBuffer.isEmpty else { return 0.0 }
        
        // Calculate variance in acceleration magnitude
        var magnitudes: [Double] = []
        
        for reading in accelerometerBuffer {
            // Calculate magnitude of acceleration vector
            let magnitude = sqrt(
                reading.x * reading.x +
                reading.y * reading.y +
                reading.z * reading.z
            )
            magnitudes.append(magnitude)
        }
        
        // Calculate mean
        let mean = magnitudes.reduce(0, +) / Double(magnitudes.count)
        
        // Calculate variance
        let variance = magnitudes.reduce(0) { sum, value in
            sum + pow(value - mean, 2)
        } / Double(magnitudes.count)
        
        // Calculate standard deviation
        let standardDeviation = sqrt(variance)
        
        // Normalize to 0-1 range
        // Typical sleep movement: 0.01-0.05 std dev
        // Awake movement: 0.1+ std dev
        let normalizedIntensity = min(1.0, standardDeviation / 0.15)
        
        return normalizedIntensity
    }
    
    /// Classify sleep stage based on movement intensity
    private func classifySleepStage(intensity: Double) -> SleepStage {
        switch intensity {
        case 0.0..<0.3:
            return .deepSleep
        case 0.3..<0.7:
            return .lightSleep
        default:
            return .awake
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        stopTracking()
    }
}

// MARK: - Supporting Types

private struct AccelerometerReading {
    let timestamp: Date
    let x: Double
    let y: Double
    let z: Double
}
