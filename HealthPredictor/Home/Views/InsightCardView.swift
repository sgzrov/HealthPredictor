//
//  InsightCardView.swift
//  HealthPredictor
//
//  Created by Stephan  on 29.03.2025.
//

import SwiftUI

struct InsightCardView: View {
    @StateObject var insightCardViewModel: InsightCardViewModel

    init(card: InsightCard) {
        _insightCardViewModel = StateObject(wrappedValue: InsightCardViewModel(card: card))
    }

    var body: some View {
        HStack {
            Text(insightCardViewModel.card.title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(insightCardViewModel.card.textColor)
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(insightCardViewModel.card.backgroundColor)
        )
    }
}

#Preview {
    InsightCardView(card: InsightCard(
        title: "Your sleep quality has dropped 20% throughout this week. Consider winding down earlier.",
        backgroundColor: Color(hex: "#28242c"),
        textColor: .white
    ))
}
