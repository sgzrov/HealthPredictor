//
//  InsightCardView.swift
//  HealthPredictor
//
//  Created by Stephan  on 29.03.2025.
//

import SwiftUI

struct InsightCardView: View {
    let insightTitle: String

    var body: some View {
        Text(insightTitle)
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundColor(.white)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color(hex: "#28242c"))
        )
        .padding(.horizontal, 20)
    }
}

#Preview {
    InsightCardView(insightTitle: "Your sleep quality has dropped 20% throughout this week. Consider winding down earlier.")
}
