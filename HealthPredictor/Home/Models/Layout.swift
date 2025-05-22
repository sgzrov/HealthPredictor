//
//  Layout.swift
//  HealthPredictor
//
//  Created by Stephan  on 08.04.2025.
//

import Foundation
import SwiftUI

public enum LayoutConstants {
    
    static func expandedSpacing(for containerHeight: CGFloat) -> CGFloat {
        let calculated = containerHeight * 0.012
        return round(calculated / 8) * 8
    }
}
