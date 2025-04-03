//
//  MinimizedCardDockView.swift
//  HealthPredictor
//
//  Created by Stephan  on 02.04.2025.
// This view holds scrollable vertical capsule holding icons.

import SwiftUI

struct CardDockView: View {
    let icons: [String]
    static let defaultWidth: CGFloat = 18 +  2 * 5
    static let iconHeight: CGFloat = 18
    static let iconSpacing: CGFloat = 8
    static let verticalPadding: CGFloat = 8
    static let defaultHeight: CGFloat = iconHeight
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))

            VStack(spacing: 8) {
                if icons.isEmpty {
                    Spacer().frame(height: Self.defaultHeight)
                } else {
                    ForEach(icons, id: \.self) { emoji in
                        CardIconView(emoji: emoji)
                    }
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 8)
        }
        .frame(width: Self.defaultWidth, height: Self.defaultHeight)
    }
}

#Preview {
    CardDockView(icons: ["❤️", "⏰", "🔥", "😴", "💧", "🧠"])
}
