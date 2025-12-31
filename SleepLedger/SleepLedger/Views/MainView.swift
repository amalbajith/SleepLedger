//
//  MainView.swift
//  SleepLedger
//
//  Main navigation - Features a custom glassmorphic floating tab bar
//

import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingOnboarding = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case 0:
                    SleepView()
                case 1:
                    JournalView()
                case 3:
                    SettingsView()
                default:
                    JournalView() // Placeholder for Stats/Insights
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Floating Tab Bar
            customTabBar
                .padding(.bottom, 20)
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView()
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showingOnboarding = true
            }
        }
    }
    
    // MARK: - Tab Bar component
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(icon: "square.grid.2x2.fill", tag: 0)
            tabButton(icon: "calendar", tag: 1)
            tabButton(icon: "chart.bar.xaxis", tag: 2)
            tabButton(icon: "gearshape.fill", tag: 3)
        }
        .padding(.horizontal, 8)
        .frame(height: 64)
        .frame(maxWidth: 300)
        .sleepGlassPanel()
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    private func tabButton(icon: String, tag: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tag
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(selectedTab == tag ? .white : .white.opacity(0.4))
                
                if selectedTab == tag {
                    Circle()
                        .fill(Color.sleepPrimary)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(selectedTab == tag ? Color.white.opacity(0.1) : Color.clear)
            .clipShape(Capsule())
            .padding(4)
        }
    }
}

#Preview {
    MainView()
        .preferredColorScheme(.dark)
}
