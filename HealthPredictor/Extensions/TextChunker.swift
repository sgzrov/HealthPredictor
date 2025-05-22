import Foundation
import NaturalLanguage

struct TextChunker {
    // Splits the output into sentences.
    static func sentences(from text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        var result: [String] = []
        
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty {
                result.append(sentence)
            }
            return true
        }
        return result
    }

    // Splits output into words. Check out bug with punctuation not being attached.
    static func words(from sentence: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = sentence
        var result: [String] = []
        
        tokenizer.enumerateTokens(in: sentence.startIndex..<sentence.endIndex) { range, _ in
            let word = String(sentence[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !word.isEmpty {
                result.append(word)
            }
            return true
        }
        return result
    }

    // Groups words into chunnks (for chunk fade-ins). If there's a chunked fade-in, we do not need a sentence splitter.
    static func chunkedWords(from sentence: String, chunkSize: Int) -> [String] {
        let words = self.words(from: sentence)
        guard chunkSize > 0 else { return words }
        return stride(from: 0, to: words.count, by: chunkSize).map {
            Array(words[$0..<min($0 + chunkSize, words.count)]).joined(separator: " ")
        }
    }
}
