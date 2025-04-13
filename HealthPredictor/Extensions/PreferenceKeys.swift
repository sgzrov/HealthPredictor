//
//  PreferenceKeys.swift
//  HealthPredictor
//
//  Created by Stephan  on 08.04.2025.
//

import Foundation
import SwiftUI

struct CardPosition: Equatable {
    let id: String
    let frame: CGRect

    static func == (lhs: CardPosition, rhs: CardPosition) -> Bool {
        lhs.id == rhs.id && lhs.frame == rhs.frame
    }
}

struct CardPositionPreferenceKey: PreferenceKey {
    static var defaultValue: [CardPosition] = []

    static func reduce(value: inout [CardPosition], nextValue: () -> [CardPosition]) {
        value.append(contentsOf: nextValue())
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}