//
//  GreetingView.swift
//  HealthPredictor
//
//  Created by Stephan  on 08.04.2025.
//

import SwiftUI

struct GreetingView: View {

    var body: some View {
        VStack(alignment: .leading) {
            Text("Hello, Max")
            .font(.largeTitle)
            .bold()
            .foregroundColor(.white)

            Text("Let's check how you feel today")
            .font(.footnote)
            .foregroundColor(.gray)
        }
        .padding(.leading, LayoutConstants.leadingPadding)
        .padding(.bottom, LayoutConstants.greetingPadding)
    }
}

#Preview {
    GreetingView()
}
