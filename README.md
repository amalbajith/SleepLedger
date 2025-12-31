# SleepLedger

A privacy-focused sleep tracker for iOS that uses a manual "Punch In/Out" system with accelerometer-based movement tracking.

## ✨ Features

- 🛏️ **Manual Sleep Tracking** - Simple punch in/out system (no Apple Watch required)
- 📊 **Movement Detection** - CoreMotion-based accelerometer tracking with 50 Hz sampling
- 💤 **Sleep Stage Classification** - Real-time detection of deep sleep, light sleep, and awake states
- 📉 **Sleep Debt Tracking** - Monitor your sleep deficit/surplus against your customizable goal
- ⏰ **Smart Alarm** - Wake up during light sleep within a 20-minute window before your target time
- 📈 **Statistics & Charts** - Visualize sleep duration, quality trends, and debt accumulation
- 📱 **Dark OLED UI** - Battery-optimized pure black interface with gradient accents
- 🔐 **100% Private** - All data stored locally with SwiftData (no cloud, no subscription)

## Requirements

- iOS 17.0+
- Physical iPhone (motion tracking requires real device)
- Motion & Fitness permission

## Privacy

- ✅ All data stored locally on device
- ✅ No cloud sync or external servers
- ✅ No account or login required
- ✅ No analytics or tracking
- ✅ No subscriptions

## Technical Stack

- **SwiftUI** - Modern declarative UI
- **SwiftData** - Local data persistence
- **CoreMotion** - Accelerometer-based movement detection
- **UserNotifications** - Smart alarm system

## Architecture

- `SleepSession.swift` - SwiftData model for sleep sessions
- `MotionDetectionService.swift` - CoreMotion integration and sleep stage classification
- `SleepTrackingService.swift` - Main orchestration layer

## License

MIT License - See LICENSE file for details

## Author

Built with ❤️ for better sleep tracking
