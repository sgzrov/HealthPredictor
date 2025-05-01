//
//  CaloriesBurntChartView.swift
//  HealthPredictor
//
//  Created by Stephan  on 01.05.2025.
//

import SwiftUI

struct CaloriesBurntChartView: View {
    @ObservedObject var viewModel: HealthCardViewModel

    var body: some View {
        VStack {
            // Replace with actual calories visualization
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(hex: "#28242c"))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Text("Calories Burnt Chart")
                            .foregroundColor(.white)
                        Text("Calories per day")
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
    CaloriesBurntChartView(viewModel: HealthCardViewModel(card: HealthCard.caloriesBurnt))
        .padding()
        .background(Color.gray.opacity(0.1))
}
