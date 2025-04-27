import Foundation
import SwiftUI

struct BalanceMetric: Identifiable {
    let id = UUID()
    let name: String
    let averagePercentage: Double
    let value: String
    let type: MetricType
}

enum MetricType {
    case activity
    case recovery
    case balance

    var color: Color {
        switch self {
        case .activity:
            return Color(.systemRed)
        case .recovery:
            return Color(.systemGreen)
        case .balance:
            return Color(.systemBlue)
        }
    }
}
