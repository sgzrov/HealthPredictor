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
                model: "gpt-4.5-preview",
                messages: [
                    Message(
                        role: "system",
                        content: "You are a health assistant that creates concise and accurate 3-sentence summaries of medical studies. Do not include obvious points/conclusions, dive deeper. Use accessible language."
                    )
                ],
                temperature: 0.7,
                maxTokens: 130
            )

            let summary = try await openAIService.sendChat(request: request)
            self.summarizedText = summary
        } catch {
            print("Failed to summarize: \(error).")
        }

        isSummarizing = false
    }
}
