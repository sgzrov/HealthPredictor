//
//  ImportSheetView.swift
//  HealthPredictor
//
//  Created by Stephan  on 25.05.2025.
//

import SwiftUI

struct ImportSheetView: View {
    @ObservedObject var importVM: TagExtractionViewModel

    @Binding var showFileImporter: Bool
    @Binding var selectedFileURL: URL?

    var onDismiss: () -> Void

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

                VStack {
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
                    .padding(.bottom, 16)
                    Text("Import studies to view how their results correlate with your health data.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 58)
                        .lineSpacing(2)
                }
                .padding(.bottom, 30)

                if selectedFileURL == nil {
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
                        .padding(10)
                        .background(Color(.secondarySystemFill))
                        .cornerRadius(12)

                        if !importVM.errorMessage.isEmpty {
                            Text(importVM.errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 2)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 2)
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
                    .padding(.horizontal, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if !importVM.topTags.isEmpty && importVM.errorMessage.isEmpty && importVM.isFullyValidURL() {
                    HStack(spacing: 8) {
                        ForEach(importVM.visibleTags) { tag in
                            TagView(tag: tag)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: importVM.visibleTags)
                }

                Spacer()

                Button(action: {
                    // Import action
                    onDismiss()
                }) {
                    Text("Import Study")
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
                    !importVM.errorMessage.isEmpty
                )
                .opacity(
                    importVM.isLoading ||
                    importVM.isExtractingTags ||
                    importVM.visibleTags.count < 1 ||
                    (importVM.importInput.isEmpty && selectedFileURL == nil) ||
                    (!importVM.isFullyValidURL() && selectedFileURL == nil) ||
                    !importVM.errorMessage.isEmpty
                    ? 0.5 : 1.0
                )
                .padding(.horizontal, 8)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .presentationDetents([.large])
        .animation(.easeInOut(duration: 0.3), value: selectedFileURL)
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
        onDismiss: {}
    )
}
