import Foundation
import SwiftUI

class HealthCardViewModel: ObservableObject {
    let card: HealthCard
    @Published var isExpanded: Bool = false
    @Published var selectedTimeRange: TimeRange = .today

    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "7 days"
        case month = "30 days"
        case year = "1 year"
    }

    var percentage: Int {
        guard card.goal != 0 else { return 0 }
        return min(100, (card.value * 100) / card.goal)
    }

    var filledBars: Int {
        return min(6, (percentage * 6) / 100)
    }

    var trend: String {
        // This would eventually come from real data analysis
        return "4% lower"
    }

    func updateTimeRange(_ range: TimeRange) {
        selectedTimeRange = range
        // Here you would fetch new data for the selected time range
        objectWillChange.send()
    }

    // Chart data computation could go here
    var chartData: [Double] {
        // This would eventually return real data based on selectedTimeRange
        return [/* sample data */]
    }

    init(card: HealthCard) {
        self.card = card
    }
}
