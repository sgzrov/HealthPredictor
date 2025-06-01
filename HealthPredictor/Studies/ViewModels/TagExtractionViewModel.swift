//
//  TagExtractionViewModel.swift
//  HealthPredictor
//
//  Created by Stephan  on 30.05.2025.
//

import Foundation
import NaturalLanguage
import SwiftUI

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
        // Simple HTML tag removal
        var text = htmlString
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")

        // Remove extra whitespace
        text = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")

        return text
    }

    private func extractTags(from url: URL) async {
        isExtractingTags = true
        topTags = []
        visibleTags = []

        do {
            let data: Data
            if url.pathExtension.lowercased() == "pdf" {
                // For PDFs, use direct URLSession
                let (pdfData, _) = try await URLSession.shared.data(from: url)
                data = pdfData
            } else {
                // For HTML content, use CloudflareCheck
                let (htmlData, _) = try await CloudflareCheck.shared.makeRequest(to: url)
                data = htmlData
            }

            guard let htmlString = String(data: data, encoding: .utf8) else {
                print("Failed to decode content")
                isExtractingTags = false
                return
            }

            let text = extractTextFromHTML(htmlString)

            let tagger = NLTagger(tagSchemes: [.lexicalClass, .lemma])
            tagger.string = text

            var tagCounts: [String: Int] = [:]

            tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
                if tag == .noun {
                    if let lemma = tagger.tag(at: tokenRange.lowerBound, unit: .word, scheme: .lemma).0?.rawValue {
                        let normalizedWord = lemma.lowercased()
                        if Tag.healthKeywords.contains(where: { $0.name.lowercased() == normalizedWord }) {
                            print("Matched tag: \(normalizedWord)")
                            tagCounts[normalizedWord.capitalized, default: 0] += 1
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
            topTags = Array(matched.prefix(4)) // Ensure 4 tags are shown (if exist in source)

            for tag in topTags {
                try? await Task.sleep(nanoseconds: UInt64(0.08 * 1_000_000_000))
                if Task.isCancelled { return }
                visibleTags.append(Tag(name: tag.name, color: tag.color))
            }

        } catch {
            print("Error extracting tags: \(error)")
            if let error = error as NSError? {
                if error.code == 403 {
                    print("Access denied - Cloudflare protection detected")
                }
            }
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
