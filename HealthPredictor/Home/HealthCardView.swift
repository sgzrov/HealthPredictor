//
//  HealthCardView.swift
//  HealthPredictor
//
//  Created by Stephan  on 29.03.2025.
//

import SwiftUI

struct HealthCardView: View {
    let title: String
    let emoji: String
    let value: Int
    let goal: Int
    let metric: String
    let cardColor: Color
    let otherColor: Color

    // Percentage calculation
    var percentage: Int {
        guard goal != 0 else { return 0 }
        return min(100, (value * 100) / goal)
    }

    // Bars to fill calculation
    var filledBars: Int {
        return min(6, (percentage * 6) / 100)
    }

    var body: some View {
        VStack(spacing: 12) {

            HStack(alignment: .firstTextBaseline) {
                Text(emoji)
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(otherColor)
                Spacer()
                Text("4% lower")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(otherColor)
            }
            .padding(.top, 3)

            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 0) {
                    Text("\(value)")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(otherColor)
                    Text("/")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(Color(hex: "#505048"))
                    Text("\(goal) \(metric)")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(Color(hex: "#505048"))
                }
                Spacer()
                Text("\(percentage)%")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(otherColor)
            }
            .offset(y: 5)

            HStack(spacing: 4) {
                ForEach(0..<6) { index in
                    Capsule()
                        .fill(index < filledBars ? Color(otherColor) : Color(hex: "#505048").opacity(0.2))
                        .frame(height: 6)
                }
            }
            .offset(y: -3)

        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(cardColor)
        )
        .padding(.horizontal, 20)
    }
}

#Preview {
    HealthCardView(title: "Heart rate", emoji: "❤️", value: 65, goal: 82, metric: "bpm", cardColor: Color(hex: "#f0fc4c"), otherColor: Color(hex: "#0c0804"))
}
