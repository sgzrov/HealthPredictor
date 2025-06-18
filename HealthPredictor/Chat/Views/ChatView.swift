//
//  ChatView.swift
//  HealthPredictor
//
//  Created by Stephan  on 17.06.2025.
//

import SwiftUI

struct ChatView: View {

    @StateObject private var messageVM = MessageViewModel()

    var body: some View {
        VStack(spacing: 0) {

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messageVM.messages) { message in
                            MessageBubbleView(message: message)
                        }
                    }
                    .padding()
                }
                .onChange(of: messageVM.messages) { oldValue, newValue in
                    withAnimation {
                        proxy.scrollTo(newValue.last?.id, anchor: .bottom)
                    }
                }
            }

            ChatInputView(
                inputMessage: $messageVM.inputMessage,
                onSend: {
                    messageVM.sendMessage()
                }
            )
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ChatView()
}
