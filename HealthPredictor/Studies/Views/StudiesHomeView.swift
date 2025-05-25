//
//  StudiesHomeView.swift
//  HealthPredictor
//
//  Created by Stephan  on 24.05.2025.
//

import SwiftUI

struct StudiesHomeView: View {

    @StateObject private var importVM = StudiesImportViewModel()
    
    @State private var searchText: String = ""
    @State private var showSheet: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var selectedFileURL: URL? = nil

    var body: some View {
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
                                .frame(width: 24, height: 24)
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 12, height: 12)
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
                    Text("Imported")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemFill))
                        .cornerRadius(16)

                    Text("Recommmended")
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
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button(action: {
                            showSheet = false
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(.secondarySystemFill))
                                    .frame(width: 24, height: 24)
                                Image(systemName: "xmark")
                                    .resizable()
                                    .frame(width: 10, height: 10)
                                    .foregroundColor(Color(.systemGroupedBackground))
                            }
                        }
                    }

                    VStack(spacing: 20) {
                        VStack {
                            Text("Import")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Health Studies")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        Text("Import studies via text, URL, or document to see how their results correlate with your health data.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 32)

                    if let fileURL = selectedFileURL {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "doc.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fileURL.lastPathComponent)
                                    .font(.headline)
                                Text("Selected file")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemFill))
                        .cornerRadius(16)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    }

                    if importVM.isText {
                        TextEditor(text: $importVM.importInput)
                            .frame(minHeight: 100, maxHeight: 200)
                            .padding(12)
                            .background(Color(.secondarySystemFill))
                            .cornerRadius(12)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 2)
                    } else {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(Color(.tertiaryLabel))
                            TextField("Paste URL or text here", text: $importVM.importInput)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .truncationMode(.middle)
                            if !importVM.importInput.isEmpty {
                                Button(action: {
                                    importVM.importInput = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(.secondarySystemFill))
                        .cornerRadius(12)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 2)
                    }

                    Button(action: {
                        showFileImporter = true
                    }) {
                        Text("Choose Files...")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                            .padding(.top, 8)
                    }
                    .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf, .plainText, .rtf, .text, .data], allowsMultipleSelection: false) { result in
                        switch result {
                        case .success(let urls):
                            selectedFileURL = urls.first
                        case .failure:
                            selectedFileURL = nil
                        }
                    }

                    Spacer()

                    Button(action: {

                    }) {
                        Text("Import Study")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .presentationDetents([.large])
        }
    }
}

#Preview {
    StudiesHomeView()
}
