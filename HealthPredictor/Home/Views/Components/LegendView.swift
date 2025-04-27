//
//  LegendView.swift
//  HealthPredictor
//
//  Created by Stephan  on 26.04.2025.
//

import SwiftUI

struct LegendView: View {
    let metrics: [BalanceMetric]
    @Binding var legendHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(metrics) { metric in
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(metric.name)
                            .font(.body)
                            .fontWeight(.medium)
                        Text(metric.value)
                            .font(.title3)
                            .fontWeight(.light)
                            .foregroundColor(metric.type.color)
                    }
                }
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { legendHeight = geo.size.height }
                    .onChange(of: geo.size.height) { _, newValue in legendHeight = newValue }
            }
        )
    }
}

#Preview {
    LegendView(metrics: [
        BalanceMetric(name: "Activity", averagePercentage: 0.6, value: "45 min", type: .activity),
        BalanceMetric(name: "Recovery", averagePercentage: 1.0, value: "7 h", type: .recovery),
        BalanceMetric(name: "Balance", averagePercentage: 1.0, value: "82%", type: .balance)
    ], legendHeight: .constant(0))
}
