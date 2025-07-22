//
//  ChatHistoryViewModel.swift
//  HealthPredictor
//
//  Created by Stephan  on 09.07.2025.
//

import Foundation
import SwiftUI

@MainActor
class ChatHistoryViewModel: ObservableObject {

    @Published var chatSessions: [ChatSession] = []
    @Published var selectedSession: ChatSession?
    @Published var searchText: String = ""
    var userToken: String

    init(userToken: String) {
        self.userToken = userToken
        loadChatSessions()
    }

    func createNewChat() -> ChatSession {
        let newSession = ChatSession()
        chatSessions.insert(newSession, at: 0)
        return newSession
    }

    func loadChatSessions() {
        BackendService.shared.fetchChatSessions(userToken: userToken) { ids in
            self.chatSessions = []
            for id in ids {
                BackendService.shared.fetchChatHistory(conversationId: id, userToken: self.userToken) { messages in
                    let session = ChatSession(conversationId: id, messages: messages)
                    self.chatSessions.append(session)
                }
            }
        }
    }

    func updateChatSession(_ session: ChatSession) {
        if let index = chatSessions.firstIndex(where: { $0.id == session.id }) {
            chatSessions[index] = session
        }
    }

    func deleteChatSession(_ session: ChatSession) {
        chatSessions.removeAll { $0.id == session.id }
    }

    var filteredSessions: [ChatSession] {
        if searchText.isEmpty {
            return chatSessions
        } else {
            return chatSessions.filter { session in
                session.title.localizedCaseInsensitiveContains(searchText) ||
                session.messages.contains { message in
                    message.content.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    }
}