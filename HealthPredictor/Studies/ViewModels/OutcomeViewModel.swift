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

    func generateOutcome(from studyText: String) async -> String? {
        isGenerating = true
        outcomeText = nil
        errorMessage = nil

        do {
            guard !studyText.isEmpty else {
                isGenerating = false
                return nil
            }

            let csvPath = try await generateCSVAsync()
            var fullOutcome = ""
            let stream = try await healthDataCommunicationService.generateOutcomeStream(csvFilePath: csvPath, userInput: studyText)

            for await chunk in stream {
                if chunk.hasPrefix("Error: ") {
                    print("Outcome error chunk: \(chunk)")
                    self.errorMessage = chunk
                    isGenerating = false
                    return nil
                }
                fullOutcome += chunk
                self.outcomeText = fullOutcome

                try await Task.sleep(nanoseconds: 4_000_000)
            }

            isGenerating = false
            return fullOutcome
        } catch {
            self.errorMessage = "Failed to generate outcome: \(error.localizedDescription)"
            print("Exception in generateOutcome: \(error)")
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
