//
//  HealthCard.swift
//  HealthPredictor
//
//  Created by Stephan  on 02.04.2025.
// The core data model representing each health card in the app.

import Foundation
import SwiftUI

struct HealthCard: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let emoji: String
    let value: Int
    let goal: Int
    let metric: String
    let cardColor: Color
    let otherColor: Color
}
