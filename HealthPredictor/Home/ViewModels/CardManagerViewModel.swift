import Foundation
import SwiftUI

class CardManagerViewModel: ObservableObject {
    @Published var userCards: [HealthCard]
    @Published var visibleStartIndex: Int = 0
    @Published var hasAddedCards: Bool = false
    @Published var expandedCardIndex: Int?
    @Published var originalExpandedCardIndex: Int?
    @Published var cardOffsets: [Int: CGFloat] = [:]

    let allTemplates = CardTemplates.all
    private let maxVisibleCards = 3

    var availableCardTemplates: [HealthCard] {
        let usedTitles = Set(userCards.map { $0.title })
        return allTemplates.filter { !usedTitles.contains($0.title) }
    }

    var shouldShowDock: Bool {
        hasAddedCards && !minimizedCards.isEmpty
    }

    var visibleCards: [HealthCard] {
        let end = min(visibleStartIndex + maxVisibleCards, userCards.count)
        return Array(userCards[visibleStartIndex..<end])
    }

    private var visibleRange: Range<Int> {
        visibleStartIndex..<min(visibleStartIndex + maxVisibleCards, userCards.count)
    }

    var minimizedCards: [HealthCard] {
        Array(userCards.enumerated().filter { !visibleRange.contains($0.offset) }.map { $0.element })
    }

    var cardsAbove: [HealthCard] {
        guard let firstVisible = visibleCards.first,
              let index = userCards.firstIndex(of: firstVisible) else { return [] }
        return Array(userCards.prefix(upTo: index))
    }

    var cardsBelow: [HealthCard] {
        guard let lastVisible = visibleCards.last,
              let index = userCards.firstIndex(of: lastVisible) else { return [] }
        return Array(userCards.suffix(from: index + 1))
    }

    init() {
        self.userCards = Array(allTemplates.prefix(maxVisibleCards))
    }

    enum ScrollDirection {
        case upwardMovement
        case downwardMovement
    }

    var isAtTop: Bool {
        visibleStartIndex == 0
    }

    var isAtBottom: Bool {
        visibleStartIndex + maxVisibleCards >= userCards.count
    }

    func handleScrollGesture(direction: ScrollDirection) {
        switch direction {
        case .upwardMovement:
            guard !isAtTop else { return }
            visibleStartIndex -= 1
        case .downwardMovement:
            guard !isAtBottom else { return }
            visibleStartIndex += 1
        }
    }

    func addCard(_ card: HealthCard) {
        let exists = userCards.contains(where: { $0.title == card.title })
        if !exists {
            userCards.append(card)
            hasAddedCards = true
        }
    }

    func isAtBoundary(for translation: CGFloat) -> Bool {
        (translation > 0 && isAtTop) || (translation < 0 && isAtBottom)
    }

    func handleCardExpansion(cardIndex: Int) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
            if expandedCardIndex == cardIndex {
                expandedCardIndex = nil
                originalExpandedCardIndex = nil
                cardOffsets.removeAll()
            } else {
                originalExpandedCardIndex = cardIndex
                expandedCardIndex = cardIndex

                let cardHeight = LayoutConstants.Card.height(for: UIScreen.main.bounds.height)
                let cardSpacing = LayoutConstants.Card.spacing(for: UIScreen.main.bounds.height)

                for visibleIndex in 0..<maxVisibleCards {
                    if visibleIndex < cardIndex {
                        cardOffsets[visibleIndex] = -cardHeight
                    } else if visibleIndex == cardIndex {
                        let currentPosition = CGFloat(visibleIndex) * (cardHeight + cardSpacing)
                        cardOffsets[visibleIndex] = -currentPosition
                    } else {
                        cardOffsets[visibleIndex] = cardHeight
                    }
                }
            }
        }
    }

    func offsetForCard(at index: Int) -> CGFloat {
        cardOffsets[index] ?? 0
    }
}

