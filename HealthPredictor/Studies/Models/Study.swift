//
//  Study.swift
//  HealthPredictor
//
//  Created by Stephan  on 05.06.2025.
//

import Foundation
import SwiftUI

struct Study: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let summary: String
    let personalizedInsight: String
    let importDate: Date
    let sourceURL: URL

    init(id: UUID = UUID(), title: String, summary: String, personalizedInsight: String, sourceURL: URL) {
        self.id = id
        self.title = title
        self.summary = summary
        self.personalizedInsight = personalizedInsight
        self.importDate = Date()
        self.sourceURL = sourceURL
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Study, rhs: Study) -> Bool {
        lhs.id == rhs.id
    }
}
