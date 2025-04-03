//
//  MinimizedCardIconView.swift
//  HealthPredictor
//
//  Created by Stephan  on 02.04.2025.
// This view holds small icons per card (emoji + shape).

import SwiftUI

struct MinimizedCardIconView: View {
    let emoji: String

    var body: some View {
        Text(emoji)
            .font(.system(size: 8))
            .frame(width: 18, height: 18)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.gray.opacity(0.2))
            )
    }
}

#Preview {
    MinimizedCardIconView(emoji: "❤️")
}
