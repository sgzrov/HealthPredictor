//
//  ChatView.swift
//  HealthPredictor
//
//  Created by Stephan  on 17.06.2025.
//

import SwiftUI

struct ChatView: View {

    @StateObject private var messageVM: MessageViewModel

    @ObservedObject var session: ChatSession

    init(session: ChatSession) {
        self.session = session
        self._messageVM = StateObject(wrappedValue: MessageViewModel(session: session))
    }

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
                isLoading: messageVM.isLoading,
                onSend: {
                    messageVM.sendMessage()
                }
            )
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ChatView(session: ChatSession(title: "Test Chat"))
}
