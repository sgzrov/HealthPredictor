//
//  ImportSheetView.swift
//  HealthPredictor
//
//  Created by Stephan  on 25.05.2025.
//

import SwiftUI

struct ImportSheetView: View {

    @ObservedObject var importVM: TagExtractionViewModel

    @StateObject private var summaryVM = SummaryViewModel()
    @StateObject private var outcomeVM = OutcomeViewModel()

    @Binding var showFileImporter: Bool
    @Binding var selectedFileURL: URL?

    @FocusState private var isTextFieldFocused: Bool

    var onDismiss: () -> Void
    var onImport: (Study) -> Void = { _ in }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                ImportSheetHeaderView(showFileImporter: $showFileImporter, onDismiss: onDismiss)
                VStack(spacing: 24) {
                    VStack {
                        Text("Import")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Health Studies")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 70)
                    Text("Import health studies to view how their findings correlate with your health data.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 50)
                }
                ImportSheetInputSection(importVM: importVM, selectedFileURL: $selectedFileURL, isTextFieldFocused: $isTextFieldFocused)
                ImportSheetTagsAndImportButton(importVM: importVM, summaryVM: summaryVM, outcomeVM: outcomeVM, selectedFileURL: $selectedFileURL, isTextFieldFocused: $isTextFieldFocused, onImport: {
                    let url = selectedFileURL ?? URL(string: importVM.importInput)!
                    let study = Study(
                        title: url.lastPathComponent,
                        summary: "",
                        personalizedInsight: "",
                        sourceURL: url
                    )
                    onImport(study)
                    onDismiss()
                    Task {
                        let extractedText = try? await TextExtractionService.shared.extractText(from: url)
                        guard let extractedText, !extractedText.isEmpty else {
                            print("Text extraction failed for URL: \(url)")
                            return
                        }
                        Task {
                            _ = await summaryVM.summarizeStudy(text: extractedText)
                        }
                        Task {
                            _ = await outcomeVM.generateOutcome(from: extractedText)
                        }
                        Task {
                            for await _ in summaryVM.$summarizedText.values {
                                if let summary = summaryVM.summarizedText, !summary.isEmpty {
                                    await MainActor.run {
                                        study.summary = summary
                                    }
                                }
                            }
                        }
                        Task {
                            for await _ in outcomeVM.$outcomeText.values {
                                if let outcome = outcomeVM.outcomeText, !outcome.isEmpty {
                                    await MainActor.run {
                                        study.personalizedInsight = outcome
                                    }
                                }
                            }
                        }
                    }
                })
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .ignoresSafeArea(.keyboard)
        .onTapGesture {
            isTextFieldFocused = false
        }
        .presentationDetents([.large])
        .animation(.easeInOut(duration: 0.2), value: selectedFileURL)
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf, .plainText, .rtf], allowsMultipleSelection: false) { result in
            importVM.clearTags()

            switch result {
            case .success(let urls):
                if let fileURL = urls.first {
                    selectedFileURL = fileURL
                    Task {
                        await importVM.validateFileType(url: fileURL)
                    }
                }
            case .failure:
                selectedFileURL = nil
            }
        }
    }
}

#Preview {
    ImportSheetView(
        importVM: TagExtractionViewModel(),
        showFileImporter: .constant(false),
        selectedFileURL: .constant(nil),
        onDismiss: {},
        onImport: { _ in }
    )
}
