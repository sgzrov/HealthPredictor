//
//  MainChatView.swift
//  HealthPredictor
//
//  Created by Stephan  on 09.07.2025.
//

import SwiftUI

struct MainChatView: View {

    @StateObject private var chatHistoryVM = ChatHistoryViewModel()

    @State private var navigateToChat: ChatSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                if chatHistoryVM.chatSessions.isEmpty {
                    VStack {
                        Spacer(minLength: 80)
                        Text("Tap + to start a new conversation.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding(.top, 12)
                } else {
                    LazyVStack(spacing: 4) {
                        ForEach(chatHistoryVM.chatSessions) { session in
                            Button(action: {
                                navigateToChat = session
                            }) {
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(session.title)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Text(session.createdAt.chatCardString)
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
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Edit") {
                        // Edit action
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let newSession = chatHistoryVM.createNewChat()
                        navigateToChat = newSession
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
            .navigationDestination(item: $navigateToChat) { session in
                ChatView(session: session)
            }
        }
    }
}

extension Date {
    var chatCardString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm MMM d'<<suffix>>' yyyy"
        let calendar = Calendar.current
        let day = calendar.component(.day, from: self)
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        let dateString = formatter.string(from: self)
        return dateString.replacingOccurrences(of: "<<suffix>>", with: suffix)
    }
}

#Preview {
    MainChatView()
}
