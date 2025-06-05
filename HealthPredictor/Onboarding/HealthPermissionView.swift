//
//  HealthPermissionView.swift
//  HealthPredictor
//
//  Created by Stephan  on 24.03.2025.
//

import SwiftUI

struct HealthPermissionView: View {
    let healthStore = HealthStoreService()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("We need access to your Health data:")
                .font(.title2)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 10) {
                Label("Heart Rate", systemImage: "heart.fill")
                Label("Sleep", systemImage: "bed.double.fill")
                Label("Steps", systemImage: "figure.walk")
                Label("Calories", systemImage: "flame.fill")
            }

            Button("Allow Health Access") {
                healthStore.requestAuthorization { success, error in
                    if success {
                        // Continue to next onboarding screen or Home
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    HealthPermissionView()
}
