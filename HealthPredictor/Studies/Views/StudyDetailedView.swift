//
//  StudyDetailedView.swift
//  HealthPredictor
//
//  Created by Stephan  on 05.06.2025.
//

import SwiftUI

struct StudyDetailedView: View {

    let study: Study

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Summary: ")
                    .font(.headline)
                Text(study.summary)
                Text("Outcome: ")
                    .font(.headline)
                Text(study.outcome)
            }
            .padding()
        }
    }
}

#Preview {
    StudyDetailedView(study: Study(
        title: "How can high heart rates increase the risk of cancer?",
        summary: "This is a sample summary.",
        outcome: "This is a sample outcome.",
        importDate: Date()
    ))
}
