//
//  SleepLedgerApp.swift
//  SleepLedger
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct SleepLedgerApp: App {
    @State private var isStoreLoaded = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isStoreLoaded {
                    MainView()
                        .preferredColorScheme(.dark)
                        .modelContainer(ModelContainer.shared)
                        .transition(.opacity)
                } else {
                    SplashScreenView()
                        .preferredColorScheme(.dark)
                        .onAppear {
                            initializeStore()
                            requestNotificationPermission()
                        }
                }
            }
            .animation(.easeInOut(duration: 0.5), value: isStoreLoaded)
        }
    }
    
    private func initializeStore() {
        Task {
            // Accessing ModelContainer.shared for the first time triggers its init
            // We do this in a Task to ensure the UI can at least render the splash
            _ = await MainActor.run {
                _ = ModelContainer.shared
                isStoreLoaded = true
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            } else {
                print("⚠️ Notification permission denied")
            }
        }
    }
}

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color.sleepBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.sleepPrimary)
                
                Text("SleepLedger")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                ProgressView()
                    .tint(.sleepPrimary)
                    .padding(.top, 20)
            }
        }
    }
}

// MARK: - Shared ModelContainer Extension

extension ModelContainer {
    @MainActor
    static var shared: ModelContainer = {
        let schema = Schema([
            SleepSession.self,
            MovementData.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            // If creation fails (e.g. migration error), return an in-memory or empty container to prevent 10s black screen hang
            print("❌ ModelContainer failed: \(error)")
            let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [memConfig])
        }
    }()
}
