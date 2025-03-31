import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(alignment: .leading) {

                VStack(alignment: .leading) {
                    Text("Hello, Max")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.primary)
                    
                    Text("Let's check how you feel today")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 25)
                
                Spacer().frame(height: 30)
                
                Text("Today's goals")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.primary)
                    .padding(.horizontal, 25)

                VStack(spacing: 10) {
                    HealthCardView(title: "Heart rate", emoji: "❤️", value: 65, goal: 82, metric: "bpm", cardColor: Color(hex: "#f0fc4c"), otherColor: Color(hex: "#0c0804"))

                    HealthCardView(title: "Active time", emoji: "⏰", value: 140, goal: 145, metric: "minutes", cardColor: Color(hex: "#28242c"), otherColor: Color(hex: "#fcfcfc"))

                    HealthCardView(title: "Calories", emoji: "🔥", value: 450, goal: 600, metric: "kcal", cardColor: Color(hex: "#98fcec"), otherColor: Color(hex: "#0c0804"))
                }

                Spacer().frame(height: 30)
                
                Text("Today's insight")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.primary)
                    .padding(.horizontal, 25)
                
                InsightCardView(insightTitle: "Your sleep quality has dropped 20% today. Consider winding down earlier.")
            }
            .padding(.bottom, 60)
        }
    }
}

#Preview {
    HomeView()
}
