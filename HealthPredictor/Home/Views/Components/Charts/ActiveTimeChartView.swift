//
//  ActiveTimeChartView.swift
//  HealthPredictor
//
//  Created by Stephan  on 01.05.2025.
//

import SwiftUI

struct ActiveTimeChartView: View {
    @ObservedObject var viewModel: HealthCardViewModel

    var body: some View {
        VStack {
            // Replace with actual active time visualization
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(hex: "#28242c"))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Text("Active Time Chart")
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
    ActiveTimeChartView(viewModel: HealthCardViewModel(card: HealthCard.activeTime))
        .padding()
        .background(Color.gray.opacity(0.1))
}
