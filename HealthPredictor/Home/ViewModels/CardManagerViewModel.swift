import Foundation
import SwiftUI

class CardManagerViewModel: ObservableObject {
    @Published var userCards: [HealthCard]
    @Published var visibleStartIndex: Int = 0
    @Published var hasAddedCards: Bool = false

    let allTemplates = CardTemplates.all

    var availableCardTemplates: [HealthCard] {
        let usedTitles = Set(userCards.map { $0.title })
        return allTemplates.filter { !usedTitles.contains($0.title) }
    }

    var shouldShowDock: Bool {
        hasAddedCards && !minimizedCards.isEmpty
    }

    var visibleCards: [HealthCard] {
        let end = min(visibleStartIndex + 3, userCards.count)
        return Array(userCards[visibleStartIndex..<end])
    }

    private var visibleRange: Range<Int> {
        visibleStartIndex..<min(visibleStartIndex + 3, userCards.count)
    }

    var minimizedCards: [HealthCard] {
        Array(userCards.enumerated().filter { !visibleRange.contains($0.offset) }.map { $0.element })
    }

    var cardsAbove: [HealthCard] {
        guard let firstVisible = visibleCards.first, let index = userCards.firstIndex(of: firstVisible) else { return [] }
        return Array(userCards.prefix(upTo: index))
    }

    var cardsBelow: [HealthCard] {
        guard let lastVisible = visibleCards.last, let index = userCards.firstIndex(of: lastVisible) else { return [] }
        return Array(userCards.suffix(from: index + 1))
    }

    init() {
        self.userCards = Array(allTemplates.prefix(3))
    }

    enum ScrollDirection {
        case upwardMovement
        case downwardMovement
    }

    var isAtTop: Bool {
        visibleStartIndex == 0
    }

    var isAtBottom: Bool {
        visibleStartIndex + 3 >= userCards.count
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
}
