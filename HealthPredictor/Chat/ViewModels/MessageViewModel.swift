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

    @Published var isLoading: Bool = false
    @Published var inputMessage: String = ""
    @Published var messages: [ChatMessage]

    private var session: ChatSession

    private let backendService = BackendService.shared
    private let healthFileCacheService = UserFileCacheService.shared

    private let userToken: String

    private static let streamingDelay: UInt64 = 4_000_000

    init(session: ChatSession, userToken: String) {
        self.session = session
        self.userToken = userToken
        self.messages = session.messages
    }

    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isLoading else { return }

        let userMessage = ChatMessage(content: inputMessage, role: .user)
        messages.append(userMessage)
        session.messages = messages

        let userInput = inputMessage
        inputMessage = ""
        isLoading = true

        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            let thinkingMessage = ChatMessage(content: "", role: .assistant, state: .streaming)
            messages.append(thinkingMessage)
            session.messages = messages

            await processMessage(userInput: userInput)
        }
    }

    private func processMessage(userInput: String) async {
        do {
            let needsCodeInterpreter = try await backendService.shouldUseCodeInterpreter(userInput: userInput)
            await sendStreamingMessage(userInput: userInput, needsCodeInterpreter: needsCodeInterpreter)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        isLoading = false
    }

    private func sendStreamingMessage(userInput: String, needsCodeInterpreter: Bool) async {
        do {
            let stream: AsyncStream<String>

            if needsCodeInterpreter {
                let csvPath = try await healthFileCacheService.getCachedHealthFile()
                stream = try await backendService.chatWithCI(
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

            let messageIndex = messages.count - 1
            var isFirstChunk = true
            var fullContent = ""

            for await chunk in stream {
                if isFirstChunk {
                    if let id = extractConversationId(from: chunk) {
                        session.conversationId = id
                    }
                    isFirstChunk = false
                }

                if chunk.hasPrefix("Error: ") {
                    break
                }

                fullContent += chunk
                messages[messageIndex].content = fullContent
                session.messages = messages
                try? await Task.sleep(nanoseconds: Self.streamingDelay)
            }

            messages[messageIndex].state = .complete
            session.messages = messages

            // Notify that chat has been updated
            NotificationCenter.default.post(name: .chatUpdated, object: nil)
        } catch {
            print("Error: \(needsCodeInterpreter ? "Chat" : "Simple chat") streaming error: \(error.localizedDescription)")
        }
    }

    private func extractConversationId(from chunk: String) -> String? {
        if let data = chunk.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let id = json["conversation_id"] as? String {
            return id
        }
        return nil
    }
}
