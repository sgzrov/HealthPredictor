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
                        .padding(.bottom, 4)
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
                        .padding(.horizontal, 24)
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
                        formatter.dateFormat = "mm.dd.yyyy"
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
        .animation(.easeInOut(duration: 0.3), value: selectedFileURL)
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
