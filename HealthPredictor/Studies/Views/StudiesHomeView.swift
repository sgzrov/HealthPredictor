//
//  StudiesHomeView.swift
//  HealthPredictor
//
//  Created by Stephan  on 24.05.2025.
//

import SwiftUI

struct StudiesHomeView: View {

    @StateObject private var importVM = TagExtractionViewModel()
    @StateObject private var studiesVM: StudyViewModel

    @State private var showSheet: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var selectedFileURL: URL?
    @State private var currentStudy: Study?
    @State private var navigateToStudy: Study?

    init(userToken: String) {
        _studiesVM = StateObject(wrappedValue: StudyViewModel(userToken: userToken))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    if studiesVM.isLoading {
                        VStack {
                            Spacer(minLength: 120)
                            ProgressView("Loading studies...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else if studiesVM.studies.isEmpty {
                        VStack {
                            Spacer(minLength: 120)
                            Text("Tap + to import your first study")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                    } else {
                        StudiesListView(studies: studiesVM.studies)
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            navigateToStudy = study
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                studiesVM.createStudy(title: study.title, summary: study.summary, outcome: study.outcome)
                            }
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
            .refreshable {
                studiesVM.loadStudies()
            }
        }
    }
}

#Preview {
    StudiesHomeView(userToken: "preview-token")
}
