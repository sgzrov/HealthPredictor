import Foundation
import SwiftUI

@MainActor
class BalanceViewModel: ObservableObject {
    @Published private(set) var metrics: [BalanceMetric] = []

    init() {
        loadSampleData()
    }

    struct TrianglePoints {
        let topPoint: CGPoint
        let bottomRightPoint: CGPoint
        let bottomLeftPoint: CGPoint

        var allPoints: [CGPoint] {
            [topPoint, bottomRightPoint, bottomLeftPoint]
        }
    }

    func calculateTrianglePoints(in rect: CGRect) -> TrianglePoints {
        let center = CGPoint(x: rect.width/2, y: rect.height/2)
        let radius = min(rect.width, rect.height) / 2

        let topPoint = CGPoint(x: center.x, y: center.y - radius)
        let bottomRightPoint = CGPoint(x: center.x + radius * cos(.pi / 6), y: center.y + radius * sin(.pi / 6))
        let bottomLeftPoint = CGPoint(x: center.x - radius * cos(.pi / 6), y: center.y + radius * sin(.pi / 6))

        return TrianglePoints(
            topPoint: topPoint,
            bottomRightPoint: bottomRightPoint,
            bottomLeftPoint: bottomLeftPoint
        )
    }

    private func midpoint(_ point1: CGPoint, _ point2: CGPoint) -> CGPoint {
        return CGPoint(x: (point1.x + point2.x) / 2, y: (point1.y + point2.y) / 2)
    }

    func adjustedMidpoint(_ start: CGPoint, _ end: CGPoint, _ center: CGPoint, percentage: Double) -> CGPoint {
        let mid = midpoint(start, end)
        let vectorToCenter = CGPoint(x: center.x - mid.x, y: center.y - mid.y)
        let movementFactor = 1.0 - percentage
        
        return CGPoint(x: mid.x + vectorToCenter.x * movementFactor, y: mid.y + vectorToCenter.y * movementFactor)
    }

    private func loadSampleData() {
        metrics = [
            BalanceMetric(
                name: "Activity",
                averagePercentage: 0.6,
                value: "45 min",
                type: .activity
            ),
            BalanceMetric(
                name: "Recovery",
                averagePercentage: 1.0,
                value: "7 h",
                type: .recovery
            ),
            BalanceMetric(
                name: "Balance",
                averagePercentage: 1.0,
                value: "82%",
                type: .balance
            )
        ]
    }

    // Future methods for:
    // - Loading real data
    // - Calculating percentages
    // - Updating metrics
    // - Handling overachievement
}
