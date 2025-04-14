//
//  TimeSelectorView.swift
//  HealthPredictor
//
//  Created by Stephan  on 10.04.2025.
//

import SwiftUI

struct MenuSelectorView: View {
    @State private var selectedTab = "Health Summary"
    let tabs = ["Health Summary", "App Messages"]

    var body: some View {
        VStack {
            HStack(spacing: 20) {
                ForEach(tabs, id: \.self) { tab in
                    Button(action: {
                        withAnimation {
                            selectedTab = tab
                        }
                    }) {
                        Text(tab)
                            .font(.system(size: 14.5, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(selectedTab == tab ? Color.white : Color.clear)
                            )
                            .foregroundColor(selectedTab == tab ? Color.black : Color.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, LayoutConstants.cardPadding)
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    MenuSelectorView()
        .background(Color(hex: "#100c1c"))
}
