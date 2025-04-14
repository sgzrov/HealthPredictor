//
//  HighlightsView.swift
//  HealthPredictor
//
//  Created by Stephan  on 08.04.2025.
//

import SwiftUI

struct HighlightsView: View {
    @State private var isRefreshing = false
    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.headerToContent) {
            HStack {
                Text("Highlights")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.leading, LayoutConstants.leadingPadding)

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        // Handle refresh logic here
                        withAnimation {
                            isRefreshing.toggle()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.gray)
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    }

                    Button {
                        // Handle copy action here
                        withAnimation {
                            isCopied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                isCopied = false
                            }
                        }
                    } label: {
                        Image(systemName: isCopied ? "checkmark" : "square.on.square")
                            .foregroundColor(.gray)
                    }

                    Button {
                        // Handle chat navigation here
                    } label: {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, LayoutConstants.horizontalPadding)
            }

            InsightCardView(card: InsightCard(
                title: "Your sleep quality has dropped 20% throughout this week. Consider winding down earlier.",
                backgroundColor: Color(hex: "#28242c"),
                textColor: .white
            ))
            .padding(.horizontal, LayoutConstants.cardPadding)
        }
        .padding(.top, 5)
    }
}

#Preview {
    HighlightsView()
        .background(Color(hex: "#100c1c"))
}
