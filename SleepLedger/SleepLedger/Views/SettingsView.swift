import SwiftUI
import SwiftData

struct SettingsView: View {
    // MARK: - Persistent Settings
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("sleepGoalHours") private var sleepGoalHours: Double = 8.0
    @AppStorage("targetSleepEntryTime") private var targetSleepEntryTime: Double = 22.5 // 10:30 PM represented as hours
    
    // MARK: - State
    @State private var showingExportSheet = false
    @State private var showingAboutSheet = false
    @State private var showingSleepEntryPicker = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // General Section
                        buildSection(title: "GENERAL") {
                            ToggleRow(icon: "iphone.gen3", iconColor: Color(hex: "5C3B4B"), title: "Haptic Feedback", isOn: $hapticFeedback)
                            Divider().overlay(Color.white.opacity(0.1))
                            
                            // Sleep Goal Slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "target")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .frame(width: 32, height: 32)
                                        .background(Color(hex: "4A4458"))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    Text("Sleep Goal: \(String(format: "%.1f", sleepGoalHours))h")
                                        .font(.body)
                                        .foregroundStyle(.white)
                                }
                                Slider(value: $sleepGoalHours, in: 4...12, step: 0.5)
                                    .tint(Color(hex: "8B5CF6"))
                            }
                            .padding()
                        }
                        
                        // Data Management Section
                        buildSection(title: "DATA MANAGEMENT") {
                            Button {
                                showingExportSheet = true
                            } label: {
                                SettingsRow(icon: "square.and.arrow.up", iconColor: Color(hex: "2C3E50"), title: "Export Data")
                            }
                        }
                        
                        // Reminders Section
                        buildSection(title: "REMINDERS") {
                            Button {
                                withAnimation {
                                    showingSleepEntryPicker.toggle()
                                }
                            } label: {
                                SettingsRow(
                                    icon: "moon.zzz.fill",
                                    iconColor: Color(hex: "342E40"),
                                    title: "Sleep Entry Target",
                                    value: formatTime(from: targetSleepEntryTime),
                                    valueIsHighlight: true
                                )
                            }
                            if showingSleepEntryPicker {
                                Divider().overlay(Color.white.opacity(0.1))
                                DatePicker("", selection: Binding(
                                    get: {
                                        let hour = Int(targetSleepEntryTime)
                                        let minute = Int((targetSleepEntryTime.truncatingRemainder(dividingBy: 1) * 60).rounded())
                                        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
                                    },
                                    set: { newDate in
                                        let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                        if let h = components.hour, let m = components.minute {
                                            targetSleepEntryTime = Double(h) + Double(m) / 60.0
                                        }
                                    }
                                ), displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .environment(\.colorScheme, .dark)
                            }
                        }
                        
                        // About Section
                        buildSection(title: "ABOUT SLEEPLEDGER") {
                            Button {
                                showingAboutSheet = true
                            } label: {
                                SettingsRow(icon: "info.circle.fill", iconColor: Color(hex: "3E3E3E"), title: "Version", value: "v1.0.2")
                            }
                        }
                        
                        // Footer
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                Text("No Subscription Required")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(Color(hex: "9F7AEA"))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color(hex: "9F7AEA").opacity(0.15))
                            .clipShape(Capsule())
                            
                            Text("SleepLedger Inc. © 2024")
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 100)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingExportSheet) {
            ExportDataView()
        }
        .sheet(isPresented: $showingAboutSheet) {
            AboutView()
        }
    }
    
    var headerView: some View {
        HStack {
            Image(systemName: "person.fill")
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color(hex: "341963")) // Deep Profile Purple
                .clipShape(Circle())
            
            Spacer()
            
            Text("Settings")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Spacer()
            
            // Invisible spacer to balance the header centering
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding()
        .background(Color.black)
    }
    
    func buildSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.gray)
                .padding(.leading, 8)
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color(hex: "151517"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    func formatTime(from hours: Double) -> String {
        let hour = Int(hours)
        let minute = Int((hours.truncatingRemainder(dividingBy: 1) * 60).rounded())
        let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}

// MARK: - Components

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var value: String? = nil
    var valueIsHighlight: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(getForeground(for: iconColor))
                .frame(width: 32, height: 32)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(title)
                .font(.body)
                .foregroundStyle(.white)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(valueIsHighlight ? Color(hex: "9F7AEA") : Color.gray)
                    .padding(.horizontal, valueIsHighlight ? 8 : 0)
                    .padding(.vertical, valueIsHighlight ? 4 : 0)
                    .background(valueIsHighlight ? Color(hex: "9F7AEA").opacity(0.15) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.gray.opacity(0.7))
        }
        .padding()
        // Ensure the entire row is tappable if inside a button
        .contentShape(Rectangle()) 
    }
    
    func getForeground(for bg: Color) -> Color {
        return .white.opacity(0.8)
    }
}

struct ToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 32, height: 32)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(title)
                .font(.body)
                .foregroundStyle(.white)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "8B5CF6")))
                .labelsHidden()
        }
        .padding()
    }
}

// MARK: - Sheets

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color(hex: "6B35F6"))
                        .padding(.top, 40)
                    
                    Text("Export Data")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("Your data will be exported as a JSON file containing all sleep sessions and derived metrics.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.gray)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    if let fileURL = generateJSONFile() {
                        ShareLink(item: fileURL) {
                            Text("Share / Save File")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "6B35F6"))
                                .cornerRadius(12)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    func generateJSONFile() -> URL? {
        // Create a temporary file
        let fileName = "sleep_data.json"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        // Dummy data
        let jsonString = """
        {
            "app": "SleepLedger",
            "version": "1.0.2",
            "exportDate": "\(Date().formatted())",
            "sessions": []
        }
        """
        
        do {
            try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing JSON: \(error)")
            return nil
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(Color(hex: "6B35F6"))
                            .padding(.top, 40)
                        
                        Text("SleepLedger")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text("Version 1.0.2")
                            .foregroundStyle(.gray)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("A privacy-focused sleep tracker designed to help you understand and improve your sleep habits.")
                                .foregroundStyle(.white)
                        }
                        .padding()
                        .background(Color(hex: "1C1C1E"))
                        .cornerRadius(16)
                        .padding()
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
