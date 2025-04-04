//
//  CardTemplateModel.swift
//  HealthPredictor
//
//  Created by Stephan  on 02.04.2025.

// Stores reusable and styled default instances of HealthCard.

import Foundation
import SwiftUI

struct CardTemplates {
    
    static let heartRate = HealthCard(
        title: "Heart rate",
        emoji: "❤️",
        value: 65,
        goal: 80,
        metric: "bpm",
        cardColor: Color(hex: "#f0fc4c"),
        otherColor: Color(hex: "#0c0804")
    )
    
    static let activeTime = HealthCard(
        title: "Active time",
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
        cardColor: Color(hex: "#98fcec"),
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
    
    static let water = HealthCard(
        title: "Water",
        emoji: "💧",
        value: 2,
        goal: 3,
        metric: "liters",
        cardColor: Color(hex: "#e6f2ff"),
        otherColor: Color(hex: "#0c0804")
    )
    
    static let steps = HealthCard(
        title: "Steps",
        emoji: "🚶‍♂️",
        value: 10000,
        goal: 15000,
        metric: "steps",
        cardColor: Color(hex: "#fce6e6"),
        otherColor: Color(hex: "#0c0804")
    )
    
    static let all: [HealthCard] = [heartRate, activeTime, calories, sleep, water, steps]
}
