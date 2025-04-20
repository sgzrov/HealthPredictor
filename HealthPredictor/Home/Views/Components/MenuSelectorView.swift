//
//  TimeSelectorView.swift
//  HealthPredictor
//
//  Created by Stephan  on 10.04.2025.
//

import SwiftUI

struct MenuSelectorView: View {
    @State private var selectedTab = "Overview"
    let tabs = ["Overview", "Messages"]

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                // Background capsule
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white.opacity(0.1))

                HStack(spacing: 8) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 105, height: 30)
                        .offset(x: selectedTab == tabs[0] ? 5 : 5 + 105 + 8)

                    Spacer()
                }
                
                // Buttons
                HStack(spacing: 8) {
                    ForEach(tabs, id: \.self) { tab in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                selectedTab = tab
                            }
                        } label: {
                            Text(tab)
                                .font(.system(size: 14.5, weight: selectedTab == tab ? .semibold : .medium))
                                .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.7))
                                .frame(width: 105, height: 30)
                        }
                    }
                }
            }
            .frame(width: 228, height: 38)
        }
        .padding(.horizontal, LayoutConstants.cardPadding)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    MenuSelectorView()
        .background(Color(hex: "#100c1c"))
}
