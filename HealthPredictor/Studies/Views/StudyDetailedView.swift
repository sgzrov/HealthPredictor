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
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary:")
                .font(.headline)
            Text(study.summary)
                .font(.body)
        }
        .padding()
    }
}

#Preview {
    StudyDetailedView(study: Study(
        title: "Sample Study",
        summary: "This is a sample study summary.",
        sourceURL: URL(string: "https://example.com")!
    ))
}
