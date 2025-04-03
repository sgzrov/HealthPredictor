//
//  CardManagerViewModel.swift
//  HealthPredictor
//
//  Created by Stephan  on 02.04.2025.
// This view model holds all card logic, splits visible vs minimized.

import Foundation
import SwiftUI

class CardManagerViewModel: ObservableObject {
    @Published var visibleCards: [HealthCard]
    @Published var minimizedCards: [HealthCard]

    init() {
        self.visibleCards = [
            CardTemplates.heartRate,
            CardTemplates.activeTime,
            CardTemplates.calories
        ]
        self.minimizedCards = []
    }

    enum ScrollDirection {
        case up, down
    }

    func handleScrollGesture(direction: ScrollDirection) {
        switch direction {
            
        case .down:
            guard minimizedCards.count > 0 else { return }
            
            let bottomCard = visibleCards.removeLast()
            minimizedCards.insert(bottomCard, at: 0)
            
            let previousCard = minimizedCards.removeLast()
            visibleCards.insert(previousCard, at: 0)
            
        case .up:
            guard minimizedCards.count > 0 else { return }
            
            let topCard = visibleCards.removeFirst()
            minimizedCards.append(topCard)
            
            let nextCard = minimizedCards.removeFirst()
            visibleCards.append(nextCard)
        }
    }

    func addCard(_ card: HealthCard) {
        let exists = visibleCards.contains(where: { $0.title == card.title }) ||
                     minimizedCards.contains(where: { $0.title == card.title })

        if !exists {
            minimizedCards.append(card)
        }
    }
}
