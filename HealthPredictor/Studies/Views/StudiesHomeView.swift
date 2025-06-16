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

    @State private var searchText: String = ""
    @State private var showSheet: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var selectedFileURL: URL?
    @State private var currentStudy: Study = Study(title: "Test Study", summary: "This is a test study for development purposes.", personalizedInsight: "This is a test insight", sourceURL: URL(string: "https://example.com")!)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 14) {

                    HStack {
                        Button(action: {
                            // Edit action
                        }) {
                            Text("Edit")
                        }

                        Spacer()

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

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Studies")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(Color(.tertiaryLabel))
                                TextField("Search", text: $searchText)
                            }
                            .padding(6)
                            .background(Color(.secondarySystemFill))
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity)

                            Button(action: {
                                // Filter action
                            }) {
                                Image(systemName: "line.3.horizontal.decrease")
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        Button(action: {
                            studiesVM.selectedCategory = .recommended
                        }) {
                            Text("Recommended")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(studiesVM.selectedCategory == .recommended ? .white : .primary.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(studiesVM.selectedCategory == .recommended ? Color.accentColor : Color(.secondarySystemFill))
                                .cornerRadius(16)
                        }

                        Button(action: {
                            studiesVM.selectedCategory = .all
                        }) {
                            Text("All")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(studiesVM.selectedCategory == .all ? .white : .primary.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(studiesVM.selectedCategory == .all ? Color.accentColor : Color(.secondarySystemFill))
                                .cornerRadius(16)
                        }
                    }

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if studiesVM.selectedCategory == .recommended {
                                if studiesVM.recommendedStudies.isEmpty {
                                    VStack(spacing: 12) {
                                        Text("No recommended studies.")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.top, 40)
                                }
                            }

                            ForEach(studiesVM.selectedCategory == .recommended ? studiesVM.recommendedStudies : studiesVM.allStudies) { study in
                                NavigationLink(destination: StudyDetailedView(study: study)) {
                                    StudyCardView(study: study)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 16)
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
                    }
                )
            }
        }
        .onAppear {
            studiesVM.loadStudies()
        }
    }
}

#Preview {
    StudiesHomeView()
}
