//
//  Study.swift
//  HealthPredictor
//
//  Created by Stephan  on 05.06.2025.
//

import Foundation
import SwiftUI

class Study: Identifiable, Hashable, Codable, ObservableObject {

    let id: UUID
    let importDate: Date
    let sourceURL: URL

    @Published var title: String
    @Published var summary: String
    @Published var personalizedInsight: String

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

    // Codable conformance for @Published properties
    enum CodingKeys: String, CodingKey {
        case id, title, summary, personalizedInsight, importDate, sourceURL
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        summary = try container.decode(String.self, forKey: .summary)
        personalizedInsight = try container.decode(String.self, forKey: .personalizedInsight)
        importDate = try container.decode(Date.self, forKey: .importDate)
        sourceURL = try container.decode(URL.self, forKey: .sourceURL)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(summary, forKey: .summary)
        try container.encode(personalizedInsight, forKey: .personalizedInsight)
        try container.encode(importDate, forKey: .importDate)
        try container.encode(sourceURL, forKey: .sourceURL)
    }
}
