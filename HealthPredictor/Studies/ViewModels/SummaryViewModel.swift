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

            // Prompt is built here
            let messages = [
                ["role": "system", "content": "You are a medical research assistant that creates concise and accurate summaries of medical studies."],
                ["role": "user", "content": """
                Please summarize this scientific article in 3 well-written sentences. The first should give a clear overview of the study. The second should explain the most important findings and observed outcomes, using technical but accessible language. The third should add any additional insight, such as correlations, predictions, or notes on the control group if applicable. Avoid oversimplifying and generalizing.

                Text:
                \(text)
                """
                ]
            ]

            let summary = try await openAIService.sendChat(messages: messages)
            self.summarizedText = summary
        } catch {
            print("❌ Failed to summarize: \(error)")
        }

        isSummarizing = false
    }
}
