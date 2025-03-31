//
//  SignUpView.swift
//  HealthPredictor
//
//  Created by Stephan  on 27.03.2025.
//

import SwiftUI

struct SignUpView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.crop.circle") // Placeholder logo
                .resizable()
                .frame(width: 60, height: 60)
                .padding(.bottom, 10)

            VStack(spacing: 5) {
                Text("Place where all your")
                    .font(.title3)
                    .foregroundColor(.primary)
                Text("Travels begin")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }

            VStack(spacing: 15) {
                TextField("First name", text: $firstName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                TextField("Last name", text: $lastName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }

            Text("At least 8 characters, containing a letter and a number")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.top, -10)

            Button(action: {
                // Sign up action
            }) {
                Text("Create account")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top)

            Text("By creating an account, you agree to our")
                .font(.footnote)
                .foregroundColor(.gray)

            HStack(spacing: 4) {
                Text("Terms of Service")
                    .font(.footnote)
                    .foregroundColor(.blue)
                Text("and")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Text("Privacy Policy.")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }

            Text("or")
                .padding(.top, 20)
                .foregroundColor(.gray)

            HStack(spacing: 20) {
                Image(systemName: "f.circle.fill") // Placeholder icons
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)

                Image("google_logo")
                    .resizable()
                    .frame(width: 40, height: 40)

                Image(systemName: "applelogo")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.black)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    SignUpView()
}
