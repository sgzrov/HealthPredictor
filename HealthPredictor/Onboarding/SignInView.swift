//
//  SignInView.swift
//  HealthPredictor
//
//  Created by Stephan  on 27.03.2025.
//

import SwiftUI

struct SignInView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    
    
    var body: some View {
        VStack (spacing: 20) {
            Spacer()
            
            Image(systemName: "circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.black)
            
            Text("Sign In to Continue")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Email and Password
            VStack(spacing: 12) {
                TextField("Email address", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            }
            
            // Or continue with
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
                // Handle Apple Sign In
            }) {
                HStack {
                    Image(systemName: "applelogo")
                    Text("Continue with Apple")
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
            }
            
            Button(action: {
                // Handle Google Sign In
            }) {
                HStack {
                    Image(systemName: "globe")
                    Text("Continue with Google")
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
            }
            
            Button(action: {
                // Handle forgot password
            }) {
                Text("Forgot password?")
                    .font(.caption)
                    .underline()
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
            }
            
            Button(action: {
                // Handle sign-in
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
            }
            
            Spacer()
            
            // Sign up
            HStack(spacing: 4) {
                Text("Not a member?")
                    .foregroundColor(.black)
                Button(action: {
                    // Navigate to Sign Up
                }) {
                    Text("Create an account")
                        .underline()
                        .foregroundColor(.black)
                        .fontWeight(.medium)
                }
            }
            
        .padding(.horizontal)
            Spacer()
            
            Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.horizontal)
    }
}

#Preview {
    SignInView()
}
