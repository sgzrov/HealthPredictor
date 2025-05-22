//
//  HealthCard.swift
//  HealthPredictor
//
//  Created by Stephan  on 02.04.2025.
// The core data model representing each health card in the app.

import Foundation
import SwiftUI

enum HealthCardType {
    case heartRate
    case heartRateVariability
    case caloriesBurnt
    case steps
    case standHours
    case activeTime
    case water
    case sleepDurationQuality
    case mindfulMinutes
}

struct HealthCard: Identifiable, Equatable, Hashable {
    let id = UUID()
    let title: String
    let emoji: String
    let value: Int
    let goal: Int
    let metric: String
    let cardColor: Color
    let otherColor: Color
    let summary: String
    let type: HealthCardType

    static var heartRate: HealthCard {
        HealthCard(
            title: "Heart rate",
            emoji: "❤️",
            value: 65,
            goal: 80,
            metric: "bpm",
            cardColor: Color(hex: "#f0fc4c"),
            otherColor: .black,
            summary: "Your heart rate has been stable. Keep maintaining a regular exercise routine to maintain this healthy pattern.",
            type: .heartRate
        )
    }

    static var heartRateVariability: HealthCard {
        HealthCard(
            title: "Heart Rate Variability",
            emoji: "💓",
            value: 50,
            goal: 60,
            metric: "ms",
            cardColor: Color(hex: "#ff6b6b"),
            otherColor: .white,
            summary: "Your heart rate variability is within normal range. Regular exercise and stress management can help maintain this pattern.",
            type: .heartRateVariability
        )
    }

    static var caloriesBurnt: HealthCard {
        HealthCard(
            title: "Calories Burnt",
            emoji: "🔥",
            value: 600,
            goal: 1000,
            metric: "kcal",
            cardColor: Color(hex: "#98fcec"),
            otherColor: Color(hex: "#0c0804"),
            summary: "Your calorie burn is on track. Keep up the physical activity to maintain this healthy pattern.",
            type: .caloriesBurnt
        )
    }

    static var steps: HealthCard {
        HealthCard(
            title: "Steps",
            emoji: "🚶‍♂️",
            value: 10000,
            goal: 15000,
            metric: "steps",
            cardColor: Color(hex: "#fce6e6"),
            otherColor: Color(hex: "#0c0804"),
            summary: "Your step count has been stable. Keep maintaining a regular exercise routine to maintain this healthy pattern.",
            type: .steps
        )
    }

    static var standHours: HealthCard {
        HealthCard(
            title: "Stand Hours",
            emoji: "🧍",
            value: 8,
            goal: 12,
            metric: "hours",
            cardColor: Color(hex: "#a8e6cf"),
            otherColor: Color(hex: "#0c0804"),
            summary: "You're doing well with standing time. Try to maintain regular breaks from sitting throughout the day.",
            type: .standHours
        )
    }

    static var activeTime: HealthCard {
        HealthCard(
            title: "Active time",
            emoji: "⏰",
            value: 45,
            goal: 60,
            metric: "minutes",
            cardColor: Color(hex: "#1c1b20"),
            otherColor: .white,
            summary: "You're close to your daily activity goal. A short walk could help you reach your target.",
            type: .activeTime
        )
    }

    static var water: HealthCard {
        HealthCard(
            title: "Water",
            emoji: "💧",
            value: 2,
            goal: 3,
            metric: "liters",
            cardColor: Color(hex: "#e6f2ff"),
            otherColor: Color(hex: "#0c0804"),
            summary: "Your health has been getting worse. This is due to the fact that you drink less water. To better your hydration and health, increase your dosage of water to 1 liter a day.",
            type: .water
        )
    }

    static var sleepDurationQuality: HealthCard {
        HealthCard(
            title: "Sleep Quality",
            emoji: "😴",
            value: 7,
            goal: 8,
            metric: "hours",
            cardColor: Color(hex: "#c5baff"),
            otherColor: Color(hex: "#0c0804"),
            summary: "Your sleep duration and quality are good. Maintain a consistent sleep schedule for optimal health.",
            type: .sleepDurationQuality
        )
    }

    static var mindfulMinutes: HealthCard {
        HealthCard(
            title: "Mindful Minutes",
            emoji: "🧘",
            value: 10,
            goal: 15,
            metric: "minutes",
            cardColor: Color(hex: "#ffd3b6"),
            otherColor: Color(hex: "#0c0804"),
            summary: "Your mindfulness practice is beneficial. Consider increasing your daily meditation time for better stress management.",
            type: .mindfulMinutes
        )
    }

    static var all: [HealthCard] {
        [heartRate, heartRateVariability, caloriesBurnt, steps, standHours, activeTime, water, sleepDurationQuality, mindfulMinutes]
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
