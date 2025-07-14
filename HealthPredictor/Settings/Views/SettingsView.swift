//
//  SettingsView.swift
//  HealthPredictor
//
//  Created by Stephan  on 13.07.2025.
//

import SwiftUI
import Clerk

struct SettingsView: View {

    @Environment(Clerk.self) private var clerk

    var body: some View {
        VStack {
            if clerk.user != nil {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Button("Sign Out") {
                    Task { try? await clerk.signOut() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(Clerk.shared)
}
