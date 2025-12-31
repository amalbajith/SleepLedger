//
//  SettingsView.swift
//  SleepLedger
//
//  App settings and configuration
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("sleepGoalHours") private var sleepGoalHours: Double = 8.0
    @AppStorage("smartAlarmEnabled") private var smartAlarmEnabled: Bool = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    
    @State private var showingAbout = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Sleep Goal Section
                sleepGoalSection
                
                // Smart Alarm Section
                smartAlarmSection
                
                // Notifications Section
                notificationsSection
                
                // Data & Privacy Section
                dataPrivacySection
                
                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(Color.sleepBackground)
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
    
    // MARK: - Sleep Goal Section
    
    private var sleepGoalSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.sleepPrimary)
                    Text("Sleep Goal")
                        .foregroundColor(.sleepTextPrimary)
                    Spacer()
                    Text(String(format: "%.1f hours", sleepGoalHours))
                        .foregroundColor(.sleepTextSecondary)
                }
                
                Slider(value: $sleepGoalHours, in: 4...12, step: 0.5)
                    .tint(.sleepPrimary)
                
                Text("Your target sleep duration per night")
                    .font(.caption)
                    .foregroundColor(.sleepTextSecondary)
            }
            .padding(.vertical, 8)
        } header: {
            Text("Sleep Settings")
                .foregroundColor(.sleepTextSecondary)
        }
    }
    
    // MARK: - Smart Alarm Section
    
    private var smartAlarmSection: some View {
        Section {
            Toggle(isOn: $smartAlarmEnabled) {
                HStack {
                    Image(systemName: "alarm.fill")
                        .foregroundColor(.sleepSecondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Smart Alarm")
                            .foregroundColor(.sleepTextPrimary)
                        Text("Wake during light sleep")
                            .font(.caption)
                            .foregroundColor(.sleepTextSecondary)
                    }
                }
            }
            .tint(.sleepPrimary)
            
            if smartAlarmEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The smart alarm will wake you during light sleep within 20 minutes before your target time.")
                        .font(.caption)
                        .foregroundColor(.sleepTextSecondary)
                }
            }
        } header: {
            Text("Alarm")
                .foregroundColor(.sleepTextSecondary)
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $notificationsEnabled) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.sleepPrimary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notifications")
                            .foregroundColor(.sleepTextPrimary)
                        Text("Alarm and reminders")
                            .font(.caption)
                            .foregroundColor(.sleepTextSecondary)
                    }
                }
            }
            .tint(.sleepPrimary)
        } header: {
            Text("Notifications")
                .foregroundColor(.sleepTextSecondary)
        }
    }
    
    // MARK: - Data & Privacy Section
    
    private var dataPrivacySection: some View {
        Section {
            NavigationLink {
                DataPrivacyView()
            } label: {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.sleepSuccess)
                    Text("Data & Privacy")
                        .foregroundColor(.sleepTextPrimary)
                }
            }
            
            NavigationLink {
                ExportDataView()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up.fill")
                        .foregroundColor(.sleepPrimary)
                    Text("Export Data")
                        .foregroundColor(.sleepTextPrimary)
                }
            }
        } header: {
            Text("Privacy")
                .foregroundColor(.sleepTextSecondary)
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            Button {
                showingAbout = true
            } label: {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.sleepSecondary)
                    Text("About SleepLedger")
                        .foregroundColor(.sleepTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.sleepTextTertiary)
                }
            }
            
            HStack {
                Text("Version")
                    .foregroundColor(.sleepTextPrimary)
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.sleepTextSecondary)
            }
        } header: {
            Text("About")
                .foregroundColor(.sleepTextSecondary)
        }
    }
}

// MARK: - Data Privacy View

struct DataPrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.sleepSuccess, .sleepPrimary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Your Privacy Matters")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.sleepTextPrimary)
                    
                    Text("SleepLedger is built with privacy at its core")
                        .font(.subheadline)
                        .foregroundColor(.sleepTextSecondary)
                }
                
                Divider()
                    .background(Color.sleepCardBorder)
                
                PrivacyFeature(
                    icon: "iphone.and.arrow.forward",
                    title: "100% Local Storage",
                    description: "All your sleep data is stored locally on your device using SwiftData. Nothing is sent to external servers."
                )
                
                PrivacyFeature(
                    icon: "icloud.slash.fill",
                    title: "No Cloud Sync",
                    description: "Your data never leaves your device. No cloud storage, no backups to third-party servers."
                )
                
                PrivacyFeature(
                    icon: "person.crop.circle.badge.xmark",
                    title: "No Account Required",
                    description: "No sign-up, no login, no email required. Just install and start tracking."
                )
                
                PrivacyFeature(
                    icon: "chart.bar.xaxis",
                    title: "No Analytics",
                    description: "We don't track your usage, collect analytics, or send telemetry data."
                )
                
                PrivacyFeature(
                    icon: "dollarsign.circle.fill",
                    title: "No Subscriptions",
                    description: "One-time purchase, no recurring fees, no premium tiers with data access."
                )
                
                Divider()
                    .background(Color.sleepCardBorder)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Permissions Used")
                        .font(.headline)
                        .foregroundColor(.sleepTextPrimary)
                    
                    Text("• Motion & Fitness: To track movement during sleep")
                        .font(.subheadline)
                        .foregroundColor(.sleepTextSecondary)
                    
                    Text("• Notifications: For smart alarm alerts")
                        .font(.subheadline)
                        .foregroundColor(.sleepTextSecondary)
                }
            }
            .padding()
        }
        .background(Color.sleepBackground)
        .navigationTitle("Data & Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.sleepSuccess)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.sleepTextPrimary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.sleepTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Export Data View

struct ExportDataView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingExportSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.sleepPrimary, .sleepSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Export Your Data")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.sleepTextPrimary)
                    
                    Text("Download all your sleep data in JSON format")
                        .font(.subheadline)
                        .foregroundColor(.sleepTextSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Button {
                    exportData()
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Export as JSON")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.sleepPrimary, .sleepSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("What's included:")
                        .font(.headline)
                        .foregroundColor(.sleepTextPrimary)
                    
                    ExportItem(text: "All sleep sessions with timestamps")
                    ExportItem(text: "Sleep quality scores and metrics")
                    ExportItem(text: "Movement data and sleep stages")
                    ExportItem(text: "Sleep debt calculations")
                    ExportItem(text: "Notes and tags")
                }
                .padding()
                .sleepCard()
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.sleepBackground)
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Export Successful", isPresented: $showingExportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your sleep data has been exported successfully.")
        }
    }
    
    private func exportData() {
        // TODO: Implement actual export functionality
        showingExportSuccess = true
    }
}

struct ExportItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.sleepSuccess)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.sleepTextSecondary)
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.sleepPrimary, .sleepSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("SleepLedger")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.sleepTextPrimary)
                        
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.sleepTextSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("A privacy-focused sleep tracker that uses a manual 'Punch In/Out' system with accelerometer-based movement detection.")
                            .font(.body)
                            .foregroundColor(.sleepTextSecondary)
                            .multilineTextAlignment(.center)
                        
                        Divider()
                            .background(Color.sleepCardBorder)
                        
                        FeatureRow(icon: "hand.tap.fill", text: "Manual punch in/out system")
                        FeatureRow(icon: "waveform.path.ecg", text: "Accelerometer-based tracking")
                        FeatureRow(icon: "moon.fill", text: "Sleep stage classification")
                        FeatureRow(icon: "chart.line.downtrend.xyaxis", text: "Sleep debt calculation")
                        FeatureRow(icon: "alarm.fill", text: "Smart alarm (light sleep)")
                        FeatureRow(icon: "lock.shield.fill", text: "100% private & local")
                    }
                    .padding()
                    .sleepCard()
                    
                    Text("Built with ❤️ for better sleep")
                        .font(.caption)
                        .foregroundColor(.sleepTextTertiary)
                }
                .padding()
            }
            .background(Color.sleepBackground)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.sleepPrimary)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.sleepTextSecondary)
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
