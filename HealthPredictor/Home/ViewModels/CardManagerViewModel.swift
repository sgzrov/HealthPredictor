import Foundation
import SwiftUI

class CardManagerViewModel: ObservableObject {
    @Published var userCards: [HealthCard]
    @Published var hasAddedCards: Bool = false
    @Published var expandedCardIndex: Int?
    @Published var originalExpandedCardIndex: Int?
    @Published var cardOffsets: [Int: CGFloat] = [:]

    let allTemplates = HealthCard.all

    var availableCardTemplates: [HealthCard] {
        let usedTitles = Set(userCards.map { $0.title })
        return allTemplates.filter { !usedTitles.contains($0.title) }
    }

    init() {
        // Start with heart rate card by default
        self.userCards = [HealthCard.heartRate]
    }

    func addCard(_ card: HealthCard) {
        let exists = userCards.contains(where: { $0.title == card.title })
        if !exists {
            userCards.append(card)
            hasAddedCards = true
        }
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
                
                cardOffsets[cardIndex] = 0
            }
        }
    }

    func offsetForCard(at index: Int) -> CGFloat {
        cardOffsets[index] ?? 0
    }
}

