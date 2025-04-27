//
//  TriangleView.swift
//  HealthPredictor
//

import SwiftUI

struct TriangleView: View {
    let metrics: [BalanceMetric]
    let viewModel: BalanceViewModel
    let lineWidth: CGFloat = 12

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let triangleHeight = width * sqrt(3) / 2
            let yOffset = (geometry.size.height - triangleHeight) / 2
            let inset = lineWidth / 2
            // Inset triangle points
            let topPoint = CGPoint(x: width / 2, y: yOffset + inset)
            let bottomLeftPoint = CGPoint(x: inset, y: triangleHeight + yOffset - inset)
            let bottomRightPoint = CGPoint(x: width - inset, y: triangleHeight + yOffset - inset)
            let points = [topPoint, bottomRightPoint, bottomLeftPoint]
            // Centroid of the triangle
            let center = CGPoint(x: width / 2, y: (triangleHeight / 3) + yOffset)

            ZStack {
                // Background track (continuous triangle)
                Path { path in
                    path.move(to: topPoint)
                    path.addLine(to: bottomRightPoint)
                    path.addLine(to: bottomLeftPoint)
                    path.closeSubpath()
                }
                .stroke(
                    Color(.tertiarySystemFill),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

                // Draw lines with Apple-style gradients
                ForEach(Array(metrics.enumerated()), id: \.element.id) { idx, metric in
                    let start = points[idx]
                    let end = points[(idx + 1) % 3]
                    let percentage = metric.averagePercentage
                    let color = metric.type.color

                    if percentage >= 1.0 {
                        // Straight line with full gradient
                        Path { path in
                            path.move(to: start)
                            path.addLine(to: end)
                        }
                        .stroke(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.7),
                                    color.opacity(0.9),
                                    color.opacity(0.9),
                                    color.opacity(0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(
                                lineWidth: lineWidth,
                                lineCap: .round
                            )
                        )
                    } else {
                        // Calculate the dented midpoint for the new triangle
                        let mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
                        let vectorToCenter = CGPoint(x: center.x - mid.x, y: center.y - mid.y)
                        let movementFactor = 1.0 - percentage
                        let dentedMid = CGPoint(x: mid.x + vectorToCenter.x * movementFactor, y: mid.y + vectorToCenter.y * movementFactor)

                        // First half
                        Path { path in
                            path.move(to: start)
                            path.addLine(to: dentedMid)
                        }
                        .stroke(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.7),
                                    color.opacity(0.9),
                                    color.opacity(0.9),
                                    color.opacity(0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(
                                lineWidth: lineWidth,
                                lineCap: .round
                            )
                        )

                        // Second half
                        Path { path in
                            path.move(to: dentedMid)
                            path.addLine(to: end)
                        }
                        .stroke(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.7),
                                    color.opacity(0.9),
                                    color.opacity(0.9),
                                    color.opacity(0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(
                                lineWidth: lineWidth,
                                lineCap: .round
                            )
                        )
                    }
                }
            }
        }
        .aspectRatio(1/(sqrt(3)/2), contentMode: .fit)
    }
}

#Preview {
    let sampleMetrics = [
        BalanceMetric(name: "Activity", averagePercentage: 0.6, value: "45 min", type: .activity),
        BalanceMetric(name: "Recovery", averagePercentage: 1.0, value: "7 h", type: .recovery),
        BalanceMetric(name: "Balance", averagePercentage: 1.0, value: "82%", type: .balance)
    ]
    return TriangleView(
        metrics: sampleMetrics,
        viewModel: BalanceViewModel()
    )
    .frame(width: 200)
    .preferredColorScheme(.dark)
}
