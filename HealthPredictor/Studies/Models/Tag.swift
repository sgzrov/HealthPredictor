//
//  Tag.swift
//  HealthPredictor
//
//  Created by Stephan  on 27.05.2025.
//

import Foundation
import SwiftUI

struct Tag: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color

    static let healthKeywords: [Tag] = [
        Tag(name: "Heart", color: .red),
        Tag(name: "Activity", color: .green),
        Tag(name: "Sleep", color: .blue),
        Tag(name: "Calorie", color: .yellow),
        Tag(name: "Water", color: .cyan),
        Tag(name: "Mind", color: .purple),
        Tag(name: "Weight", color: .pink)
    ]
}
