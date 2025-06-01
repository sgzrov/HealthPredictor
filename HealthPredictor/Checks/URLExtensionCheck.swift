//
//  URLExtensionCheck.swift
//  HealthPredictor
//
//  Created by Stephan  on 28.05.2025.
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
        do {
            let (data, response) = try await CloudflareCheck.shared.makeRequest(to: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                return fail()
            }

            let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""

            // Check for PDF first, regardless of Cloudflare status
            if contentType.contains("application/pdf") || url.pathExtension.lowercased() == "pdf" {
                return .init(type: .pdf, error: nil)
            }

            // Then check for Cloudflare protection
            if CloudflareCheck.shared.isCloudflareProtected(response) {
                return isHTMLContent(contentType, data: data)
            }

            guard httpResponse.statusCode == 200 else {
                return fail()
            }

            return isHTMLContent(contentType, data: data)
        } catch {
            return fail()
        }
    }

    private func isHTMLContent(_ contentType: String, data: Data) -> ContentTypeResult {
        if contentType.contains("text/html") || contentType.contains("application/xhtml+xml") {
            return .init(type: .html, error: nil)
        }

        if isParsableHTML(data: data) {
            return .init(type: .html, error: nil)
        }

        return fail()
    }

    private func verifyPDF(_ data: Data) -> ContentTypeResult {
        PDFDocument(data: data) != nil ? .init(type: .pdf, error: nil) : fail()
    }

    private func isParsableHTML(data: Data) -> Bool {
        guard let htmlString = String(data: data, encoding: .utf8) else { return false }
        return (try? SwiftSoup.parse(htmlString)) != nil
    }

    private func fail() -> ContentTypeResult {
        .init(type: .unknown, error: "Invalid URL. Content could not be inferred.")
    }
}
