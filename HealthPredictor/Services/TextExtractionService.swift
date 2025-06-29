//
//  TextExtractionService.swift
//  HealthPredictor
//
//  Created by Stephan  on 08.06.2025.
//

import Foundation
import PDFKit
import SwiftSoup

class TextExtractionService {

    static let shared = TextExtractionService()

    private init() {}

    func extractText(from url: URL) async throws -> String {
        let data = try await fetchData(for: url)
        let contentType = try await determineContentType(url: url)
        return extractTextFromSource(from: data, isPDF: contentType.isPDF, isHTML: contentType.isHTML)
    }

    private func fetchData(for url: URL) async throws -> Data {
        if url.isFileURL {
            return try Data(contentsOf: url)
        } else {
            let (fetchedData, _) = try await CloudflareCheck.shared.makeRequest(to: url)
            return fetchedData
        }
    }

    private func determineContentType(url: URL) async throws -> (isPDF: Bool, isHTML: Bool) {
        if url.isFileURL {
            let data = try Data(contentsOf: url)
            let isPDF = PDFDocument(data: data) != nil
            return (isPDF: isPDF, isHTML: false)
        } else {
            let result = await URLExtensionCheck.checkContentType(url: url)
            return (isPDF: result.type == .pdf, isHTML: result.type == .html)
        }
    }

    private func extractTextFromSource(from data: Data, isPDF: Bool, isHTML: Bool) -> String {
        if isPDF {
            return extractTextFromPDF(data)
        } else if isHTML {
            return extractTextFromHTML(data)
        } else {
            return extractTextFromPlainText(data)
        }
    }

    private func extractTextFromPDF(_ data: Data) -> String {
        guard let pdfDocument = PDFDocument(data: data) else { return "" }
        var text = ""
        for pageIndex in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex) {
                text += page.string ?? ""
            }
        }
        return text
    }

    private func extractTextFromHTML(_ data: Data) -> String {
        guard let htmlString = String(data: data, encoding: .utf8) else { return "" }

        do {
            let doc = try SwiftSoup.parse(htmlString)

            try doc.select("nav, footer, script, style, header, aside, form, noscript").remove()
            try doc.select("a[href*='pdf'], a[href*='download'], .references, .ref-list").remove()

            // Get main content first
            if let main = try? doc.select("main, article, .main-content, .article").first() {
                let mainText = try main.text()
                if !mainText.isEmpty {
                    return mainText
                }
            }
            // If unsuccesful, try to obtain body
            if let bodyText = try doc.body()?.text(), !bodyText.isEmpty {
                return bodyText
            }
        } catch {
            print("SwiftSoup HTML extraction failed: \(error)")
        }

        // If unsuccesful, fallback to regex-based parsing
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

    private func extractTextFromPlainText(_ data: Data) -> String {
        return String(data: data, encoding: .utf8) ?? ""
    }
}