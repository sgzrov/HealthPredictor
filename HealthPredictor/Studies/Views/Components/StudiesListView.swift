//
//  StudiesListView.swift
//  HealthPredictor
//
//  Created by Stephan on 24.06.2025.
//

import SwiftUI

struct StudiesListView: View {

    let studies: [Study]

    var body: some View {
        LazyVStack(spacing: 16) {
            if studies.isEmpty {
                VStack {
                    Spacer(minLength: 120)
                    Text("Tap + to import a new study.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            }
            ForEach(studies) { study in
                NavigationLink(destination: StudyDetailedView(study: study)) {
                    StudyCardView(viewModel: StudyCardViewModel(study: study))
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

struct StudiesListView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleStudies = [
            Study(
                id: UUID(),
                title: "Sample Study 1",
                summary: "This is a summary for study 1.",
                personalizedInsight: "Personalized insight 1.",
                sourceURL: URL(string: "https://example.com/1")!
            ),
            Study(
                id: UUID(),
                title: "Sample Study 2",
                summary: "This is a summary for study 2.",
                personalizedInsight: "Personalized insight 2.",
                sourceURL: URL(string: "https://example.com/2")!
            )
        ]
        StudiesListView(studies: sampleStudies)
            .previewLayout(.sizeThatFits)
    }
}
