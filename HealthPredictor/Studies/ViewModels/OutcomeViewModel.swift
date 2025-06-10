//
//  OutcomeViewModel.swift
//  HealthPredictor
//
//  Created by Stephan  on 08.06.2025.
//

import Foundation
import SwiftUI

@MainActor
class OutcomeViewModel: ObservableObject {

    @Published var isGenerating = false
    @Published var outcomeText: String?
    @Published var errorMessage: String?

    private let openAIService = OpenAIService()

    func generateOutcome(from studyText: String, using healthMetrics: [String: String]) async {
        isGenerating = true
        outcomeText = nil
        errorMessage = nil

        // Format health data as bullet points
        let formattedMetrics = healthMetrics.map { "- \($0.key): \($0.value)" }.joined(separator: "\n")

        // Build prompt
        let messages: [[String: String]] = [
            ["role": "system", "content": """
                You are a health assistant that compares scientific research studies to an individual's personal health data and provides medically reasonable conclusions. Be specific and relevant.
                """],
            ["role": "user", "content": """
                Here is a scientific study:

                \(studyText)

                Here is the user's health data:

                \(formattedMetrics)

                Based on this, explain how the study's findings apply to the user and provide a clear, personalized conclusion.
                """]
        ]

        do {
            let result = try await openAIService.sendChat(messages: messages)
            self.outcomeText = result
        } catch {
            self.errorMessage = "❌ Failed to generate insight: \(error.localizedDescription)"
        }

        isGenerating = false
    }
}
