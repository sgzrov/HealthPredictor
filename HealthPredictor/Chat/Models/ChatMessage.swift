//
//  ChatMessage.swift
//  HealthPredictor
//
//  Created by Stephan  on 18.06.2025.
//

import Foundation

enum MessageSender: String, Codable, Equatable {
    case user
    case assistant
}

enum MessageState: String, Codable, Equatable {
    case complete
    case streaming
    case error
}

struct ChatMessage: Identifiable, Equatable, Codable {
    var id: UUID
    var content: String
    var state: MessageState
    let role: MessageSender
    let timestamp: Date

    init(id: UUID = UUID(), content: String, role: MessageSender, timestamp: Date = Date(), state: MessageState = .complete) {
        self.id = id
        self.content = content
        self.state = state
        self.role = role
        self.timestamp = timestamp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.content = try container.decode(String.self, forKey: .content)
        self.state = (try? container.decode(MessageState.self, forKey: .state)) ?? .complete
        self.role = (try? container.decode(MessageSender.self, forKey: .role)) ?? .assistant
        self.timestamp = (try? container.decode(Date.self, forKey: .timestamp)) ?? Date()
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.content == rhs.content &&
        lhs.role == rhs.role &&
        lhs.timestamp == rhs.timestamp &&
        lhs.state == rhs.state
    }
}
