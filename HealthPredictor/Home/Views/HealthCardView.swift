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
    @Binding var isScrolling: Bool
    let cardIndex: Int

    init(card: HealthCard, cardIndex: Int, cardManagerViewModel: CardManagerViewModel, isScrolling: Binding<Bool>) {
        _healthCardViewModel = StateObject(wrappedValue: HealthCardViewModel(card: card))
        self.cardManagerViewModel = cardManagerViewModel
        self._isScrolling = isScrolling
        self.cardIndex = cardIndex
    }

    @ViewBuilder
    private func chartContent() -> some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(Color(hex: "#28242c"))
            .frame(height: LayoutConstants.Card.expandedChartHeight(for: UIScreen.main.bounds.height))
            .overlay(
                Text("Chart coming soon")
                    .foregroundColor(.white)
            )
    }

    @ViewBuilder
    private func dividerLine() -> some View {
        Rectangle()
            .fill(healthCardViewModel.card.otherColor.opacity(0.1))
            .frame(height: 1)
    }

    @ViewBuilder
    private func expandedHeader() -> some View {
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
    }

    @ViewBuilder
    private func expandedSection() -> some View {
        VStack(spacing: LayoutConstants.Card.expandedSpacing(for: UIScreen.main.bounds.height)) {
            expandedHeader()
            chartContent()
        }
        .padding(20)
    }

    private var mainContent: some View {
        VStack {

            // First line (Card name + emoji + trend)
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

            // Second line (Fraction + percentage)
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 0) {
                    Text("\(healthCardViewModel.card.value)")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(healthCardViewModel.card.otherColor)
                    Text("/")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(Color(hex: "#505048"))
                        .offset(y: -0.7)
                    Text("\(healthCardViewModel.card.goal) \(healthCardViewModel.card.metric)")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(Color(hex: "#505048"))
                }
                Spacer()
                Text("\(healthCardViewModel.percentage)%")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(healthCardViewModel.card.otherColor)
            }
            .offset(y: 16)

            // Third line (Progress bar)
            HStack(spacing: 4) {
                ForEach(0..<6) { index in
                    Capsule()
                        .fill(index < healthCardViewModel.filledBars ? healthCardViewModel.card.otherColor : Color(hex: "#505048").opacity(0.2))
                        .frame(height: 6)
                }
            }
        }
        .padding(20)
    }

    var body: some View {
        VStack(spacing: 0) {
            mainContent

            if healthCardViewModel.isExpanded {
                dividerLine()
                expandedSection()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(healthCardViewModel.card.cardColor)
        )
        .offset(y: cardManagerViewModel.offsetForCard(at: cardIndex))
        .opacity(shouldBeVisible ? 1 : 0)
        .scaleEffect(shouldBeVisible ? 1 : 0.8)
        .onTapGesture {
            if !isScrolling {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.95)) {
                    healthCardViewModel.isExpanded.toggle()
                    cardManagerViewModel.handleCardExpansion(cardIndex: cardIndex)
                }
            }
        }
    }

    private var shouldBeVisible: Bool {
        cardManagerViewModel.expandedCardIndex == nil || cardManagerViewModel.expandedCardIndex == cardIndex
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
        cardIndex: 0,
        cardManagerViewModel: CardManagerViewModel(),
        isScrolling: .constant(false)
    )
}
