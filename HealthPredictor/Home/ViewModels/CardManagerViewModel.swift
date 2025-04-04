import Foundation
import SwiftUI

class CardManagerViewModel: ObservableObject {
    @Published var userCards: [HealthCard]
    @Published var visibleStartIndex: Int = 0

    let allTemplates = CardTemplates.all

    var visibleCards: [HealthCard] {
        let end = min(visibleStartIndex + 3, userCards.count)
        return Array(userCards[visibleStartIndex..<end])
    }

    var minimizedCards: [HealthCard] {
        Array(userCards.enumerated().filter { !visibleRange.contains($0.offset) }.map { $0.element })
    }

    private var visibleRange: Range<Int> {
        visibleStartIndex..<min(visibleStartIndex + 3, userCards.count)
    }

    var availableCardTemplates: [HealthCard] {
        let usedTitles = Set(userCards.map { $0.title })
        return allTemplates.filter { !usedTitles.contains($0.title) }
    }

    init() {
        self.userCards = Array(allTemplates.prefix(3))
    }

    enum ScrollDirection {
        case up, down
    }

    var isAtTop: Bool {
        visibleStartIndex == 0
    }

    var isAtBottom: Bool {
        visibleStartIndex + 3 >= userCards.count
    }

    func handleScrollGesture(direction: ScrollDirection) {
        switch direction {
        case .up:
            guard !isAtTop else { return }
            visibleStartIndex -= 1
        case .down:
            guard !isAtBottom else { return }
            visibleStartIndex += 1
        }
    }

    func addCard(_ card: HealthCard) {
        let exists = userCards.contains(where: { $0.title == card.title })
        if !exists {
            userCards.append(card)
        }
    }
}
