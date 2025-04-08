//
//  HealthCardView.swift
//  HealthPredictor
//
//  Created by Stephan  on 29.03.2025.
//

import SwiftUI

struct HealthCardView: View {
    @StateObject var healthCardViewModel: HealthCardViewModel

    init(card: HealthCard) {
        _healthCardViewModel = StateObject(wrappedValue: HealthCardViewModel(card: card))
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(healthCardViewModel.card.emoji)
                Text(healthCardViewModel.card.title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(healthCardViewModel.card.otherColor)
                Spacer()
                Text("4% lower")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(healthCardViewModel.card.otherColor)
            }
            .padding(.top, 3)

            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 0) {
                    Text("\(healthCardViewModel.card.value)")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(healthCardViewModel.card.otherColor)
                    Text("/")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(Color(hex: "#505048"))
                    Text("\(healthCardViewModel.card.goal) \(healthCardViewModel.card.metric)")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(Color(hex: "#505048"))
                }
                Spacer()
                Text("\(healthCardViewModel.percentage)%")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(healthCardViewModel.card.otherColor)
            }
            .offset(y: 5)

            HStack(spacing: 4) {
                ForEach(0..<6) { index in
                    Capsule()
                        .fill(index < healthCardViewModel.filledBars ? healthCardViewModel.card.otherColor : Color(hex: "#505048").opacity(0.2))
                        .frame(height: 6)
                }
            }
            .offset(y: -3)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(healthCardViewModel.card.cardColor)
        )
    }
}

#Preview {
    HealthCardView(card: HealthCard(title: "Heart rate", emoji: "❤️", value: 65, goal: 82, metric: "bpm", cardColor: Color(hex: "#f0fc4c"), otherColor: Color(hex: "#0c0804")))
}
