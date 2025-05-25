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

    var isURL: Bool {
        if let url = URL(string: importInput.trimmingCharacters(in: .whitespacesAndNewlines)),
           url.scheme == "http" || url.scheme == "https" {
            return true
        }
        return false
    }
    
    var isPossiblyTypingURL: Bool {
        let trimmed = importInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.hasPrefix("http") || trimmed.hasPrefix("https")
    }

    var isText: Bool {
        !isURL && !isPossiblyTypingURL && importInput.trimmingCharacters(in: .whitespacesAndNewlines).count > 0
    }
}
