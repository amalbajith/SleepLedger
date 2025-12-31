# SleepLedger 🌙

**SleepLedger** is a premium, privacy-focused sleep tracking application designed to help you understand and improve your sleep habits without compromising your data. Built natively for iOS, it combines advanced motion detection with a beautiful, dark-themed "Midnight" interface.

## 🚀 Key Features

### 🔒 Privacy-First Design
- **Offline First**: All sleep data is stored locally on your device using SwiftData.
- **No Cloud Tracking**: We do not upload your data to any servers.
- **Data Safety**: Raw accelerometer data is analyzed in real-time and immediately discarded—only privacy-safe sleep stage metrics are saved.

### 😴 Advanced Sleep Tracking
- **Smart Motion Detection**: Uses the device's accelerometer to detect movement and classify sleep stages (Deep Sleep, Light Sleep, Awake).
- **Sleep Debt Visualizer**: A dynamic ring gauge instanty shows your sleep balance (surplus or deficit) based on your personal goals.
- **Consistency Score**: Tracks how consistent your sleep schedule is, rewarding regular sleep patterns.

### ⏰ Smart Alarm (Upcoming)
- **Intelligent Wake-Up**: Wakes you up during your lightest sleep phase within a set window, ensuring you start the day feeling refreshed.

### 📊 Insightful Journal
- **Interactive Graphs**: View your sleep quality trends over the last 7 or 30 days.
- **Detailed Ledger**: A complete history of every sleep session, including duration, quality score, and bedtimes.
- **Visual Trends**: At-a-glance arrows indicate if your sleep duration and quality are improving.

### 🎨 Premium User Experience
- **Midnight UI**: A sleek, deep purple and black aesthetic optimized for nighttime usage to reduce eye strain.
- **Time-Aware Greeting**: The app welcomes you with a personalized message based on the time of day.
- **Haptic Feedback**: Subtle tactile responses for interactions like starting/stopping sleep tracking.

## 📱 Technical Details

- **Platform**: iOS 17.0+
- **Language**: Swift 5.10
- **Frameworks**: SwiftUI, SwiftData, CoreMotion, Combine
- **Architecture**: MVVM
- **Orientation**: Optimzed for Portrait Mode

## 🛠 Installation

1. Clone the repository.
2. Open `SleepLedger.xcodeproj` in Xcode.
3. Build and run on your iPhone (Physical device required for accurate motion tracking).

---

&copy; 2024 SleepLedger. Sleep well, track better.
