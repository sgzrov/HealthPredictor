//
//  MainChatView.swift
//  HealthPredictor
//
//  Created by Stephan  on 09.07.2025.
//

import SwiftUI

struct MainChatView: View {

    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var chatHistoryVM: ChatHistoryViewModel

    @State private var navigateToChat: ChatSession?
    @State private var pendingNewChat = false

    let userToken: String

    init(userToken: String) {
        self.userToken = userToken
        _chatHistoryVM = StateObject(wrappedValue: ChatHistoryViewModel(userToken: userToken))
    }

    var borderColor: Color? {
        colorScheme == .dark ? Color.gray.opacity(0.4) : nil
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d'<<suffix>>' yyyy 'at' HH:mm"
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let suffix: String

        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }

        let dateString = formatter.string(from: date)
        return dateString.replacingOccurrences(of: "<<suffix>>", with: suffix)
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            NavigationStack {

                ScrollView {
                    if chatHistoryVM.chatSessions.isEmpty {
                        VStack {
                            Spacer(minLength: 120)
                            Text("Tap + to start a new conversation.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(chatHistoryVM.chatSessions) { session in
                                Button(action: {
                                    navigateToChat = session
                                }) {
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.clear, radius: 4, x: 0, y: 2)
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(session.title)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                                Text(formattedDate(session.createdAt))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            if let lastMessage = session.messages.last {
                                                Text(lastMessage.content)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            } else {
                                                Text("No messages yet")
                                                    .padding(.top, 2)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                    .italic()
                                            }
                                        }
                                        .padding(16)
                                    }
                                    .overlay(
                                        Group {
                                            if let borderColor = borderColor {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(borderColor, lineWidth: 1)
                                            }
                                        }
                                    )
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 12)
                        .padding(.horizontal, 16)
                    }
                }
                .background(Color.clear)
                .navigationTitle("Chats")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Edit") {
                            // Edit action
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            pendingNewChat = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(.secondarySystemFill))
                                    .frame(width: 30, height: 30)
                                Image(systemName: "plus")
                                    .resizable()
                                    .frame(width: 14, height: 14)
                                    .foregroundColor(Color(.systemGroupedBackground))
                            }
                        }
                    }
                }
                .navigationDestination(isPresented: $pendingNewChat) {
                    ChatView(userToken: userToken, newSessionHandler: { session in
                        chatHistoryVM.chatSessions.insert(session, at: 0)
                        navigateToChat = session
                        pendingNewChat = false
                    })
                }
                .navigationDestination(item: $navigateToChat) { session in
                    ChatView(session: session, userToken: userToken)
                }
            }
        }
    }
}

#Preview {
    MainChatView(userToken: "PREVIEW_TOKEN")
}
