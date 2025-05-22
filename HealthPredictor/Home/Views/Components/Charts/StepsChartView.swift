//
//  StepsChartView.swift
//  HealthPredictor
//
//  Created by Stephan  on 01.05.2025.
//

import SwiftUI

struct StepsChartView: View {
    @ObservedObject var viewModel: HealthCardViewModel

    var body: some View {
        VStack {
            // Replace with actual steps visualization
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(hex: "#28242c"))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Text("Steps")
                            .foregroundColor(.white)
                        Text("Steps per day")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        Text("\(viewModel.card.value) \(viewModel.card.metric)")
                            .foregroundColor(.white)
                            .font(.title)
                    }
                )
        }
    }
}

#Preview {
    StepsChartView(viewModel: HealthCardViewModel(card: HealthCard.steps))
}
