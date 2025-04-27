//
//  SummaryTriangleView.swift
//  HealthPredictor
//
//  Created by Stephan  on 24.04.2025.
//

import SwiftUI

struct SummaryView: View {
    @StateObject private var viewModel = BalanceViewModel()
    private let triangleWidth: CGFloat = 170
    private let triangleHeight: CGFloat = 170 * sqrt(3) / 2

    var body: some View {
        VStack(spacing: 0){
            Text("Activity Triangle")
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 24)
            Divider()
            HStack(spacing: 24) {
                TriangleView(metrics: viewModel.metrics, viewModel: viewModel)
                    .frame(width: triangleWidth)

                LegendView(metrics: viewModel.metrics, legendHeight: .constant(triangleHeight))
                    .frame(height: triangleHeight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)
            .padding(.leading, 24)
        }
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
