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

    private let openAIService = OpenAIService()

    private func loadOutcomePrompt(named filename: String) -> String {
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil),
              let prompt = try? String(contentsOf: url, encoding: .utf8) else {
            return ""
        }
        return prompt
    }

    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Add user message
        let userMessage = ChatMessage(content: inputMessage, sender: .user)
        messages.append(userMessage)

        // Store the user's message for the API call
        let userInput = inputMessage

        // Clear input
        inputMessage = ""

        isLoading = true

        Task {
            await sendToOpenAI(userInput: userInput)
        }
    }

    func sendToOpenAI(userInput: String) async {
        let chatPrompt = loadOutcomePrompt(named: "ChatPrompt")
        let request = OpenAIRequest(
            model: "gpt-4.1-mini",
            messages: [
                Message(
                    role: "system",
                    content: chatPrompt
                ),
                Message(
                    role: "user",
                    content: userInput
                )
            ],
            temperature: 0.85,
            maxTokens: 600
        )

        do {
            let result = try await openAIService.sendChat(request: request)
            let assistantMessage = ChatMessage(
                content: result,
                sender: .assistant
            )
            self.messages.append(assistantMessage)
        } catch {
            let errorMessage = ChatMessage(
                content: "Sorry, I'm having trouble connecting right now. Please try again later.",
                sender: .assistant
            )
            self.messages.append(errorMessage)
            print("OpenAI API error: \(error.localizedDescription)")
        }

        isLoading = false
    }
}
