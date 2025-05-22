//
//  HeartRateVariabilityChartView.swift
//  HealthPredictor
//
//  Created by Stephan  on 01.05.2025.
//

import SwiftUI

struct HeartRateVariabilityChartView: View {
    @ObservedObject var viewModel: HealthCardViewModel

    var body: some View {
        VStack {
            // Replace with actual HRV visualization
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(hex: "#28242c"))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Text("Heart Rate Variability")
                            .foregroundColor(.white)
                        Text("HRV over time")
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
    HeartRateVariabilityChartView(viewModel: HealthCardViewModel(card: HealthCard.heartRateVariability))
}

