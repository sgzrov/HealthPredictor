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
            .foregroundColor(.primary)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 4)
        )
        .padding(.horizontal, 20)
    }
}

#Preview {
    InsightCardView(insightTitle: "Your sleep quality has dropped 20% today. Consider winding down earlier.")
}
