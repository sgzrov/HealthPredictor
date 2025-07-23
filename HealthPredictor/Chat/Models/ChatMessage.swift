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
    let sender: MessageSender
    let timestamp: Date
    var state: MessageState

    enum CodingKeys: String, CodingKey {
        case id, content, sender, timestamp, state
        case role // for backend compatibility
    }

    init(id: UUID = UUID(), content: String, sender: MessageSender, timestamp: Date = Date(), state: MessageState = .complete) {
        self.id = id
        self.content = content
        self.sender = sender
        self.timestamp = timestamp
        self.state = state
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.content = try container.decode(String.self, forKey: .content)
        if let sender = try? container.decode(MessageSender.self, forKey: .sender) {
            self.sender = sender
        } else if let role = try? container.decode(String.self, forKey: .role) {
            self.sender = MessageSender(rawValue: role) ?? .assistant
        } else {
            self.sender = .assistant
        }
        self.timestamp = (try? container.decode(Date.self, forKey: .timestamp)) ?? Date()
        self.state = (try? container.decode(MessageState.self, forKey: .state)) ?? .complete
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(sender, forKey: .sender)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(state, forKey: .state)
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.content == rhs.content &&
        lhs.sender == rhs.sender &&
        lhs.timestamp == rhs.timestamp &&
        lhs.state == rhs.state
    }
}
