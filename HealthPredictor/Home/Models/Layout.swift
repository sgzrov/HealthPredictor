//
//  Layout.swift
//  HealthPredictor
//
//  Created by Stephan  on 08.04.2025.
//

import Foundation
import SwiftUI

public enum LayoutConstants {
    public static let sectionSpacing: CGFloat = 21
    public static let headerToContent: CGFloat = 14
    public static let headerToScrollableContent: CGFloat = 6
    public static let leadingPadding: CGFloat = 22
    public static let buttonPadding: CGFloat = 5
    public static let cardPadding: CGFloat = 12
    public static let horizontalPadding: CGFloat = 15
    public static let greetingPadding: CGFloat = 30

    enum Card {
        static let defaultHeight: CGFloat = 136
        static let expandedMultiplier: CGFloat = 3
        static let spacing: CGFloat = 12
        static let cornerRadius: CGFloat = 30
        static let contentPadding: CGFloat = 20

        static func height(for containerHeight: CGFloat) -> CGFloat {
            return containerHeight * 0.146
        }
        static func spacing(for containerHeight: CGFloat) -> CGFloat {
            return containerHeight * 0.015
        }
        static func expandedChartHeight(for containerHeight: CGFloat) -> CGFloat {
            return containerHeight * 0.23
        }
        static func expandedSpacing(for containerHeight: CGFloat) -> CGFloat {
            return containerHeight * 0.017
        }
    }
}
