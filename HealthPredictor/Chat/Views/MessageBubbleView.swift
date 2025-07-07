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
                HStack(alignment: .top, spacing: 8) {
                    Text(message.content.isEmpty && message.state == .streaming ? "Thinking..." : message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(backgroundColor)
                        .foregroundColor(foregroundColor)
                        .cornerRadius(20)

                }

                HStack(spacing: 4) {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if message.state == .streaming {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .opacity(0.7)
                    }
                }
            }

            if message.sender == .assistant {
                Spacer()
            }
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        ))
    }

    private var backgroundColor: Color {
        switch message.state {
        case .complete:
            return message.sender == .user ? Color.accentColor : .gray.opacity(0.3)
        case .streaming:
            return message.sender == .user ? Color.accentColor : .gray.opacity(0.2)
        case .error:
            return message.sender == .user ? Color.accentColor : .red.opacity(0.1)
        }
    }

        private var foregroundColor: Color {
        switch message.state {
        case .complete:
            return message.sender == .user ? .white : .primary
        case .streaming:
            return message.sender == .user ? .white : .secondary
        case .error:
            return message.sender == .user ? .white : .red
        }
    }
}

#Preview {
    VStack {
        MessageBubbleView(message: ChatMessage(
            content: "Hello! How can I help you with your health today?",
            sender: .assistant,
            state: .complete
        ))
        MessageBubbleView(message: ChatMessage(
            content: "Tell me more about my heart rate!",
            sender: .user,
            state: .complete
        ))
        MessageBubbleView(message: ChatMessage(
            content: "I'm analyzing your health data...",
            sender: .assistant,
            state: .streaming
        ))
        MessageBubbleView(message: ChatMessage(
            content: "Sorry, I encountered an error processing your request.",
            sender: .assistant,
            state: .error
        ))
    }
}

