//
//  ImportSheetView.swift
//  HealthPredictor
//
//  Created by Stephan  on 25.05.2025.
//

import SwiftUI

struct ImportSheetView: View {

    @ObservedObject var importVM: StudiesImportViewModel

    @Binding var showFileImporter: Bool
    @Binding var selectedFileURL: URL?

    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
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
                    Text("📥")
                        .font(.system(size: 60))
                        .padding(.bottom, 8)
                    VStack {
                        Text("Import")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Health Studies")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    Text("Import studies via URL or document to see how their results correlate with your health data.")
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

                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(Color(.tertiaryLabel))
                        TextField("Paste URL here", text: $importVM.importInput)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .truncationMode(.middle)
                            .onChange(of: importVM.importInput) { oldValue, newValue in
                                importVM.validateURL()
                            }
                        if !importVM.importInput.isEmpty {
                            Button(action: {
                                importVM.importInput = ""
                                importVM.errorMessage = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.secondarySystemFill))
                    .cornerRadius(12)

                    if !importVM.errorMessage.isEmpty {
                        Text(importVM.errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 2)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 2)

                Button(action: {
                    showFileImporter = true
                }) {
                    Text("Choose Files...")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                        .padding(.top, 10)
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
                    // Import action
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

#Preview {
    ImportSheetView(
        importVM: StudiesImportViewModel(),
        showFileImporter: .constant(false),
        selectedFileURL: .constant(nil),
        onDismiss: {}
    )
}
