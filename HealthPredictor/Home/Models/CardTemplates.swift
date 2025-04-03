//
//  CardTemplateModel.swift
//  HealthPredictor
//
//  Created by Stephan  on 02.04.2025.
//

import Foundation
import SwiftUI

struct CardTemplates {
    
    static let heartRate = HealthCard(
        title: "Heart Rate",
        emoji: "❤️",
        value: 65,
        goal: 80,
        metric: "bpm",
        cardColor: Color(hex: "#f0fc4c"),
        otherColor: Color(hex: "#0c0804")
    )
    
    static let activeTime = HealthCard(
        title: "Active Time",
        emoji: "⏰",
        value: 45,
        goal: 60,
        metric: "minutes",
        cardColor: Color(hex: "#1c1b20"),
        otherColor: Color.white
    )

    static let calories = HealthCard(
        title: "Calories",
        emoji: "🔥",
        value: 600,
        goal: 1000,
        metric: "kcal",
        cardColor: Color(hex: "#b0f6f0"),
        otherColor: Color(hex: "#0c0804")
    )

    static let sleep = HealthCard(
        title: "Sleep",
        emoji: "😴",
        value: 6,
        goal: 8,
        metric: "hours",
        cardColor: Color(hex: "#c5baff"),
        otherColor: Color(hex: "#0c0804")
    )

}
