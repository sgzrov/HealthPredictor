//
//  SummaryTriangleView.swift
//  HealthPredictor
//
//  Created by Stephan  on 24.04.2025.
//

import SwiftUI

struct SummaryView: View {
    @StateObject private var viewModel = BalanceViewModel()
    private let triangleWidth: CGFloat = 200
    private let triangleHeight: CGFloat = 200 * sqrt(3) / 2

    var body: some View {
        HStack(alignment: .top, spacing: 32) {
            TriangleView(metrics: viewModel.metrics, viewModel: viewModel)
                .frame(width: triangleWidth)

            LegendView(metrics: viewModel.metrics, legendHeight: .constant(triangleHeight))
                .frame(height: triangleHeight)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        )
    }
}

#Preview {
    SummaryView()
        .padding()
        .frame(maxWidth: 400)
        .preferredColorScheme(.dark)
}

