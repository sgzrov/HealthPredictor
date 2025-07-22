//
//  MainTabView.swift
//  HealthPredictor
//
//  Created by Stephan  on 01.04.2025.
//

import SwiftUI
import Clerk

struct MainTabView: View {

    @State private var healthDataSetup = false
    @State private var userToken: String = ""

    @Environment(Clerk.self) private var clerk

    var body: some View {
        TabView {
            StudiesHomeView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Studies")
                }
            MainChatView(userToken: userToken)
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
            // Fetch userToken using AuthService
            do {
                userToken = try await AuthService.getAuthToken()
            } catch {
                print("Failed to get Clerk JWT: \(error)")
            }
        }
    }
}

#Preview {
    MainTabView()
}
