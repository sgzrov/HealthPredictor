//
//  StudyCardView.swift
//  HealthPredictor
//
//  Created by Stephan  on 16.06.2025.
//

import SwiftUI

struct StudyCardView: View {

    @ObservedObject var study: Study

    let onRefreshSummary: () -> Void
    let onRefreshOutcome: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(study.title)
                .font(.headline)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.gray, lineWidth: 1))
    }
}

#Preview {
    StudyCardView(study: Study(
        title: "Sample Study Title",
        summary: "This is a sample study summary.",
        personalizedInsight: "This is a sample personalized insight.",
        sourceURL: URL(string: "https://example.com")!
    )) {
    } onRefreshOutcome: {
    }
}
