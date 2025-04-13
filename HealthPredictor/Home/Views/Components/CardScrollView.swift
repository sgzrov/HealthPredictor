//
//  CardScrollView.swift
//  HealthPredictor
//
//  Created by Stephan  on 08.04.2025.
//

import SwiftUI

struct CardScrollView: View {
    @ObservedObject var cardViewModel: CardManagerViewModel
    @Binding var isScrolling: Bool
    @Binding var scrollOffset: CGFloat
    @State private var cardPositions: [CardPosition] = []

    private var isExpanded: Bool {
        cardViewModel.expandedCardIndex != nil
    }

    var body: some View {
        HStack {
            if isScrolling && cardViewModel.shouldShowDock && !isExpanded {
                CardDockView(
                    cardsAbove: cardViewModel.cardsAbove,
                    cardsBelow: cardViewModel.cardsBelow
                )
                .frame(width: CardDockView.defaultWidth, height: cardViewModel.minimizedCards.isEmpty ? CardDockView.defaultHeight : CGFloat(cardViewModel.minimizedCards.count) * (CardDockView.iconHeight + CardDockView.iconSpacing) + CardDockView.verticalPadding * 2)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .move(edge: .leading)).combined(with: .opacity),
                    removal: .scale(scale: 0.8).combined(with: .move(edge: .leading)).combined(with: .opacity)
                ))
            }

            ScrollView(.vertical, showsIndicators: false) {
                GeometryReader { geometry in
                    LazyVStack(spacing: LayoutConstants.Card.spacing(for: UIScreen.main.bounds.height)) {
                        ForEach(Array(zip(cardViewModel.visibleCards.indices, cardViewModel.visibleCards)), id: \.1) { index, card in
                            HealthCardView(card: card, cardIndex: index, cardManagerViewModel: cardViewModel, isScrolling: $isScrolling)
                                .background(
                                    GeometryReader { cardGeometry in
                                        Color.clear.preference(
                                            key: CardPositionPreferenceKey.self,
                                            value: [CardPosition(
                                                id: card.title,
                                                frame: cardGeometry.frame(in: .named("scroll"))
                                            )]
                                        )
                                    }
                                )
                        }
                    }
                    .padding(.vertical, LayoutConstants.Card.spacing(for: UIScreen.main.bounds.height) / 2)
                    .background(
                        GeometryReader { scrollGeometry in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: scrollGeometry.frame(in: .named("scroll")).minY
                            )
                        }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isExpanded && cardViewModel.hasAddedCards && !cardViewModel.isAtBoundary(for: value.translation.height) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                        isScrolling = true
                                    }
                                }
                            }
                            .onEnded { value in
                                if !isExpanded && cardViewModel.hasAddedCards && !cardViewModel.isAtBoundary(for: value.translation.height) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                        if value.translation.height > 25 {
                                            cardViewModel.handleScrollGesture(direction: .upwardMovement)
                                        } else if value.translation.height < -25 {
                                            cardViewModel.handleScrollGesture(direction: .downwardMovement)
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                                isScrolling = false
                                            }
                                        }
                                    }
                                }
                            }
                    )
                }
            }
            .frame(height: (3 * LayoutConstants.Card.height(for: UIScreen.main.bounds.height)) +
                   (2 * LayoutConstants.Card.spacing(for: UIScreen.main.bounds.height)) +
                   (LayoutConstants.Card.spacing(for: UIScreen.main.bounds.height)))
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                if cardViewModel.hasAddedCards && !isExpanded {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        isScrolling = abs(value - scrollOffset) > 1.5
                        scrollOffset = value
                    }
                }
            }
            .onPreferenceChange(CardPositionPreferenceKey.self) { positions in
                cardPositions = positions
            }
            .clipped()
            .padding(.leading, cardViewModel.hasAddedCards && isScrolling && !isExpanded ? 8 : 0)
        }
        .padding(.horizontal, LayoutConstants.cardPadding)
    }
}

#Preview {
    CardScrollView(cardViewModel: CardManagerViewModel(), isScrolling: .constant(false), scrollOffset: .constant(0))
}
