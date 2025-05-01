//
//  AnimatedMeshView.swift
//  HealthPredictor
//
//  Created by Stephan  on 29.04.2025.
//

import SwiftUI

struct AnimatedMeshView: View {

    @State private var appear = false
    @State private var appear2 = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [appear2 ? 0.5 : 1.0, 0.0], [1.0, 0.0],
                [0.0, 0.5], appear ? [0.1, 0.5] : [0.8, 0.2], [1.0, -0.5],
                [0.0, 1.0], [1.0, appear2 ? 2.0 : 1.0], [1.0, 1.0]
        ], colors: [
            appear2 ? .red : .mint, appear2 ? .yellow : .cyan, .orange,
            appear ? .blue : .red, appear ? .cyan : .white, appear ? .red : .purple,
            appear ? .red : .cyan, appear ? .mint : .blue, appear2 ? .red : .blue
        ])
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                appear.toggle()
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                appear2.toggle()
            }
        }
    }
}

#Preview {
    AnimatedMeshView()
        .ignoresSafeArea()
}
