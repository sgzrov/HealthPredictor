//
//  StudiesHomeView.swift
//  HealthPredictor
//
//  Created by Stephan  on 24.05.2025.
//

import SwiftUI

struct StudiesHomeView: View {

    @StateObject private var importVM = TagExtractionViewModel()
    @StateObject private var studiesVM = StudyViewModel()

    @State private var showSheet: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var selectedFileURL: URL?
    @State private var currentStudy: Study?
    @State private var navigateToStudy: Study?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    ScrollView {
                        StudiesListView(studies: studiesVM.allStudies)
                    }
                }
            }
            .navigationDestination(item: $navigateToStudy) { study in
                StudyDetailedView(study: study)
            }
            .sheet(isPresented: $showSheet) {
                ImportSheetView(
                    importVM: importVM,
                    showFileImporter: $showFileImporter,
                    selectedFileURL: $selectedFileURL,
                    onDismiss: {
                        showSheet = false
                        selectedFileURL = nil
                        importVM.clearInput()
                    },
                    onImport: { study in
                        currentStudy = study
                        studiesVM.allStudies.insert(study, at: 0)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            navigateToStudy = study
                        }
                    }
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Edit") {
                        // Edit action
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSheet = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(.secondarySystemFill))
                                .frame(width: 30, height: 30)
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 14, height: 14)
                                .foregroundColor(Color(.systemGroupedBackground))
                        }
                    }
                }
            }
            .navigationTitle("Studies")
        }
    }
}

#Preview {
    StudiesHomeView()
}
