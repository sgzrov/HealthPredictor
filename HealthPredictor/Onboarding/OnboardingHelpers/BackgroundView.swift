//
//  AnimatedGradientBackgroundView.swift
//  HealthPredictor
//
//  Created by Stephan  on 28.03.2025.
//

import SwiftUI

struct BackgroundView: View {
    @State private var currentIndex = 0

    let gradients: [[Color]] = [
        [Color.orange.opacity(0.8), Color.pink.opacity(0.8)],
        [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
        [Color.green.opacity(0.8), Color.yellow.opacity(0.8)],
        [Color.blue.opacity(0.8), Color.cyan.opacity(0.8)],
        [Color.purple.opacity(0.8), Color.indigo.opacity(0.8)],
        [Color.mint.opacity(0.8), Color.cyan.opacity(0.8)]
    ]

    var body: some View {
        ZStack {
            ForEach(gradients.indices, id: \.self) { index in
                LinearGradient(
                    colors: gradients[index],
                    startPoint: .topLeading,
                    endPoint: UnitPoint(x: 0.85, y: 0.5)
                )
                .opacity(currentIndex == index ? 1 : 0)
                .animation(.easeInOut(duration: 3), value: currentIndex)
                .transition(.opacity)
                .opacity(0.9)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 2)) {
                    currentIndex = (currentIndex + 1) % gradients.count
                }
            }
        }
    }
}

#Preview {
    BackgroundView()
}
