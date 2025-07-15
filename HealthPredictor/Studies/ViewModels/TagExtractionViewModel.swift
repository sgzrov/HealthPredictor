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
    private let textExtractionService = TextExtractionService.shared

    override func validateFileType(url: URL) async {
        await super.validateFileType(url: url)

        if isPDF || isHTML {
            tagExtractionTask?.cancel()
            tagExtractionTask = Task { [weak self] in
                await self?.extractTags(from: url)
            }
        }
    }

    private func extractTags(from url: URL) async {
        isExtractingTags = true
        topTags = []
        visibleTags = []

        if url.isFileURL {
            try? await Task.sleep(nanoseconds: UInt64(75_000_000))
            if Task.isCancelled { return }
        }

        do {
            let text = try await textExtractionService.extractText(from: url)
            let tags = extractHealthTags(from: text)
            await updateVisibleTags(with: tags)
        } catch {
            print("Error extracting tags: \(error)") // Debug print
        }

        isExtractingTags = false
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
        stopAccessingCurrentFile()
    }
}

