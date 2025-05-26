//
//  StudyImportViewModel.swift
//  HealthPredictor
//
//  Created by Stephan  on 25.05.2025.
//

import Foundation
import Combine

class StudiesImportViewModel: ObservableObject {

    @Published var importInput: String = ""
    @Published var errorMessage: String = ""

    private let invalidURLCharacters = CharacterSet(charactersIn: "<>{}|")
    private let commonTLDs = ["com", "org", "net", "edu", "gov", "io", "co", "ai", "app", "dev", "health", "research",
    "us", "uk", "de", "fr", "ca", "au", "nz", "se", "no", "fi", "nl", "ch", "it", "es", "dk", "ie", "be", "at", "jp", "kr", "sg",
    "in", "br", "mx", "za", "is", "cz", "pl", "il", "gr", "ru", "ua", "pt", "ar", "tr", "cl", "my", "th", "hk", "ae"]
    private var validationTimer: Timer?

    var isValidURL: Bool {
        let trimmed = importInput.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for https://
        guard trimmed.lowercased().hasPrefix("https://") else {
            setError("Invalid URL. Try again.")
            return false
        }

        // Check for periods
        let afterProtocol = trimmed.dropFirst(8)
        let periodCheck = afterProtocol.components(separatedBy: ".")
        guard periodCheck.count >= 2,
              !periodCheck.contains(where: { $0.isEmpty }),
              !afterProtocol.hasSuffix("."),
              !afterProtocol.hasPrefix("."),
              !afterProtocol.contains("..") else {
            setError("Invalid URL. Try again.")
            return false
        }

        // Character validation
        guard !trimmed.contains(" "),
              trimmed.rangeOfCharacter(from: invalidURLCharacters) == nil else {
            setError("Invalid URL. Try again.")
            return false
        }

        // URL parsing and host validation
        guard let url = URL(string: trimmed),
              let host = url.host,
              !host.isEmpty else {
            setError("Invalid URL. Try again.")
            return false
        }

        // Domain structure validation
        let components = host.components(separatedBy: ".")
        guard components.count >= 2 else {
            setError("Invalid URL. Try again.")
            return false
        }

        // TLD validation
        let tld = components.last?.lowercased() ?? ""
        guard commonTLDs.contains(tld) else {
            setError("Invalid URL. Try again.")
            return false
        }

        clearError()
        return true
    }

    func validateURL() {
        validationTimer?.invalidate()

        let trimmed = importInput.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            clearError()
            return
        }

        clearError()

        // Check for partial https:// input
        let httpsPrefix = "https://"
        if trimmed.count <= httpsPrefix.count {
            let currentPrefix = trimmed.lowercased()
            if httpsPrefix.hasPrefix(currentPrefix) {
                return
            }
        }

        // Immediate error for non-https URLs
        if !trimmed.lowercased().hasPrefix("https://") {
            setError("Invalid URL. Try again.")
            return
        }

        // Schedule validation for other checks
        validationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if !self.isValidURL {
                self.setError("Invalid URL. Try again.")
            }
        }
    }

    private func setError(_ message: String) {
        errorMessage = message
    }

    private func clearError() {
        errorMessage = ""
    }
}
