//
//  DisclaimerView.swift
//  SleepLedger
//
//  Medical and legal disclaimer
//

import SwiftUI

struct DisclaimerView: View {
    @Environment(\.dismiss) private var dismiss
    var isOnboarding: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            if !isOnboarding {
                HStack {
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.sleepPrimary)
                }
                .padding()
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.sleepWarning)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    
                    Text("Medical Disclaimer")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.sleepTextPrimary)
                    
                    Text("SleepLedger is designed for wellness tracking purposes only. It is NOT a medical device and is not intended for the diagnosis, monitoring, or treatment of any medical condition or disease.")
                        .font(.body)
                        .foregroundColor(.sleepTextPrimary)
                    
                    Text("Professional Advice")
                        .font(.headline)
                        .foregroundColor(.sleepTextPrimary)
                    
                    Text("The information providing by SleepLedger should not replace professional medical advice. Always consult with a qualified healthcare provider for any health-related concerns, especially regarding sleep disorders.")
                        .font(.body)
                        .foregroundColor(.sleepTextPrimary)
                    
                    Text("No Guarantees")
                        .font(.headline)
                        .foregroundColor(.sleepTextPrimary)
                    
                    Text("Sleep tracking accuracy can vary based on device placement and external factors. The 'Sleep Quality' and 'Stages' are estimates based on movement data and should be used as a general guide, not as clinical data.")
                        .font(.body)
                        .foregroundColor(.sleepTextPrimary)
                    
                    Text("By using this application, you acknowledge that you have read and understood this disclaimer.")
                        .font(.footnote)
                        .foregroundColor(.sleepTextSecondary)
                        .padding(.top)
                }
                .padding()
            }
        }
        .background(Color.sleepBackground)
    }
}

#Preview {
    DisclaimerView()
        .preferredColorScheme(.dark)
}
