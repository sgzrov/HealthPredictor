//
//  ChatSession.swift
//  HealthPredictor
//
//  Created by Stephan  on 09.07.2025.
//

import Foundation

class ChatSession: Identifiable, Hashable, Codable, ObservableObject {

    @Published var title: String
    @Published var messages: [ChatMessage]

    let id: UUID
    let createdAt: Date
    let conversationId: String

    init(id: UUID = UUID(), conversationId: String = UUID().uuidString, title: String = "New Chat", createdAt: Date = Date(), messages: [ChatMessage] = []) {
        self.id = id
        self.conversationId = conversationId
        self.title = title
        self.createdAt = createdAt
        self.messages = messages
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ChatSession, rhs: ChatSession) -> Bool {
        lhs.id == rhs.id && lhs.conversationId == rhs.conversationId
    }

    enum CodingKeys: String, CodingKey {
        case id, conversationId, title, createdAt, messages
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        conversationId = try container.decode(String.self, forKey: .conversationId)
        title = try container.decode(String.self, forKey: .title)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        messages = try container.decode([ChatMessage].self, forKey: .messages)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(conversationId, forKey: .conversationId)
        try container.encode(title, forKey: .title)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(messages, forKey: .messages)
    }
}