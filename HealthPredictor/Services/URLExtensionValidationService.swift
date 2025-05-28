//
//  URLExtensionValidationServices.swift
//  HealthPredictor
//
//  Created by Stephan  on 28.05.2025.
//

import Foundation
import PDFKit
import SwiftSoup

@MainActor
class URLExtensionValidationServices {
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
        // Check file extension first
        if url.pathExtension.lowercased() == "pdf" {
            return ContentTypeResult(type: .pdf, error: nil)
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            // Check content type from response
            if let httpResponse = response as? HTTPURLResponse,
               let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")?.lowercased() {
                if contentType.contains("application/pdf") {
                    return ContentTypeResult(type: .pdf, error: nil)
                }
                if contentType.contains("text/html") || contentType.contains("application/xhtml+xml") {
                    return ContentTypeResult(type: .html, error: nil)
                }
            }

            // If still not determined, try parsing
            if PDFDocument(data: data) != nil {
                return ContentTypeResult(type: .pdf, error: nil)
            }

            // Try parsing as HTML
            if let htmlString = String(data: data, encoding: .utf8) {
                do {
                    _ = try SwiftSoup.parse(htmlString)
                    return ContentTypeResult(type: .html, error: nil)
                } catch {
                    return ContentTypeResult(type: .unknown, error: "Invalid HTML content")
                }
            }

            return ContentTypeResult(type: .unknown, error: "Could not determine content type")
        } catch {
            return ContentTypeResult(type: .unknown, error: "Failed to verify content type: \(error.localizedDescription)")
        }
    }
}
