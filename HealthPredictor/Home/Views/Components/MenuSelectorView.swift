//
//  TimeSelectorView.swift
//  HealthPredictor
//
//  Created by Stephan  on 10.04.2025.
//

import SwiftUI

struct MenuSelectorView: View {
    @State private var selectedTab = "Health Monitor"
    let tabs = ["Health Monitor", "Messages"]

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
                            .font(.system(size: 14, weight: .medium))
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
            .padding(.top, 15)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    MenuSelectorView()
        .background(Color(hex: "#100c1c"))
}
