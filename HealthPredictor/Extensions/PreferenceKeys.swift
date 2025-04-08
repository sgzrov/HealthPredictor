//
//  PreferenceKeys.swift
//  HealthPredictor
//
//  Created by Stephan  on 08.04.2025.
//

import Foundation
import SwiftUI

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}