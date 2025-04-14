//
//  GreetingView.swift
//  HealthPredictor
//
//  Created by Stephan  on 08.04.2025.
//

import SwiftUI

struct GreetingView: View {

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome back,")
                    .font(.footnote)
                    .foregroundColor(.gray)

                Text("Stephan")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)

                Image(systemName: "person.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
            }
            .alignmentGuide(.lastTextBaseline) { dimensions in dimensions[.bottom] - 3}
        }
        .padding(.horizontal, LayoutConstants.leadingPadding)
    }
}

#Preview {
    GreetingView()
}
