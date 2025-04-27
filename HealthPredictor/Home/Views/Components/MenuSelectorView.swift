//
//  TimeSelectorView.swift
//  HealthPredictor
//
//  Created by Stephan  on 10.04.2025.
//

import SwiftUI

struct MenuSelectorView: View {
    @State private var selectedTab = "Overview"
    @Namespace private var segmentNamespace
    let tabs = ["Overview", "History"]

    var body: some View {
        ZStack {
            // Background capsule
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(.secondarySystemFill))
                .frame(height: 40)

            // Button row with sliding capsule
            HStack(spacing: 2) {
                ForEach(tabs, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab)
                            .fontWeight(selectedTab == tab ? .medium : .medium)
                            .foregroundColor(selectedTab == tab ? .primary : .primary.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                Group {
                                    if selectedTab == tab {
                                        Capsule()
                                            .fill(Color(.tertiarySystemFill))
                                            .matchedGeometryEffect(id: "segment", in: segmentNamespace)
                                    }
                                }
                            )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

#Preview {
    MenuSelectorView()
        .preferredColorScheme(.dark)
        .background(Color(.systemBackground))
}
