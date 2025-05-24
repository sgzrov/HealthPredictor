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
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            StudiesHomeView()
        }
    }
}
