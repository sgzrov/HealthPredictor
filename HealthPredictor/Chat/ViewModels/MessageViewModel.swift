//
//  MessageViewModel.swift
//  HealthPredictor
//
//  Created by Stephan  on 18.06.2025.
//

import Foundation
import SwiftUI

@MainActor
class MessageViewModel: ObservableObject {

    @Published var messages: [ChatMessage] = []
    @Published var inputMessage: String = ""
    @Published var isLoading: Bool = false

    private let healthDataCommunicationService = HealthDataCommunicationService.shared
    private let healthFileCreationService = HealthFileCreationService.shared
    private let conversationId = UUID().uuidString

    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isLoading else { return }

        let userMessage = ChatMessage(content: inputMessage, sender: .user)
        messages.append(userMessage)

        let userInput = inputMessage
        inputMessage = ""
        isLoading = true

        Task {
            await sendToBackend(userInput: userInput)
        }
    }

    private func sendToBackend(userInput: String) async {
        do {
            let needsCodeInterpreter = try await checkIfCodeInterpreterNeeded(message: userInput)

            if needsCodeInterpreter {
                let csvPath = try await generateCSVAsync()
                let response = try await healthDataCommunicationService.analyzeHealthData(
                    csvFilePath: csvPath,
                    userInput: userInput,
                    conversationId: conversationId
                )

                let assistantMessage = ChatMessage(
                    content: response,
                    sender: .assistant
                )
                self.messages.append(assistantMessage)
            } else {
                let response = try await healthDataCommunicationService.simpleChat(userInput: userInput, conversationId: conversationId)

                let assistantMessage = ChatMessage(
                    content: response,
                    sender: .assistant
                )
                self.messages.append(assistantMessage)
            }
        } catch {
            let errorMessage = ChatMessage(
                content: "I'm having trouble processing your request right now. Please try again later.",
                sender: .assistant
            )
            self.messages.append(errorMessage)
            print("Backend API error: \(error.localizedDescription)")
        }

        isLoading = false
    }

    private func checkIfCodeInterpreterNeeded(message: String) async throws -> Bool {
        let result = try await healthDataCommunicationService.shouldUseCodeInterpreter(userInput: message)
        return result == "yes"
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
