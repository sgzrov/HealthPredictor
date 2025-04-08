//
//  HighlightsView.swift
//  HealthPredictor
//
//  Created by Stephan  on 08.04.2025.
//

import SwiftUI

struct HighlightsView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.headerToContent) {
            Text("Highlights")
                .font(.headline)
                .bold()
                .foregroundColor(.white)
                .padding(.leading, LayoutConstants.leadingPadding)

            InsightCardView(card: InsightCard(
                title: "Your sleep quality has dropped 20% throughout this week. Consider winding down earlier.",
                backgroundColor: Color(hex: "#28242c"),
                textColor: .white
            ))
                .padding(.horizontal, LayoutConstants.cardPadding)
        }
        .padding(.top, LayoutConstants.sectionSpacing + LayoutConstants.buttonPadding)
    }
}

#Preview {
    HighlightsView()
        .background(Color(hex: "#100c1c"))
}
