//
//  TagView.swift
//  HealthPredictor
//
//  Created by Stephan  on 27.05.2025.
//

import SwiftUI

struct TagView: View {
    let tag: Tag

    var body: some View {
        Text(tag.name)
            .font(.footnote)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(tag.color.opacity(0.15))
            .foregroundColor(tag.color)
            .clipShape(Capsule())
    }
}

#Preview {
    TagView(tag: Tag(name: "Calories", color: .red))
}
