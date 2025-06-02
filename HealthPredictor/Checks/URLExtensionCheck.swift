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
        print("Starting content type check for URL: \(url.absoluteString)")

        do {
            let (data, response) = try await CloudflareCheck.shared.makeRequest(to: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid HTTP response")
                return fail()
            }

            let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""
            print("Received Content-Type: \(contentType)")
            print("HTTP status code: \(httpResponse.statusCode)")

            if contentType.contains("application/pdf") || url.pathExtension.lowercased() == "pdf" {
                print("Detected PDF by content-type or extension, attempting to load PDFDocument")
                let pdfResult = verifyPDF(data)
                if pdfResult.type == .pdf {
                    print("PDFDocument successfully loaded")
                    return pdfResult
                } else {
                    print("PDFDocument failed to initialize")
                }
            }

            // Try meta refresh if HTML
            if contentType.contains("text/html") || contentType.contains("application/xhtml+xml") {
                if let redirectedURL = extractMetaRefreshRedirect(from: data, originalURL: url) {
                    print("Found meta refresh redirect to: \(redirectedURL)")
                    return await checkContentType(url: redirectedURL) // recursive follow
                } else {
                    print("No meta refresh redirect found, treating as HTML")
                    return .init(type: .html, error: nil)
                }
            }

            return fail()
        } catch {
            print("Error during content check: \(error)")
            return fail()
        }
    }

    private func verifyPDF(_ data: Data) -> ContentTypeResult {
        if let _ = PDFDocument(data: data) {
            return .init(type: .pdf, error: nil)
        } else {
            return fail()
        }
    }

    private func extractMetaRefreshRedirect(from data: Data, originalURL: URL) -> URL? {
        guard let html = String(data: data, encoding: .utf8) else {
            print("Failed to decode HTML from data")
            return nil
        }

        do {
            let doc = try SwiftSoup.parse(html)
            let meta = try doc.select("meta[http-equiv=refresh]").first()
            if let content = try meta?.attr("content") {
                print("Meta refresh content: \(content)")
                if let range = content.range(of: "url=", options: .caseInsensitive) {
                    let urlPart = content[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                    let resolved = URL(string: urlPart, relativeTo: originalURL)?.absoluteURL
                    return resolved
                }
            }
        } catch {
            print("Failed to parse meta refresh tag: \(error)")
        }

        return nil
    }

    private func fail() -> ContentTypeResult {
        print("Returning failure result")
        return .init(type: .unknown, error: "Invalid URL. Content could not be inferred.")
    }
}

