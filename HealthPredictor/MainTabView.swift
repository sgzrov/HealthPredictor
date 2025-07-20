//
//  MainTabView.swift
//  HealthPredictor
//
//  Created by Stephan  on 01.04.2025.
//

import SwiftUI

struct MainTabView: View {
    @State private var healthDataSetup = false

    var body: some View {
        TabView {
            StudiesHomeView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Studies")
                }
            MainChatView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Chat")
                }
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }

        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.black.opacity(0.8), for: .tabBar)
        .task {
            if !healthDataSetup {
                print("User authenticated - starting health data collection")
                UserFileCacheService.shared.setupCSVFile()

                // Pre-create health file after authentication
                do {
                    _ = try await UserFileCacheService.shared.getCachedHealthFile()
                    print("Health file created after authentication")
                } catch {
                    print("Failed to create health file after authentication: \(error)")
                }

                healthDataSetup = true
            }
        }
    }
}

#Preview {
    MainTabView()
}
