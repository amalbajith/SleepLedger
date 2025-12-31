import SwiftUI

struct DisclaimerView: View {
    var isOnboarding: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !isOnboarding {
                    HStack {
                        Spacer()
                        Capsule()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 4)
                        Spacer()
                    }
                    .padding(.top)
                }
                
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.orange)
                    Text("Medical Disclaimer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .padding(.top, isOnboarding ? 40 : 0)
                
                Text("Not a Medical Device")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("SleepLedger is designed for informational purposes only. It is not a medical device and should not be used to diagnose, treat, cure, or prevent any medical conditions or sleep disorders.")
                    .foregroundStyle(.gray)
                
                Text("Consult a Professional")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("If you have concerns about your sleep health or suspect you may have a sleep disorder (such as sleep apnea or insomnia), please consult a qualified healthcare professional.")
                    .foregroundStyle(.gray)
                
                Text("Accuracy of Data")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("While we strive for accuracy, movement-based sleep tracking has limitations compared to clinical polysomnography. Data provided by this app should be viewed as estimates/trends rather than absolute medical data.")
                    .foregroundStyle(.gray)
                
                if !isOnboarding {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Close")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "1C1C1E"))
                            .cornerRadius(12)
                    }
                    .padding(.top, 20)
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    DisclaimerView()
}
