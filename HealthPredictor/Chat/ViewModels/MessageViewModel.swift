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

    @Published var messages: [ChatMessage]
    @Published var inputMessage: String = ""
    @Published var isLoading: Bool = false

    private let session: ChatSession
    private let backendService = BackendService.shared
    private let healthFileCacheService = UserFileCacheService.shared
    private let userToken: String

    init(session: ChatSession, userToken: String) {
        self.session = session
        self.userToken = userToken
        self.messages = session.messages // Preload messages from session
    }

    private static let streamingDelay: UInt64 = 4_000_000 // For slowed streaming (better UI)

    func refreshMessages() {
        print("Refreshing messages for session: \(session.conversationId)")
        backendService.fetchChatHistory(conversationId: session.conversationId, userToken: userToken) { messages in
            print("Fetched \(messages.count) messages from backend for session: \(self.session.conversationId)")
            self.messages = messages
            self.session.messages = messages
        }
    }

    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isLoading else { return }

        let userMessage = ChatMessage(content: inputMessage, sender: .user)
        messages.append(userMessage)
        session.messages = messages

        let userInput = inputMessage
        inputMessage = ""
        isLoading = true

        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            let thinkingMessage = ChatMessage(content: "", sender: .assistant, state: .streaming)
            messages.append(thinkingMessage)
            session.messages = messages

            await processMessage(userInput: userInput)
        }
    }

        private func processMessage(userInput: String) async {
        do {
            let needsCodeInterpreter = try await checkIfCodeInterpreterNeeded(message: userInput)
            await sendStreamingMessage(userInput: userInput, needsCodeInterpreter: needsCodeInterpreter)
        } catch {
            addErrorMessage(error.localizedDescription)
        }
        isLoading = false
    }

    private func sendStreamingMessage(userInput: String, needsCodeInterpreter: Bool) async {
        do {
            let stream: AsyncStream<String>

            if needsCodeInterpreter {
                let csvPath = try await generateCSVAsync()
                stream = try await backendService.analyzeHealthData(
                    csvFilePath: csvPath,
                    userInput: userInput,
                    conversationId: session.conversationId
                )
            } else {
                stream = try await backendService.simpleChat(
                    userInput: userInput,
                    conversationId: session.conversationId
                )
            }

            await handleStreamingResponse(stream: stream)
        } catch {
            let errorType = needsCodeInterpreter ? "Chat" : "Simple chat"
            addErrorMessage("\(errorType) streaming error: \(error.localizedDescription)")
        }
    }

    private func handleStreamingResponse(stream: AsyncStream<String>) async {
        let messageIndex = messages.count - 1
        var fullContent = ""

        for await chunk in stream {
            if chunk.hasPrefix("Error: ") {
                messages[messageIndex].content = chunk
                messages[messageIndex].state = .error
                return
            }

            fullContent += chunk
            messages[messageIndex].content = fullContent
            session.messages = messages

            try? await Task.sleep(nanoseconds: Self.streamingDelay)
        }
        messages[messageIndex].state = .complete
        session.messages = messages

        // After streaming is done, reload from backend to avoid duplicates
        await MainActor.run {
            self.refreshMessages()
        }
    }

    private func addErrorMessage(_ debugInfo: String) {
        let errorMessage = ChatMessage(
            content: "Sorry, I'm experiencing technical difficulties right now. Please try again later.",
            sender: .assistant,
            state: .error
        )
        messages.append(errorMessage)
        session.messages = messages
        print("Error: \(debugInfo)")
    }

    private func checkIfCodeInterpreterNeeded(message: String) async throws -> Bool {
        let result = try await backendService.shouldUseCodeInterpreter(userInput: message)
        return result == "yes"
    }

    private func generateCSVAsync() async throws -> String {
        return try await healthFileCacheService.getCachedHealthFile()
    }

    func clearMessages() {
        messages.removeAll()
    }

    func retryLastMessage() {
        guard let lastUserMessage = messages.last(where: { $0.sender == .user }) else { return }
        if let lastUserIndex = messages.lastIndex(where: { $0.sender == .user }) {
            messages = Array(messages.prefix(through: lastUserIndex))
        }

        isLoading = true

        Task {
            await processMessage(userInput: lastUserMessage.content)
            refreshMessages()
        }
    }
}
