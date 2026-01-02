import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("sleepGoalHours") private var sleepGoalHours: Double = 8.0
    @AppStorage("smartAlarmEnabled") private var smartAlarmEnabled = false
    @AppStorage("wakeTimeInterval") private var wakeTimeInterval: Double = 0
    @AppStorage("userName") private var userName = "Sleeper"
    
    @State private var currentPage = 0
    @State private var selectedWakeTime: Date = {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.sleepBackground.ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                // Page 0: Welcome
                welcomePage.tag(0)
                
                // Page 1: Name
                namePage.tag(1)
                
                // Page 2: Medical Disclaimer
                disclaimerPage.tag(2)
                
                // Page 3: Sleep Goal
                sleepGoalPage.tag(3)
                
                // Page 4: Smart Alarm
                smartAlarmPage.tag(4)
                
                // Page 5: Wake Time
                if smartAlarmEnabled {
                    wakeTimePage.tag(5)
                }
                
                // Final Page: Ready
                readyPage.tag(smartAlarmEnabled ? 6 : 5)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
    
    // MARK: - Welcome Page
    
    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.sleepPrimary, .sleepPrimaryGlow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 16) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.sleepTextSecondary)
                
                Text("Orbit")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.sleepTextPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                Text("Track your sleep with precision\nand wake up refreshed")
                    .font(.subheadline)
                    .foregroundColor(.sleepTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            Text("Swipe to continue")
                .font(.caption)
                .foregroundColor(.sleepTextTertiary)
                .padding(.bottom, 40)
        }
        .padding()
    }
    
    // MARK: - Name Page
    
    private var namePage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.sleepPrimary)
            
            VStack(spacing: 16) {
                Text("What should we call you?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.sleepTextPrimary)
                
                Text("Your name helps us personalize your experience")
                    .font(.subheadline)
                    .foregroundColor(.sleepTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            TextField("Your Name", text: $userName)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(hex: "1C1C1E"))
                .cornerRadius(12)
                .padding(.horizontal, 40)
                .submitLabel(.done)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Disclaimer Page
    
    private var disclaimerPage: some View {
        VStack(spacing: 0) {
            DisclaimerView(isOnboarding: true)
            
            Button {
                withAnimation {
                    currentPage = 3
                }
            } label: {
                Text("I Accept & Continue")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - Sleep Goal Page
    
    private var sleepGoalPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "target")
                .font(.system(size: 80))
                .foregroundColor(.sleepPrimary)
            
            VStack(spacing: 16) {
                Text("Set Your Sleep Goal")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.sleepTextPrimary)
                
                Text("How many hours of sleep do you need per night?")
                    .font(.subheadline)
                    .foregroundColor(.sleepTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 24) {
                Text(String(format: "%.1f hours", sleepGoalHours))
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.sleepPrimary)
                
                Slider(value: $sleepGoalHours, in: 4...12, step: 0.5)
                    .tint(.sleepPrimary)
                    .padding(.horizontal, 40)
                
                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("4h")
                            .font(.caption)
                        Text("Minimum")
                            .font(.caption2)
                    }
                    .foregroundColor(.sleepTextTertiary)
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("12h")
                            .font(.caption)
                        Text("Maximum")
                            .font(.caption2)
                    }
                    .foregroundColor(.sleepTextTertiary)
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Smart Alarm Page
    
    private var smartAlarmPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "brain.head.profile.fill")
                .font(.system(size: 80))
                .foregroundColor(.sleepPrimary)
            
            VStack(spacing: 16) {
                Text("Smart Alarm")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.sleepTextPrimary)
                
                Text("Wake up during light sleep for a more refreshed feeling")
                    .font(.subheadline)
                    .foregroundColor(.sleepTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 20) {
                OnboardingFeatureRow(
                    icon: "moon.zzz.fill",
                    title: "Monitors Sleep Stages",
                    description: "Tracks your movement to detect light and deep sleep"
                )
                
                OnboardingFeatureRow(
                    icon: "clock.badge.checkmark.fill",
                    title: "30-Minute Window",
                    description: "Wakes you within 30 min before your target time"
                )
                
                OnboardingFeatureRow(
                    icon: "sparkles",
                    title: "Wake Refreshed",
                    description: "Waking during light sleep feels more natural"
                )
            }
            .padding(.horizontal)
            
            Toggle(isOn: $smartAlarmEnabled) {
                Text("Enable Smart Alarm")
                    .font(.headline)
                    .foregroundColor(.sleepTextPrimary)
            }
            .tint(.sleepPrimary)
            .padding()
            .sleepCard()
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Wake Time Page
    
    private var wakeTimePage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "alarm.fill")
                .font(.system(size: 80))
                .foregroundColor(.sleepPrimary)
            
            VStack(spacing: 16) {
                Text("Set Wake Time")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.sleepTextPrimary)
                
                Text("When do you usually want to wake up?")
                    .font(.subheadline)
                    .foregroundColor(.sleepTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            DatePicker(
                "",
                selection: $selectedWakeTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .tint(.sleepPrimary)
            .frame(maxWidth: .infinity)
            
            Text("You can change this anytime in Settings")
                .font(.caption)
                .foregroundColor(.sleepTextTertiary)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Ready Page
    
    private var readyPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.sleepSuccess)
            
            VStack(spacing: 16) {
                Text("All Set!")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.sleepTextPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                Text("You're ready to start tracking your sleep")
                    .font(.subheadline)
                    .foregroundColor(.sleepTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                SummaryRow(icon: "target", label: "Sleep Goal", value: String(format: "%.1f hours", sleepGoalHours))
                
                if smartAlarmEnabled {
                    SummaryRow(icon: "brain.head.profile.fill", label: "Smart Alarm", value: "Enabled")
                    SummaryRow(icon: "alarm.fill", label: "Wake Time", value: selectedWakeTime.formatted(date: .omitted, time: .shortened))
                } else {
                    SummaryRow(icon: "brain.head.profile", label: "Smart Alarm", value: "Disabled")
                }
            }
            .padding()
            .sleepCard()
            .padding(.horizontal)
            
            Button(action: completeOnboarding) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.sleepPrimary, .sleepPrimaryGlow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func completeOnboarding() {
        // Save wake time if smart alarm is enabled
        if smartAlarmEnabled {
            wakeTimeInterval = selectedWakeTime.timeIntervalSinceReferenceDate
        }
        
        hasCompletedOnboarding = true
        dismiss()
    }
}

// MARK: - Supporting Views

struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.sleepPrimary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.sleepTextPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.sleepTextSecondary)
            }
        }
    }
}

struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.sleepPrimary)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.sleepTextSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.sleepTextPrimary)
        }
    }
}

#Preview {
    OnboardingView()
        .preferredColorScheme(.dark)
}
