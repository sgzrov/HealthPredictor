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
    @State private var currentIndex: Int?

    private var isExpanded: Bool {
        cardViewModel.expandedCardIndex != nil
    }

    var body: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(Array(cardViewModel.userCards.enumerated()), id: \.element.id) { index, card in
                        HealthCardView(
                            card: card,
                            cardIndex: index,
                            cardManagerViewModel: cardViewModel,
                            isScrolling: $isScrolling
                        )
                        .frame(width: UIScreen.main.bounds.width)
                        .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $currentIndex)
            .onChange(of: currentIndex) { oldValue, newValue in
                withAnimation {
                    isScrolling = true
                }
                // Reset scrolling state after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        isScrolling = false
                    }
                }
            }
        }
    }
}

#Preview {
    CardScrollView(
        cardViewModel: CardManagerViewModel(),
        isScrolling: .constant(false),
        scrollOffset: .constant(0)
    )
}
