//
//  ShakEffect.swift
//  HealthPredictor
//
//  Created by Stephan  on 27.05.2025.
//

import Foundation
import SwiftUI

public struct ShakeEffect: GeometryEffect {
    public var shakes: CGFloat
    public var amplitude: CGFloat = 4
    public var damping: CGFloat = 0.4

    public var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    public func effectValue(size: CGSize) -> ProjectionTransform {
        let progress = shakes.truncatingRemainder(dividingBy: 1)
        let decay = exp(-Double(damping) * Double(progress) * 10)
        let translation = amplitude * CGFloat(decay) * sin(progress * .pi * 8)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }

    public init(shakes: CGFloat, amplitude: CGFloat = 4, damping: CGFloat = 0.25) {
        self.shakes = shakes
        self.amplitude = amplitude
        self.damping = damping
    }
}
