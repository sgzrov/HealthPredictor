//
//  URLExtensionCheck.swift
//  HealthPredictor
//
//  Updated for meta-refresh redirect support
//

import Foundation
import PDFKit
import SwiftSoup

class URLExtensionCheck {

    enum ContentType {
        case pdf
        case html
        case unknown
    }

    struct ContentTypeResult {
        let type: ContentType
        let error: String?
    }

    func checkContentType(url: URL) async -> ContentTypeResult {
        if url.isFileURL {
            let data: Data
            
            do {
                data = try Data(contentsOf: url)
            } catch {
                return .init(type: .unknown, error: "Could not read local file.")
            }

            if PDFDocument(data: data) != nil {
                return .init(type: .pdf, error: nil)
            } else {
                return .init(type: .unknown, error: "Local file is not a valid PDF.")
            }
        }

        do {
            let (data, response) = try await CloudflareCheck.shared.makeRequest(to: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                return fail()
            }

            let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""

            // Check if content-type is PDF
            if contentType.contains("application/pdf") || url.pathExtension.lowercased() == "pdf" {
                if let pdfDoc = PDFDocument(data: data), pdfDoc.pageCount > 0 {
                    return .init(type: .pdf, error: nil)
                } else {
                    print("PDFDocument failed to initialize or has no pages.")
                }
            }

            // For PDF links that are not immediately downloadable
            if (url.pathExtension.lowercased() == "pdf" || contentType.contains("application/pdf")) && isParsableHTML(data: data) {
                return .init(type: .html, error: "Could not access PDF. Try uploading file from Files.")
            }

            // Check if content-type is HTML
            if contentType.contains("text/html") || contentType.contains("application/xhtml+xml") || isParsableHTML(data: data) {
                return .init(type: .html, error: nil)
            }

            return fail()

        } catch {
            return fail()
        }
    }

    private func isParsableHTML(data: Data) -> Bool {
        guard let htmlString = String(data: data, encoding: .utf8) else {
            return false
        }
        return (try? SwiftSoup.parse(htmlString)) != nil
    }

    private func fail() -> ContentTypeResult {
        return .init(type: .unknown, error: "Invalid URL. Content could not be inferred.")
    }
}
