//
//  Tag.swift
//  HealthPredictor
//
//  Created by Stephan  on 27.05.2025.
//

import Foundation
import SwiftUI

struct Tag: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
}
