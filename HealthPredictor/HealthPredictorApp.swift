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
    init() {
        HealthStoreService().requestAuthorization { success, error in
            if success {
                print("✅ HealthKit authorized")
            } else {
                print("❌ HealthKit authorization failed: \(error?.localizedDescription ?? "unknown error")")
            }
        }
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            StudiesHomeView()
        }
    }
}
