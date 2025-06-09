//
//  TagExtractionViewModel.swift
//  HealthPredictor
//
//  Created by Stephan  on 30.05.2025.
//

import Foundation
import NaturalLanguage
import SwiftUI
import PDFKit

@MainActor
class TagExtractionViewModel: ImportURLViewModel {

    @Published var topTags: [Tag] = []
    @Published var visibleTags: [Tag] = []
    @Published var isExtractingTags: Bool = false

    private var tagExtractionTask: Task<Void, Never>?

    override func validateFileType(url: URL) async {
        await super.validateFileType(url: url)

        if isPDF || isHTML {
            tagExtractionTask?.cancel()
            tagExtractionTask = Task { [weak self] in
                await self?.extractTags(from: url)
            }
        }
    }

    private func extractTextFromHTML(_ htmlString: String) -> String {
        var text = htmlString
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")

        text = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
        return text
    }

    private func extractTags(from url: URL) async {
        isExtractingTags = true
        topTags = []
        visibleTags = []

        do {
            let data = try await fetchData(for: url)
            let text = extractText(from: data, isPDF: isPDF, isHTML: isHTML)
            let tags = extractHealthTags(from: text)
            await updateVisibleTags(with: tags)
        } catch {
            print("Error extracting tags: \(error)") // Debug print
        }

        isExtractingTags = false
    }

    func fetchData(for url: URL) async throws -> Data {
        if url.isFileURL {
            return try Data(contentsOf: url)
        } else {
            let (fetchedData, _) = try await CloudflareCheck.shared.makeRequest(to: url)
            return fetchedData
        }
    }

    func extractText(from data: Data, isPDF: Bool, isHTML: Bool) -> String {
        if isPDF {
            if let pdfDoc = PDFDocument(data: data) {
                return (0..<pdfDoc.pageCount).compactMap { pdfDoc.page(at: $0)?.string }.joined(separator: " ")
            } else {
                print("Failed to load PDFDocument.") // Debug print
                return ""
            }
        } else if isHTML {
            if let htmlString = String(data: data, encoding: .utf8) {
                return extractTextFromHTML(htmlString)
            } else {
                print("Failed to decode HTML") // Debug print
                return ""
            }
        }
        return ""
    }

    private func extractHealthTags(from text: String) -> [Tag] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .lemma])
        tagger.string = text

        var tagCounts: [String: Int] = [:]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            if tag == .noun {
                if let lemma = tagger.tag(at: tokenRange.lowerBound, unit: .word, scheme: .lemma).0?.rawValue {
                    let normalized = lemma.lowercased()
                    if Tag.healthKeywords.contains(where: { $0.name.lowercased() == normalized }) {
                        print("Matched health keyword: \(normalized) at range: \(tokenRange)") // Debug print
                        tagCounts[normalized.capitalized, default: 0] += 1
                    }
                }
            }
            return true
        }

        let matched = tagCounts.sorted { $0.value > $1.value }
            .compactMap { name, _ in
                let tag = Tag.healthKeywords.first { $0.name.lowercased() == name.lowercased() }
                if let tag = tag {
                    print("Selected tag for UI: \(tag.name)") // Debug print
                }
                return tag
            }

        return Array(matched.prefix(4))
    }

    private func updateVisibleTags(with tags: [Tag]) async {
        topTags = tags
        for tag in tags {
            try? await Task.sleep(nanoseconds: UInt64(0.08 * 1_000_000_000))
            if Task.isCancelled { return }
            visibleTags.append(Tag(name: tag.name, color: tag.color, subtags: tag.subtags))
        }
    }

    func clearTags() {
        topTags = []
        visibleTags = []
    }

    override func clearInput() {
        super.clearInput()
        clearTags()
    }
}

