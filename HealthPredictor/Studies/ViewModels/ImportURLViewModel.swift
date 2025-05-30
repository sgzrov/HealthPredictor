//
//  ImportURLViewModel.swift
//  HealthPredictor
//
//  Created by Stephan  on 28.05.2025.
//

import Foundation

@MainActor
class ImportURLViewModel: ObservableObject {

    @Published var importInput: String = ""
    @Published var errorMessage: String = ""
    @Published var isPDF: Bool = false
    @Published var isHTML: Bool = false
    @Published var isLoading: Bool = false

    private let urlStringCheck = URLStringCheck()
    private let urlExtensionCheck = URLExtensionCheck()

    func validateURL() {
        let result = urlStringCheck.validatePartialURL(importInput)
        errorMessage = result.errorMessage ?? ""
    }

    func validateFileType(url: URL) async {
        isLoading = true
        errorMessage = ""
        isPDF = false
        isHTML = false

        let result = await urlExtensionCheck.checkContentType(url: url)
        print("Content check result: \(result.type), error: \(result.error ?? "none")") // Debug print
        switch result.type {
        case .pdf:
            isPDF = true
        case .html:
            isHTML = true
        case .unknown:
            errorMessage = result.error ?? "Invalid URL. Content could not be inferred."
        }
        print("Set errorMessage to: \(errorMessage)") // Debug print
        isLoading = false
    }

    func isFullyValidURL() -> Bool {
        return urlStringCheck.validateURL(importInput).isValid
    }

    func clearInput() {
        importInput = ""
        errorMessage = ""
        isPDF = false
        isHTML = false
    }
}
