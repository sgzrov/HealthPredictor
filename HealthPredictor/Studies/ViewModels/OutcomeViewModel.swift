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

    func generateOutcome(from studyText: String, using healthMetrics: [String: HealthMetricHistory]) async {
        isGenerating = true
        outcomeText = nil
        errorMessage = nil

        let healthMetricsJSON = healthMetrics.mapValues { history in
            HealthMetricHistory(daily: history.daily, monthly: history.monthly)
        }

        guard let healthMetricsData = try? JSONEncoder().encode(healthMetricsJSON),
              let healthMetricsDict = try? JSONSerialization.jsonObject(with: healthMetricsData) as? [String: Any] else {
            isGenerating = false
            return
        }

        let userMessageDict: [String: Any] = [
            "studytext": studyText,
            "metrics": healthMetricsDict
        ]

        // Encode the whole user message as JSON string
        guard let userMessageData = try? JSONSerialization.data(withJSONObject: userMessageDict, options: .prettyPrinted),
              let userMessageString = String(data: userMessageData, encoding: .utf8) else {
            isGenerating = false
            return
        }

        let request = OpenAIRequest(
            model: "gpt-4.5-preview",
            messages: [
                Message(
                    role: "system",
                    content: "You are a health assistant that compares the findings of scientific studies to an individual's personal health data. If there's a link between the findings and a health metric(s), describe what this means for the user and what he must expect. Return 3 sentences and maintain flow thoughout the response. Keep the language accessible, but use techincal vocabularly where needed. Do not return me a summary of the study and do specifically what I asked for."
                ),
                Message(role: "user", content: userMessageString)
            ],
            temperature: 0.6,
            maxTokens: 90
        )

        do {
            let result = try await openAIService.sendChat(request: request)
            self.outcomeText = result
        } catch {
            self.errorMessage = "Failed to generate insight: \(error.localizedDescription)"
        }

        isGenerating = false
    }
}
