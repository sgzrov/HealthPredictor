//
//  StudiesHomeView.swift
//  HealthPredictor
//
//  Created by Stephan  on 24.05.2025.
//

import SwiftUI

struct StudiesHomeView: View {

    @StateObject private var importVM = TagExtractionViewModel()

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

                        NavigationLink(destination: StudyDetailedView(study: currentStudy)) {
                            Text("View Study")
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.accentColor.opacity(0.15))
                                    .cornerRadius(8)
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
                        Text("Recommended")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary.opacity(0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemFill))
                            .cornerRadius(16)

                        Text("All")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary.opacity(0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemFill))
                            .cornerRadius(16)
                    }
                    Spacer()
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
                    }
                )
            }
        }
    }
}

#Preview {
    StudiesHomeView()
}
