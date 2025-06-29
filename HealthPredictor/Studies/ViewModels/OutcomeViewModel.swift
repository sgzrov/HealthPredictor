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

    private let healthDataCommunicationService = HealthDataCommunicationService.shared
    private let healthFileCreationService = HealthFileCreationService.shared
    private let textExtractionService = TextExtractionService.shared

    func generateOutcome(from studyText: String) async -> String? {
        isGenerating = true
        outcomeText = nil
        errorMessage = nil

        do {
            guard !studyText.isEmpty else {
                print("No text to generate outcome from.")
                isGenerating = false
                return nil
            }

            let csvPath = try await generateCSVAsync()
            let outcome = try await healthDataCommunicationService.generateOutcome(
                csvFilePath: csvPath,
                studyText: studyText
            )
            self.outcomeText = outcome
            isGenerating = false
            return outcome
        } catch {
            self.errorMessage = "Failed to generate insight: \(error.localizedDescription)"
            isGenerating = false
            return nil
        }
    }

    private func generateCSVAsync() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            healthFileCreationService.generateCSV { url in
                if let url = url {
                    continuation.resume(returning: url.path)
                } else {
                    continuation.resume(throwing: HealthCommunicationError.fileNotFound)
                }
            }
        }
    }
}
