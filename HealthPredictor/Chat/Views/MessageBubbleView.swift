//
//  MessageBubbleView.swift
//  HealthPredictor
//
//  Created by Stephan  on 18.06.2025.
//

import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
            }

            VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(message.sender == .user ? Color.accentColor : .gray.opacity(0.3))
                    .foregroundColor(message.sender == .user ? .white : .primary)
                    .cornerRadius(20)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if message.sender == .assistant {
                Spacer()
            }
        }
    }
}

#Preview {
    VStack {
        MessageBubbleView(message: ChatMessage(
            content: "Hello! How can I help you with your health today?",
            sender: .assistant
        ))
        MessageBubbleView(message: ChatMessage(
            content: "Tell me more about my heart rate!",
            sender: .user
        ))
    }
}

