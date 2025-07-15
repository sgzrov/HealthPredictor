//
//  ChatView.swift
//  HealthPredictor
//
//  Created by Stephan  on 17.06.2025.
//

import SwiftUI

struct ChatView: View {

    @ObservedObject var session: ChatSession

    @StateObject private var messageVM: MessageViewModel

    @State private var hasSentFirstMessage = false

    var newSessionHandler: ((ChatSession) -> Void)?

    init(session: ChatSession) {
        self.session = session
        self._messageVM = StateObject(wrappedValue: MessageViewModel(session: session))
    }

    init(newSessionHandler: @escaping (ChatSession) -> Void) {
        let newSession = ChatSession()
        self.session = newSession
        self._messageVM = StateObject(wrappedValue: MessageViewModel(session: newSession))
        self.newSessionHandler = newSessionHandler
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

                    if !hasSentFirstMessage && oldValue.isEmpty && !newValue.isEmpty {
                        hasSentFirstMessage = true
                        newSessionHandler?(session)
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
