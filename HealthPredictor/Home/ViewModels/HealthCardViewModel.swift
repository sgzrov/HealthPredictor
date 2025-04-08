import SwiftUI

class HealthCardViewModel: ObservableObject {
    let card: HealthCard

    var percentage: Int {
        guard card.goal != 0 else { return 0 }
        return min(100, (card.value * 100) / card.goal)
    }

    var filledBars: Int {
        return min(6, (percentage * 6) / 100)
    }

    init(card: HealthCard) {
        self.card = card
    }
}