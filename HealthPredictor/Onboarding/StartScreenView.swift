//
//  StartScreenView.swift
//  HealthPredictor
//
//  Created by Stephan  on 27.03.2025.
//

import SwiftUI

struct StartScreenView: View {
    var body: some View {
        ZStack {
            BackgroundView()

            VStack {
                VStack {
                    Text("Take control of your health!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 100)
                }

                Spacer()

                VStack(spacing: 10) {
                    Button(action: {
                        // Apple Sign-in
                    }) {
                        HStack {
                            Image(systemName: "applelogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                            Text("Continue with Apple")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14.5)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                    }

                    Button(action: {
                        // Google Sign-in
                    }) {
                        HStack {
                            Image("icons8-google-48")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                            Text("Continue with Google")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14.5)
                        .background(Color(hex: "#302c2c"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                        Text("OR")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                    }

                    Button(action: {
                        // Navigate to Sign Up
                    }) {
                        Text("Sign up")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(14.5)
                            .foregroundColor(.white)
                            .background(Color(hex: "#302c2c"))
                            .cornerRadius(12)
                    }

                    Button(action: {
                        // Navigate to Sign In
                    }) {
                        Text("Continue with Email")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(14.5)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "#302c2c"), lineWidth: 1.5)
                            )
                    }
                }
                .padding(.top, 18.5)
                .padding(.horizontal, 16.5)
                .padding(.bottom)
                .background(Color(hex: "#201c1c"))
                .cornerRadius(32)
                .frame(maxWidth: .infinity)
                .offset(y: -4.6)
            }
            .padding()
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    StartScreenView()
}
