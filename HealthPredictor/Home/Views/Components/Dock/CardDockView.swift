//
//  MinimizedCardDockView.swift
//  HealthPredictor
//
//  Created by Stephan on 02.04.2025.
//  This view holds a vertical capsule holding icons split by a divider if needed.

import SwiftUI

struct CardDockView: View {
    let cardsAbove: [HealthCard]
    let cardsBelow: [HealthCard]

    static let defaultWidth: CGFloat = 18 + 2 * 5
    static let iconHeight: CGFloat = 18
    static let iconSpacing: CGFloat = 8
    static let verticalPadding: CGFloat = 8
    static let defaultHeight: CGFloat = iconHeight

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))

            VStack(spacing: Self.iconSpacing) {
                if cardsAbove.isEmpty && cardsBelow.isEmpty {
                    Spacer().frame(height: Self.defaultHeight)
                } else {
                    ForEach(cardsAbove, id: \.id) { card in
                        CardIconView(emoji: card.emoji)
                    }

                    if !cardsAbove.isEmpty && !cardsBelow.isEmpty {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 15, height: 2)
                    }

                    ForEach(cardsBelow, id: \.id) { card in
                        CardIconView(emoji: card.emoji)
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
    CardDockView(
        cardsAbove: [
            HealthCard(title: "Heart Rate", emoji: "❤️", value: 65, goal: 80, metric: "bpm", cardColor: .red, otherColor: .white, summary: "placeholder", type: HealthCardType.heartRate),
            HealthCard(title: "Active Time", emoji: "⏰", value: 30, goal: 60, metric: "minutes", cardColor: .gray, otherColor: .white, summary: "placeholder", type: HealthCardType.activeTime)
        ],
        cardsBelow: [
            HealthCard(title: "Calories", emoji: "🔥", value: 600, goal: 1000, metric: "kcal", cardColor: .orange, otherColor: .white, summary: "placeholder", type: HealthCardType.caloriesBurnt),
            HealthCard(title: "Sleep", emoji: "😴", value: 6, goal: 8, metric: "hours", cardColor: .purple, otherColor: .white, summary: "placeholder", type: HealthCardType.sleepDurationQuality),
            HealthCard(title: "Water", emoji: "💧", value: 2, goal: 3, metric: "liters", cardColor: .blue, otherColor: .white, summary: "placeholder", type: HealthCardType.water),
            HealthCard(title: "Mind", emoji: "🧠", value: 5, goal: 10, metric: "sessions", cardColor: .pink, otherColor: .white, summary: "placeholder", type: HealthCardType.mindfulMinutes)
        ]
    )
}
