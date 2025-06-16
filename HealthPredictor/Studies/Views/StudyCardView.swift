//
//  StudyCardView.swift
//  HealthPredictor
//
//  Created by Stephan  on 16.06.2025.
//

import SwiftUI

struct StudyCardView: View {
    let study: Study

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.black, lineWidth: 1)
            )
            .overlay(
                Text(study.title)
                    .font(.headline)
                    .padding()
            )
            .frame(height: 80)
            .padding(.horizontal)
    }
}

#Preview {
    StudyCardView(study: Study(
        title: "Sample Study Title",
        summary: "This is a sample study summary.",
        personalizedInsight: "This is a sample personalized insight.",
        sourceURL: URL(string: "https://example.com")!
    ))
}
