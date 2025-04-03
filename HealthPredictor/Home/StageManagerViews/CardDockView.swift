//
//  MinimizedCardDockView.swift
//  HealthPredictor
//
//  Created by Stephan  on 02.04.2025.
// This view holds scrollable vertical capsule holding icons.

import SwiftUI

struct MinimizedCardDockView: View {
    let icons: [String]

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                if icons.isEmpty {
                    Spacer().frame(height: 20)
                } else {
                    ForEach(icons, id: \.self) { emoji in
                        MinimizedCardIconView(emoji: emoji)
                    }
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 30)
            )
        }
    }
}

#Preview {
    MinimizedCardDockView(icons: ["❤️", "⏰", "🔥", "😴", "💧", "🧠"])
}
