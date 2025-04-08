import SwiftUI

class InsightCardViewModel: ObservableObject {
    let card: InsightCard

    init(card: InsightCard) {
        self.card = card
    }
}