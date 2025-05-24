//
//  StudiesHomeView.swift
//  HealthPredictor
//
//  Created by Stephan  on 24.05.2025.
//

import SwiftUI

struct StudiesHomeView: View {

   @State private var searchText: String = ""

   var body: some View {
       ZStack {
           Color(.systemGroupedBackground).ignoresSafeArea()
           VStack(alignment: .leading, spacing: 14) {

               HStack {
                   Button(action: {
                       // Edit action
                   }) {
                       Text("Edit")
                   }

                   Spacer()

                   Button(action: {
                       // Plus action
                   }) {
                       ZStack {
                           Circle()
                               .fill(Color(.secondarySystemFill))
                               .frame(width: 24, height: 24)
                           Image(systemName: "plus")
                               .resizable()
                               .frame(width: 12, height: 12)
                               .foregroundColor(Color(.systemGroupedBackground))
                       }
                   }
               }

               VStack(alignment: .leading, spacing: 10) {
                   Text("Studies")
                       .font(.largeTitle)
                       .fontWeight(.bold)
                       .foregroundColor(.primary)

                   HStack(spacing: 8) {
                       HStack(spacing: 4) {
                           Image(systemName: "magnifyingglass")
                               .foregroundColor(Color(.tertiaryLabel))
                           TextField("Search", text: $searchText)
                       }
                       .padding(6)
                       .background(Color(.secondarySystemFill))
                       .cornerRadius(10)
                       .frame(maxWidth: .infinity)

                       Button(action: {
                           // Filter action
                       }) {
                           Image(systemName: "line.3.horizontal.decrease")
                       }
                   }
               }

               HStack(spacing: 8) {
                   Text("Imported")
                       .font(.subheadline)
                       .fontWeight(.medium)
                       .foregroundColor(.primary.opacity(0.5))
                       .padding(.horizontal, 12)
                       .padding(.vertical, 8)
                       .background(Color(.secondarySystemFill))
                       .cornerRadius(16)

                   Text("Recommmended")
                       .font(.subheadline)
                       .fontWeight(.medium)
                       .foregroundColor(.primary.opacity(0.5))
                       .padding(.horizontal, 12)
                       .padding(.vertical, 8)
                       .background(Color(.secondarySystemFill))
                       .cornerRadius(16)

                   Text("All")
                       .font(.subheadline)
                       .fontWeight(.medium)
                       .foregroundColor(.primary.opacity(0.5))
                       .padding(.horizontal, 12)
                       .padding(.vertical, 8)
                       .background(Color(.secondarySystemFill))
                       .cornerRadius(16)
               }
               .padding(.vertical, 2)
               Spacer()
           }
           .padding(.horizontal, 16)
       }
   }
}

#Preview {
    StudiesHomeView()
}
