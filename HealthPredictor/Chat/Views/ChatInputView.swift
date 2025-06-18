//
//  ChatInputView.swift
//  HealthPredictor
//
//  Created by Stephan  on 18.06.2025.
//

import SwiftUI

struct ChatInputView: View {

    @Binding var inputMessage: String

    @FocusState private var isInputFocused: Bool

    let onSend: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                TextField("Ask about your health...", text: $inputMessage, axis: .vertical)
                    .focused($isInputFocused)
                    .lineLimit(1...5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(20)

                Button(action: {
                    onSend()
                    isInputFocused = false
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.accentColor)
                }
                .disabled(inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
    }
}

#Preview {
    ChatInputView(
        inputMessage: .constant(""),
        onSend: {}
    )
}
