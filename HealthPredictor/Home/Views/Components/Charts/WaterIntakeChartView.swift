//
//  WaterIntakeChartView.swift
//  HealthPredictor
//
//  Created by Stephan  on 01.05.2025.
//

import SwiftUI

struct WaterIntakeChartView: View {
    @ObservedObject var viewModel: HealthCardViewModel

    var body: some View {
        VStack {
            // Replace with actual water visualisation
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(hex: "#28242c"))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Text("Water Intake Chart")
                            .foregroundColor(.white)
                        Text("Liters per day")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                )
        }
    }
}

#Preview {
    WaterIntakeChartView(viewModel: HealthCardViewModel(card: HealthCard.water))
}
