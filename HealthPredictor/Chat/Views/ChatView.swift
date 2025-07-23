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

    let userToken: String

    init(session: ChatSession, userToken: String) {
        self.session = session
        self.userToken = userToken
        self._messageVM = StateObject(wrappedValue: MessageViewModel(session: session, userToken: userToken))
    }

    init(userToken: String, newSessionHandler: @escaping (ChatSession) -> Void) {
        let newSession = ChatSession()
        self.session = newSession
        self.userToken = userToken
        self._messageVM = StateObject(wrappedValue: MessageViewModel(session: newSession, userToken: userToken))
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
                    // Removed newSessionHandler call to prevent duplicate assistant responses and session insertions
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
        .onAppear {
            messageVM.refreshMessages()
        }
    }
}

#Preview {
    ChatView(session: ChatSession(title: "Test Chat"), userToken: "PREVIEW_TOKEN")
}
