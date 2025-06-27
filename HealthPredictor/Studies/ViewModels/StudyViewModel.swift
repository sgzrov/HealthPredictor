//
//  StudyViewModel.swift
//  HealthPredictor
//
//  Created by Stephan  on 16.06.2025.
//

import Foundation
import SwiftUI

enum StudyCategory {
    case recommended
    case all
}

@MainActor
class StudyViewModel: ObservableObject {

    @Published var selectedCategory: StudyCategory = .recommended
    @Published var recommendedStudies: [Study] = []
    @Published var allStudies: [Study] = []

    func loadStudies() {
        let sampleStudies = [
            Study(
                title: "Heart Health Study",
                summary: "A comprehensive study about heart health.",
                personalizedInsight: "Your heart health metrics show positive trends.",
                sourceURL: URL(string: "https://example.com/heart")!
            )
        ]

        recommendedStudies = []
        allStudies = sampleStudies
    }

    func updateOutcome(for id: UUID, outcome: String) {
        if let index = allStudies.firstIndex(where: { $0.id == id }) {
            allStudies[index].personalizedInsight = outcome
        }
        if let index = recommendedStudies.firstIndex(where: { $0.id == id }) {
            recommendedStudies[index].personalizedInsight = outcome
        }
    }

    func updateSummary(for id: UUID, summary: String) {
        if let index = allStudies.firstIndex(where: { $0.id == id }) {
            allStudies[index].summary = summary
        }
        if let index = recommendedStudies.firstIndex(where: { $0.id == id }) {
            recommendedStudies[index].summary = summary
        }
    }
}
