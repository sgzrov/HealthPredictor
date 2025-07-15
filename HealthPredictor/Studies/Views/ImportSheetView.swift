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
                HStack {
                    Button(action: {
                        showFileImporter = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(.secondarySystemFill))
                                .frame(width: 36, height: 36)
                            Image(systemName: "folder")
                                .resizable()
                                .frame(width: 19, height: 16)
                                .foregroundColor(Color.accentColor)
                        }
                    }
                    Spacer()
                    Button(action: onDismiss) {
                        ZStack {
                            Circle()
                                .fill(Color(.secondarySystemFill))
                                .frame(width: 30, height: 30)
                            Image(systemName: "xmark")
                                .resizable()
                                .frame(width: 12, height: 12)
                                .foregroundColor(Color(.systemGroupedBackground))
                        }
                    }
                }
                .padding(.top, 6)

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

                if selectedFileURL == nil {
                    VStack {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(Color(.tertiaryLabel))

                            TextField("Paste URL here", text: $importVM.importInput)
                                .focused($isTextFieldFocused)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .truncationMode(.middle)
                                .onChange(of: importVM.importInput) { oldValue, newValue in
                                    importVM.validateURL()
                                    if importVM.isFullyValidURL(), let url = URL(string: newValue) {
                                        Task {
                                            await importVM.validateFileType(url: url)
                                        }
                                    }
                                }

                            if !importVM.importInput.isEmpty {
                                Button(action: {
                                    importVM.clearInput()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(.secondarySystemFill))
                        .cornerRadius(12)

                        .padding(.top, 40)

                        if !importVM.errorMessage.isEmpty {
                            Text(importVM.errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 2)
                                .padding(.top, 6)
                        }
                    }
                }

                if let fileURL = selectedFileURL {
                    let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
                    let fileSize = attrs?[.size] as? UInt64
                    let fileDate = attrs?[.modificationDate] as? Date

                    let dateString: String = {
                        guard let fileDate else { return "" }
                        let formatter = DateFormatter()
                        let regionCode = Locale.current.region?.identifier ?? "US"
                        if ["US", "CA", "PH"].contains(regionCode) {
                            formatter.dateFormat = "MM.dd.yyyy"
                        } else {
                            formatter.dateFormat = "dd.MM.yyyy"
                        }
                        return formatter.string(from: fileDate)
                    }()

                    let sizeString: String = {
                        guard let fileSize else { return "" }
                        if fileSize < 1024 {
                            return "\(fileSize) bytes"
                        } else if fileSize < 1024 * 1024 {
                            return String(format: "%.1f KB", Double(fileSize) / 1024.0)
                        } else {
                            return String(format: "%.2f MB", Double(fileSize) / (1024.0 * 1024.0))
                        }
                    }()

                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Image(systemName: "folder.badge.plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.accentColor)
                            .alignmentGuide(.firstTextBaseline) { dimensions in
                                dimensions[VerticalAlignment.center] - 0.5
                            }
                        VStack(alignment: .leading, spacing: 10) {
                            Text(fileURL.lastPathComponent)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text("\(dateString) - \(sizeString)")
                                .font(.footnote)
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemFill))
                    .cornerRadius(12)
                    .padding(.top, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if !importVM.topTags.isEmpty && importVM.errorMessage.isEmpty && (importVM.isFullyValidURL() || selectedFileURL != nil) {
                    HStack(spacing: 8) {
                        ForEach(importVM.visibleTags.indices, id: \.self) { idx in
                            TagView(tag: importVM.visibleTags[idx])
                                .transition(.scale.combined(with: .opacity))
                                .onAppear {
                                    if idx == importVM.visibleTags.count - 1 {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            isTextFieldFocused = false
                                        }
                                    }
                                }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 12)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: importVM.visibleTags)
                }

                Spacer()

                Button(action: {
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
                        let extractedText = try? await TextExtractionService.shared.extractText(from: url)  // Perform text extraction
                        // Debug print
                        guard let extractedText, !extractedText.isEmpty else {
                            print("Text extraction failed for URL: \(url)")
                            return
                        }

                        // Generate summary
                        Task {
                            _ = await summaryVM.summarizeStudy(text: extractedText)
                        }

                        // Generate outcome
                        Task {
                            _ = await outcomeVM.generateOutcome(from: extractedText)
                        }

                        // Stream summary (part by part)
                        Task {
                            for await _ in summaryVM.$summarizedText.values {
                                if let summary = summaryVM.summarizedText, !summary.isEmpty {
                                    await MainActor.run {
                                        study.summary = summary
                                    }
                                }
                            }
                        }

                        // Stream outcome (part by part)
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
                }) {
                    Text("Import")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(14)
                }
                .disabled(
                    importVM.isLoading ||
                    importVM.isExtractingTags ||
                    importVM.visibleTags.count < 1 ||
                    (importVM.importInput.isEmpty && selectedFileURL == nil) ||
                    (!importVM.isFullyValidURL() && selectedFileURL == nil) ||
                    !importVM.errorMessage.isEmpty ||
                    summaryVM.isSummarizing
                )
                .opacity(
                    importVM.isLoading ||
                    importVM.isExtractingTags ||
                    importVM.visibleTags.count < 1 ||
                    (importVM.importInput.isEmpty && selectedFileURL == nil) ||
                    (!importVM.isFullyValidURL() && selectedFileURL == nil) ||
                    !importVM.errorMessage.isEmpty ||
                    summaryVM.isSummarizing
                    ? 0.5 : 1.0
                )
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
        }
        .ignoresSafeArea(.keyboard)
        .onTapGesture {
            isTextFieldFocused = false
        }
        .presentationDetents([.large])
        .animation(.easeInOut(duration: 0.2), value: selectedFileURL)
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf, .plainText, .rtf, .text, .data], allowsMultipleSelection: false) { result in
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
