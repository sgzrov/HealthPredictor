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

    private func loadOutcomePrompt(named filename: String) -> String {
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil),
              let prompt = try? String(contentsOf: url, encoding: .utf8) else {
            return ""
        }
        return prompt
    }

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

        guard let userMessageData = try? JSONSerialization.data(withJSONObject: userMessageDict, options: .prettyPrinted),
              let userMessageString = String(data: userMessageData, encoding: .utf8) else {
            isGenerating = false
            return
        }

        // Debug print: Show the health metrics JSON being sent
        print("[OutcomeViewModel] Health metrics JSON sent to OpenAI:\n\(userMessageString)")

        let outcomePrompt = loadOutcomePrompt(named: "OutcomePrompt")
        let request = OpenAIRequest(
            model: "gpt-4o-mini",
            messages: [
                Message(
                    role: "system",
                    content: outcomePrompt
                ),
                Message(role: "user", content: userMessageString)
            ],
            temperature: 0.75,
            maxTokens: 800
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
