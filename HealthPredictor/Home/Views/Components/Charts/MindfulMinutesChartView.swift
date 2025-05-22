//
//  MindfulMinutesChartView.swift
//  HealthPredictor
//
//  Created by Stephan  on 01.05.2025.
//

import SwiftUI

struct MindfulMinutesChartView: View {
    @ObservedObject var viewModel: HealthCardViewModel

    var body: some View {
        VStack {
            // Replace with actual mindful minutes visualization
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(hex: "#28242c"))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Text("Mindful Minutes")
                            .foregroundColor(.white)
                        Text("Minutes per day")
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
    MindfulMinutesChartView(viewModel: HealthCardViewModel(card: HealthCard.mindfulMinutes))
}
