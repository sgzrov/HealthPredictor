//
//  StudyDetailedView.swift
//  HealthPredictor
//
//  Created by Stephan  on 05.06.2025.
//

import SwiftUI

struct StudyDetailedView: View {

    @ObservedObject var study: Study

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Summary: ")
                    .font(.headline)
                Text(study.summary)
                Text("Outcome: ")
                    .font(.headline)
                Text(study.personalizedInsight)
            }
            .padding()
        }
    }
}

#Preview {
    StudyDetailedView(study: Study(
        title: "Sample Study",
        summary: "This is a sample study summary.",
        personalizedInsight: "This is a sample personalized insight.",
        sourceURL: URL(string: "https://example.com")!
    ))
}
