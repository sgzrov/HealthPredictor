//
//  SummaryViewModel.swift
//  HealthPredictor
//
//  Created by Stephan  on 05.06.2025.
//

import Foundation
import SwiftUI
import PDFKit

@MainActor
class SummaryViewModel: ObservableObject {

    @Published var summarizedText: String?
    @Published var extractedText: String?
    @Published var isSummarizing = false
    @Published var errorMessage: String = ""

    private let healthDataCommunicationService = HealthDataCommunicationService.shared
    private let textExtractionService = TextExtractionService.shared

    func summarizeStudy(text: String) async -> String? {
        isSummarizing = true
        summarizedText = nil
        errorMessage = ""

        do {
            guard !text.isEmpty else {
                print("No text to summarize.")
                isSummarizing = false
                return nil
            }

            self.extractedText = text
            let summary = try await healthDataCommunicationService.summarizeStudy(studyText: text)
            self.summarizedText = summary
            isSummarizing = false
            return summary
        } catch {
            self.errorMessage = "Failed to summarize: \(error.localizedDescription)"
            print("Failed to summarize: \(error).")
            isSummarizing = false
            return nil
        }
    }

    func determineContentType(url: URL) async -> (isPDF: Bool, isHTML: Bool) {
        if url.isFileURL {
            let data = try? Data(contentsOf: url)
            let isPDF = data != nil && PDFDocument(data: data!) != nil
            return (isPDF: isPDF, isHTML: false)
        } else {
            let result = await URLExtensionCheck.checkContentType(url: url)
            return (isPDF: result.type == .pdf, isHTML: result.type == .html)
        }
    }
}
