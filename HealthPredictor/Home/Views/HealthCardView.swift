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
    @State private var showInsightReactions = true
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

    private func insightView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .medium))
                Text("AI Summary")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white)

            AnimatedTextView(
                text: healthCardViewModel.card.summary,
                font: Font.system(size: 15, weight: .regular),
                textColor: Color.white.opacity(0.9)
            )

            if showInsightReactions {
                HStack(spacing: 8) {
                    ForEach(["square.on.square", "speaker.wave.2", "hand.thumbsup", "hand.thumbsdown"], id: \.self) { iconName in
                        Button(action: {
                            // Handle reaction
                        }) {
                            Image(systemName: iconName)
                                .font(.system(size: 13))
                                .fontWeight(.light)
                        }
                        .foregroundColor(.white.opacity(0.4))
                        .hoverEffect(.highlight)
                    }
                    
                    Spacer()
                    
                    Text("Ask a follow-up")
                        .font(.system(size: 13, weight: .medium))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.black)
                        )
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 10)
    }

    @ViewBuilder
    private func expandedSection() -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.expandedSpacing(for: UIScreen.main.bounds.height)) {
            rangePicker()
            chartContent()
            insightView()
        }
        .padding(20)
        .padding(.top, -4)
    }

    @ViewBuilder
    private func rangePicker() -> some View {
        HStack(spacing: 8) {
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
                                  : healthCardViewModel.card.otherColor.opacity(0.15))
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
    .preferredColorScheme(.dark)
}
