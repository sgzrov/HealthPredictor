//
//  MainTabView.swift
//  HealthPredictor
//
//  Created by Stephan  on 01.04.2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.black.opacity(0.8), for: .tabBar)
    }
}

#Preview {
    MainTabView()
}
