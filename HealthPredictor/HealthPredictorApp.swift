//
//  HealthPredictorApp.swift
//  HealthPredictor
//
//  Created by Stephan  on 23.03.2025.
//

import SwiftUI
import Firebase

@main
struct HealthPredictorApp: App {

    @Environment(\.scenePhase) private var scenePhase

    init() {
        HealthStoreService().requestAuthorization { success, error in
            if success {
                print("✅ HealthKit authorized.")
            } else {
                print("❌ HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error.")")
            }
        }
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                CSVManager.shared.generateCSV { fileURL in
                    print("CSV generated at: \(fileURL?.absoluteString ?? "nil")")
                }
            }
        }
    }
}
