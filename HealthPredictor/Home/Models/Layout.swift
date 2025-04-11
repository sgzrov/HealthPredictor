//
//  Layout.swift
//  HealthPredictor
//
//  Created by Stephan  on 08.04.2025.
//

import Foundation
import SwiftUI

public enum LayoutConstants {
    public static let sectionSpacing: CGFloat = 28
    public static let headerToContent: CGFloat = 12
    public static let leadingPadding: CGFloat = 25
    public static let buttonPadding: CGFloat = 5
    public static let cardPadding: CGFloat = 12
    public static let horizontalPadding: CGFloat = 15

    enum Card {
        static let defaultHeight: CGFloat = 136
        static let expandedMultiplier: CGFloat = 3
        static let spacing: CGFloat = 12
        static let cornerRadius: CGFloat = 30
        static let contentPadding: CGFloat = 20

        static func height(for containerHeight: CGFloat) -> CGFloat {
            return containerHeight * 0.147
        }
        static func spacing(for containerHeight: CGFloat) -> CGFloat {
            return containerHeight * 0.015
        }
    }
}
