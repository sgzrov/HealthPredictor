//
//  SleepDurationQualityChartView.swift
//  HealthPredictor
//
//  Created by Stephan  on 01.05.2025.
//

import SwiftUI

struct SleepDurationQualityChartView: View {
    @ObservedObject var viewModel: HealthCardViewModel

    var body: some View {
        VStack {
            // Replace with actual sleep duration and quality visualization
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(hex: "#28242c"))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Text("Sleep Duration & Quality")
                            .foregroundColor(.white)
                        Text("Hours and quality score")
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
    SleepDurationQualityChartView(viewModel: HealthCardViewModel(card: HealthCard.sleepDurationQuality))
        .padding()
        .background(Color.gray.opacity(0.1))
}
