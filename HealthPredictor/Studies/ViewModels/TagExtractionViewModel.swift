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
            let (data, _) = try await CloudflareCheck.shared.makeRequest(to: url)
            var text = ""

            if isPDF {
                if let pdfDoc = PDFDocument(data: data) {
                    text = (0..<pdfDoc.pageCount).compactMap { pdfDoc.page(at: $0)?.string }.joined(separator: " ")
                } else {
                    print("Failed to load PDFDocument")
                    isExtractingTags = false
                    return
                }
            } else if isHTML {
                if let htmlString = String(data: data, encoding: .utf8) {
                    text = extractTextFromHTML(htmlString)
                } else {
                    print("Failed to decode HTML")
                    isExtractingTags = false
                    return
                }
            }

            let tagger = NLTagger(tagSchemes: [.lexicalClass, .lemma])
            tagger.string = text

            var tagCounts: [String: Int] = [:]

            tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
                if tag == .noun {
                    if let lemma = tagger.tag(at: tokenRange.lowerBound, unit: .word, scheme: .lemma).0?.rawValue {
                        let normalized = lemma.lowercased()
                        if Tag.healthKeywords.contains(where: { $0.name.lowercased() == normalized }) {
                            tagCounts[normalized.capitalized, default: 0] += 1
                        }
                    }
                }
                return true
            }

            let matched = tagCounts
                .sorted { $0.value > $1.value }
                .compactMap { name, _ in
                    Tag.healthKeywords.first { $0.name.lowercased() == name.lowercased() }
                }
            topTags = Array(matched.prefix(4))

            for tag in topTags {
                try? await Task.sleep(nanoseconds: UInt64(0.08 * 1_000_000_000))
                if Task.isCancelled { return }
                visibleTags.append(Tag(name: tag.name, color: tag.color))
            }

        } catch {
            print("Error extracting tags: \(error)")
        }

        isExtractingTags = false
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

