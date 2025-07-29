//
//  StudyViewModel.swift
//  HealthPredictor
//
//  Created by Stephan  on 16.06.2025.
//

import Foundation
import SwiftUI

@MainActor
class StudyViewModel: ObservableObject {

    @Published var studies: [Study] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""

    private let userToken: String
    private let backendService = BackendService.shared

    init(userToken: String) {
        self.userToken = userToken
        loadStudies()
    }

    func loadStudies() {
        isLoading = true
        errorMessage = ""

        backendService.fetchStudies(userToken: userToken) { [weak self] studies in
            DispatchQueue.main.async {
                self?.studies = studies
                self?.isLoading = false
            }
        }
    }

    func createStudy(title: String, summary: String = "", outcome: String = "") {
        isLoading = true
        errorMessage = ""

        backendService.createStudy(userToken: userToken, title: title, summary: summary, outcome: outcome) { [weak self] study in
            DispatchQueue.main.async {
                if let study = study {
                    self?.studies.insert(study, at: 0)
                } else {
                    self?.errorMessage = "Failed to create study"
                }
                self?.isLoading = false
            }
        }
    }
}
