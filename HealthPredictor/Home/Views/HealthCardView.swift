//
//  HealthCardView.swift
//  HealthPredictor
//
//  Created by Stephan  on 29.03.2025.
//

import SwiftUI

struct HealthCardView: View {
    @StateObject var healthCardViewModel: HealthCardViewModel
    @ObservedObject var cardManagerViewModel: CardManagerViewModel

    init(card: HealthCard, cardManagerViewModel: CardManagerViewModel) {
        _healthCardViewModel = StateObject(wrappedValue: HealthCardViewModel(card: card))
        self.cardManagerViewModel = cardManagerViewModel
    }

    var body: some View {
        VStack {
            HStack(alignment: .firstTextBaseline) {
                Text(healthCardViewModel.card.emoji)
                Text(healthCardViewModel.card.title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(healthCardViewModel.card.otherColor)
                Spacer()
                Text(healthCardViewModel.trend)
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

            if healthCardViewModel.isExpanded {
                VStack(spacing: 50) {
                    HStack {
                        Text("Your heartbeat")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(healthCardViewModel.card.otherColor)
                        Spacer()
                        Menu {
                            ForEach(HealthCardViewModel.TimeRange.allCases, id: \.self) { range in
                                Button(range.rawValue) {
                                    healthCardViewModel.updateTimeRange(range)
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.rectangle")
                                .padding(4)
                                .foregroundColor(Color(hex: "#505048"))
                        }
                    }

                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color(hex: "#28242c"))
                        .frame(height: 200)
                        .overlay(
                            Text("Chart coming soon")
                                .foregroundColor(.white)
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(healthCardViewModel.card.cardColor)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                healthCardViewModel.isExpanded.toggle()
            }
        }
    }
}

#Preview {
    HealthCardView(
        card: HealthCard(
            title: "Heart rate",
            emoji: "❤️",
            value: 65,
            goal: 82,
            metric: "bpm",
            cardColor: Color(hex: "#f0fc4c"),
            otherColor: Color(hex: "#0c0804")
        ),
        cardManagerViewModel: CardManagerViewModel()
    )
}
