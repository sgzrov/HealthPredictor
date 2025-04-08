//
//  Color+Hex.swift
//  HealthPredictor
//
//  Created by Stephan  on 27.03.2025.
//

import SwiftUI

enum Direction {
    case upward
    case downward
    case leftward
    case rightward
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)

        let redComponent = Double((int >> 16) & 0xFF) / 255
        let greenComponent = Double((int >> 8) & 0xFF) / 255
        let blueComponent = Double(int & 0xFF) / 255

        self.init(red: redComponent, green: greenComponent, blue: blueComponent)
    }
}
