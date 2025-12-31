//
//  SleepLedgerApp.swift
//  SleepLedger
//

import SwiftUI
import SwiftData

@main
struct SleepLedgerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SleepSession.self,
            MovementData.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Shared ModelContainer Extension

extension ModelContainer {
    static var shared: ModelContainer = {
        let schema = Schema([
            SleepSession.self,
            MovementData.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
