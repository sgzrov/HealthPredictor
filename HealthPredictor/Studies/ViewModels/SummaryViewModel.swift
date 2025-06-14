//
//  SummaryViewModel.swift
//  HealthPredictor
//
//  Created by Stephan  on 05.06.2025.
//

import Foundation
import SwiftUI

@MainActor
class SummaryViewModel: TagExtractionViewModel {

    @Published var summarizedText: String?
    @Published var extractedText: String?
    @Published var isSummarizing = false

    private let openAIService = OpenAIService()

    private func loadSummaryPrompt(named filename: String) -> String {
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil),
              let prompt = try? String(contentsOf: url, encoding: .utf8) else {
            return ""
        }
        return prompt
    }

    func summarizeStudy(from url: URL) async {
        isSummarizing = true
        summarizedText = nil

        do {
            let data = try await fetchData(for: url)

            await validateFileType(url: url)

            let text = extractText(from: data, isPDF: isPDF, isHTML: isHTML)
            self.extractedText = text
            print("Extracted text length: \(text.count)")

            guard !text.isEmpty else {
                print("No text extracted from file.")
                isSummarizing = false
                return
            }

            let summaryPrompt = loadSummaryPrompt(named: "SummaryPrompt")
            let request = OpenAIRequest(
                model: "gpt-4o-mini",
                messages: [
                    Message(
                        role: "system",
                        content: summaryPrompt
                    ),
                    Message(
                        role: "user",
                        content: "\(text)"
                    )
                ],
                temperature: 0.8,
                maxTokens: 400
            )

            let summary = try await openAIService.sendChat(request: request)
            self.summarizedText = summary
        } catch {
            print("Failed to summarize: \(error).")
        }

        isSummarizing = false
    }
}
