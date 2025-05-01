//
//  Layout.swift
//  HealthPredictor
//
//  Created by Stephan  on 08.04.2025.
//

import Foundation
import SwiftUI

public enum LayoutConstants {
    // Base spacing following 8-point grid
    public static let sectionSpacing: CGFloat = 24      // Was 21
    public static let headerToContent: CGFloat = 16     // Was 14
    public static let headerToScrollableContent: CGFloat = 8  // Was 6
    public static let leadingPadding: CGFloat = 24      // Was 22
    public static let buttonPadding: CGFloat = 8        // Was 5
    public static let cardPadding: CGFloat = 12         // Good (8 + 4)
    public static let horizontalPadding: CGFloat = 16   // Was 15
    public static let greetingPadding: CGFloat = 32     // Was 30

    enum Card {
        static let defaultHeight: CGFloat = 136 // Multiple of 8 (17 * 8)
        static let expandedMultiplier: CGFloat = 3
        static let spacing: CGFloat = 8
        static let cornerRadius: CGFloat = 32 // Was 30
        static let contentPadding: CGFloat = 16 // Was 20

        /// Rounds the calculated height to the nearest 8-point grid value
        static func height(for containerHeight: CGFloat) -> CGFloat {
            let calculated = containerHeight * 0.143
            return round(calculated / 8) * 8
        }

        /// Ensures spacing aligns with 8-point grid, with option for 4-point adjustment
        static func spacing(for containerHeight: CGFloat) -> CGFloat {
            let baseSpacing = containerHeight * 0.0115
            let roundedToGrid = round(baseSpacing / 8) * 8
            return roundedToGrid + 4 // Adding half-grid (4pt) for fine-tuning
        }

        /// Rounds expanded chart height to nearest 8-point grid value
        static func expandedChartHeight(for containerHeight: CGFloat) -> CGFloat {
            let calculated = containerHeight * 0.23
            return round(calculated / 8) * 8
        }

        /// Ensures expanded spacing aligns with 8-point grid
        static func expandedSpacing(for containerHeight: CGFloat) -> CGFloat {
            let calculated = containerHeight * 0.012
            return round(calculated / 8) * 8
        }
    }
}
