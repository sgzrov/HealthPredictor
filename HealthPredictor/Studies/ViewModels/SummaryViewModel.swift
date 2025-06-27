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
class SummaryViewModel: TagExtractionViewModel {

    @Published var summarizedText: String?
    @Published var extractedText: String?
    @Published var isSummarizing = false

    private let healthDataCommunicationService = HealthDataCommunicationService()

    func summarizeStudy(from url: URL) async {
        isSummarizing = true
        summarizedText = nil
        errorMessage = ""

        do {
            let data = try await fetchData(for: url)
            let contentType = await determineContentType(url: url)
            let text = extractText(from: data, isPDF: contentType.isPDF, isHTML: contentType.isHTML)
            self.extractedText = text
            print("Extracted text length: \(text.count)")

            guard !text.isEmpty else {
                print("No text extracted from file.")
                isSummarizing = false
                return
            }

            let summary = try await healthDataCommunicationService.summarizeStudy(studyText: text)
            self.summarizedText = summary
        } catch {
            self.errorMessage = "Failed to summarize: \(error.localizedDescription)"
            print("Failed to summarize: \(error).")
        }

        isSummarizing = false
    }

    private func determineContentType(url: URL) async -> (isPDF: Bool, isHTML: Bool) {
        if url.isFileURL {
            let data = try? Data(contentsOf: url)
            let isPDF = data != nil && PDFDocument(data: data!) != nil
            return (isPDF: isPDF, isHTML: false)
        } else {
            let result = await URLExtensionCheck().checkContentType(url: url)
            return (isPDF: result.type == .pdf, isHTML: result.type == .html)
        }
    }
}
