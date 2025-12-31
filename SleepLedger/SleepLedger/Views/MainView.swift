//
//  MainView.swift
//  SleepLedger
//
//  Main navigation - optimized 2-tab structure
//

import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingOnboarding = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SleepView()
                .tabItem {
                    Label("Sleep", systemImage: "moon.stars.fill")
                }
                .tag(0)
            
            JournalView()
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }
                .tag(1)
        }
        .tint(.sleepPrimary)
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView()
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showingOnboarding = true
            }
        }
    }
}

#Preview {
    MainView()
        .preferredColorScheme(.dark)
}
