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
    @State private var userId: String = ""
    @State private var isSignedIn: Bool = false

    @Environment(Clerk.self) private var clerk

    var body: some View {
        TabView {
            if !userToken.isEmpty {
                StudiesHomeView(userToken: userToken)
                    .tabItem {
                        Image(systemName: "list.bullet.rectangle")
                        Text("Studies")
                    }
                MainChatView(userToken: userToken)
                    .tabItem {
                        Image(systemName: "message")
                        Text("Chat")
                    }
            } else {
                VStack {
                    ProgressView()
                    Text("Signing in...")
                        .foregroundColor(.secondary)
                }
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Studies")
                }
                VStack {
                    ProgressView()
                    Text("Signing in...")
                        .foregroundColor(.secondary)
                }
                .tabItem {
                    Image(systemName: "message")
                    Text("Chat")
                }
            }
            SettingsView(onSignOut: {
                userToken = ""
                userId = ""
                isSignedIn = false
                TokenManager.shared.clearCachedToken()
                print("[DEBUG] Signed out, cleared userToken, userId, and cached token")
            })
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.black.opacity(0.8), for: .tabBar)
        .task {
            await refreshAuthState()
        }
        .onChange(of: clerk.session) { _, newSession in
            Task { await refreshAuthState() }
        }
    }

    private func refreshAuthState() async {
        print("[DEBUG] refreshAuthState called at \(Date())")
        guard let session = clerk.session else {
            print("[DEBUG] No Clerk session, user not signed in")
            userToken = ""
            userId = ""
            isSignedIn = false
            return
        }
        print("[DEBUG] Clerk session found, user ID: \(session.user?.id ?? "nil")")
        do {
            let token = try await TokenManager.shared.getValidToken()
            userToken = token
            userId = session.user?.id ?? ""
            isSignedIn = true
            print("[DEBUG] Successfully got auth token from TokenManager, length: \(token.count)")
            if !healthDataSetup {
                print("User authenticated - starting health data collection")
                UserFileCacheService.shared.setupCSVFile()
                do {
                    _ = try await UserFileCacheService.shared.getCachedHealthFile()
                    print("Health file created after authentication")
                } catch {
                    print("Failed to create health file after authentication: \(error)")
                }
                healthDataSetup = true
            }
        } catch {
            print("[DEBUG] Failed to get Clerk JWT: \(error)")
            userToken = ""
            userId = ""
            isSignedIn = false
        }
    }
}

#Preview {
    MainTabView()
}
