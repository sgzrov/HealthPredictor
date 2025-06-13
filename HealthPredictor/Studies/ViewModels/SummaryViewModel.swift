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

            let request = OpenAIRequest(
                model: "gpt-4o-mini",
                messages: [
                    Message(
                        role: "system",
                        content: "You are a health assistant that creates concise and accurate summaries of medical studies. Provide me with a 4-5 sentence paragraph that walks through the exact methods the researchers used to come to a conclusion and then explain the exact findings in detail, including numbers and percentages. Abstain from making obvious points/conclusions the user would have known without reading the study (e.g. insomnia leads to exhaustion) unless needed for context. Use easy language, so a user that is not familiar with techinal health terms (e.g. synaptic plasticity) can understand the summary. Important: Do NOT provide me with an introduction or a generalized summary. Prefer to dive deeper and follow the exact instructions of the prompt."
                    ),
                    Message(
                        role: "user",
                        content: "\(text)"
                    )
                ],
                temperature: 0.7,
                maxTokens: 300
            )

            let summary = try await openAIService.sendChat(request: request)
            self.summarizedText = summary
        } catch {
            print("Failed to summarize: \(error).")
        }

        isSummarizing = false
    }
}
