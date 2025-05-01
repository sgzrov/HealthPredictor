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
    @State private var selectedRange: TimeRange = .day
    let cardIndex: Int

    // Time‐range selection for expanded chart
    enum TimeRange: String, CaseIterable, Identifiable {
      case day = "D", week = "W", month = "M", year = "Y"
      var id: String { rawValue }
    }

    init(card: HealthCard, cardIndex: Int, cardManagerViewModel: CardManagerViewModel, isScrolling: Binding<Bool>) {
        _healthCardViewModel = StateObject(wrappedValue: HealthCardViewModel(card: card))
        self.cardManagerViewModel = cardManagerViewModel
        self._isScrolling = isScrolling
        self.cardIndex = cardIndex
    }

    @ViewBuilder
    private func chartContent() -> some View {
        Group {
            switch healthCardViewModel.card.type {
            case .heartRate:
                HeartRateChartView(viewModel: healthCardViewModel)
            case .heartRateVariability:
                HeartRateVariabilityChartView(viewModel: healthCardViewModel)
            case .caloriesBurnt:
                CaloriesBurntChartView(viewModel: healthCardViewModel)
            case .steps:
                StepsChartView(viewModel: healthCardViewModel)
            case .standHours:
                StandHoursChartView(viewModel: healthCardViewModel)
            case .activeTime:
                ActiveTimeChartView(viewModel: healthCardViewModel)
            case .water:
                WaterIntakeChartView(viewModel: healthCardViewModel)
            case .sleepDurationQuality:
                SleepDurationQualityChartView(viewModel: healthCardViewModel)
            case .mindfulMinutes:
                MindfulMinutesChartView(viewModel: healthCardViewModel)
            }
        }
    }

    @ViewBuilder
    private func dividerLine() -> some View {
        Rectangle()
            .fill(Color.black.opacity(0.1))
            .frame(height: 1)
    }

    @ViewBuilder
    private func expandedSection() -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.Card.expandedSpacing(for: UIScreen.main.bounds.height)) {
            rangePicker()
            chartContent()
            Text(healthCardViewModel.card.summary)
                .font(.callout)
                .lineSpacing(2)
                .foregroundColor(healthCardViewModel.card.otherColor)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.tertiarySystemFill).opacity(0.3))
                )
                .padding(.top, 12)

            HStack(spacing: 8) {
                Image(systemName: "square.on.square")
                Image(systemName: "speaker.wave.2")
                Image(systemName: "hand.thumbsup")
                Image(systemName: "hand.thumbsdown")

                Spacer()

                Button(action: {
                    // Ask AI button opens chat with health card context
                }) {
                    HStack(spacing: 4) {
                        Text("Ask AI")
                            .font(.subheadline)
                        Image(systemName: "sparkles")
                    }
                    .foregroundColor(.white)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(
                    AnimatedMeshView()
                        .mask(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(lineWidth: 12)
                                .blur(radius: 4)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white, lineWidth: 3)
                                .blur(radius: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white, lineWidth: 1)
                                .blur(radius: 1)
                                .blendMode(.overlay)
                        )
                )
                .background(.black.opacity(0.1))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            }
            .imageScale(.small)
            .foregroundColor(healthCardViewModel.card.otherColor.opacity(0.3))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
    }

    @ViewBuilder
    private func rangePicker() -> some View {
        HStack(spacing: 4) {
            ForEach(TimeRange.allCases) { range in
                let isSelected = selectedRange == range
                Text(range.rawValue)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : healthCardViewModel.card.otherColor)
                    .frame(maxWidth: .infinity, minHeight: 32)
                    .background(
                        Capsule()
                            .fill(isSelected
                                  ? healthCardViewModel.card.otherColor
                                  : healthCardViewModel.card.otherColor.opacity(0.2))
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            selectedRange = range
                        }
                    }
            }
        }
        .padding(.horizontal, 16)
    }

    private var mainContent: some View {
        VStack {
            // First line (Card name + emoji + trend)
            HStack(alignment: .firstTextBaseline) {
                Text(healthCardViewModel.card.emoji)
                Text(healthCardViewModel.card.title)
                    .font(.system(.headline))
                    .foregroundColor(healthCardViewModel.card.otherColor)
                Spacer()
                Text(healthCardViewModel.trend)
                    .font(.system(.headline))
                    .foregroundColor(healthCardViewModel.card.otherColor)
            }

            // Second line (Fraction + percentage)
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 0) {
                    Text("\(healthCardViewModel.card.value)")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundColor(healthCardViewModel.card.otherColor)
                    Text("/")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundColor(healthCardViewModel.card.otherColor.opacity(0.2))
                        .offset(y: -0.7)
                    Text("\(healthCardViewModel.card.goal) \(healthCardViewModel.card.metric)")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundColor(healthCardViewModel.card.otherColor.opacity(0.2))
                }
                Spacer()
                Text("\(healthCardViewModel.percentage)%")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundColor(healthCardViewModel.card.otherColor)
            }
            .offset(y: 16)

            // Third line (Progress bar)
            HStack(spacing: 4) {
                ForEach(0..<6) { index in
                    Capsule()
                        .fill(index < healthCardViewModel.filledBars ? healthCardViewModel.card.otherColor : healthCardViewModel.card.otherColor.opacity(0.2))
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
        card: HealthCard.heartRate,
        cardIndex: 0,
        cardManagerViewModel: CardManagerViewModel(),
        isScrolling: .constant(false)
    )
}
