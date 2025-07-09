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

    init(id: UUID = UUID(), content: String, sender: MessageSender, timestamp: Date = Date(), state: MessageState = .complete) {
        self.id = id
        self.content = content
        self.sender = sender
        self.timestamp = timestamp
        self.state = state
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.content == rhs.content &&
        lhs.sender == rhs.sender &&
        lhs.timestamp == rhs.timestamp &&
        lhs.state == rhs.state
    }
}
