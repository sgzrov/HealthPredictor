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

    var body: some View {
        HStack {
            if isScrolling && cardViewModel.shouldShowDock {
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

            ScrollView(.vertical) {
                LazyVStack(spacing: 12) {
                    ForEach(cardViewModel.visibleCards) { card in
                        HealthCardView(card: card)
                    }
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                    }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if cardViewModel.hasAddedCards && !cardViewModel.isAtBoundary(for: value.translation.height) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    isScrolling = true
                                }
                            }
                        }
                        .onEnded { value in
                            if cardViewModel.hasAddedCards && !cardViewModel.isAtBoundary(for: value.translation.height) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    if value.translation.height > 25 {
                                        cardViewModel.handleScrollGesture(direction: .upwardMovement)
                                    } else if value.translation.height < -25 {
                                        cardViewModel.handleScrollGesture(direction: .downwardMovement)
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                            isScrolling = false
                                        }
                                    }
                                }
                            }
                        }
                )
            }
            .frame(height: 3 * 136)
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                if cardViewModel.hasAddedCards {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        isScrolling = abs(value - scrollOffset) > 1.5
                        scrollOffset = value
                    }
                }
            }
            .clipped()
            .padding(.leading, cardViewModel.hasAddedCards && isScrolling ? 8 : 0)
        }
        .padding(.horizontal, LayoutConstants.cardPadding)
    }
}

#Preview {
    CardScrollView(cardViewModel: CardManagerViewModel(), isScrolling: .constant(false), scrollOffset: .constant(0))
}
