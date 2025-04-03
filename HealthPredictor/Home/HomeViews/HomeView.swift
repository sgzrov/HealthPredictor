import SwiftUI

struct HomeView: View {
    
    @StateObject var cardViewModel = CardManagerViewModel()
    
    var body: some View {
        ZStack {
            Color(hex: "#100c1c").ignoresSafeArea()

            VStack(alignment: .leading) {

                VStack(alignment: .leading) {
                    Text("Hello, Max")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text("Let's check how you feel today")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 25)
                
                Spacer().frame(height: 20)
                
                HStack {
                    Text("Today's goal")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 25)
                        
                    Spacer()
                        
                    Menu {
                        Button("Add Heart Rate") {
                            cardViewModel.addCard(CardTemplates.heartRate)
                        }
                        Button("Add Calories") {
                            cardViewModel.addCard(CardTemplates.calories)
                        }
                        Button("Add Active Time") {
                            cardViewModel.addCard(CardTemplates.activeTime)
                        }
                        Button("Add Sleep") {
                            cardViewModel.addCard(CardTemplates.sleep)
                        }
                        Button("Add Water Intake") {
                            cardViewModel.addCard(CardTemplates.water)
                        }
                        Button("Add Steps") {
                            cardViewModel.addCard(CardTemplates.steps)
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Circle().fill(Color(hex: "#28242c").opacity(0.5)))
                            .offset(y: 2)
                    }
                    .padding(.horizontal, 25)
                }

                HStack(spacing: 0) {
                    CardDockView(icons: cardViewModel.minimizedCards.map { $0.emoji })
                        .frame(width: CardDockView.defaultWidth, height: cardViewModel.minimizedCards.isEmpty ? CardDockView.defaultHeight : nil)
                        .padding(.leading, 7)
                    
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(cardViewModel.visibleCards) { card in
                                HealthCardView(card: card)
                                    .frame(maxWidth: .infinity)
                                    .scrollTransition { effect, phase in
                                        let offset = abs(phase.value)
                                        let scale = max(0.85, 1 - offset * 0.3)
                                        let opacity = max(0.3, 1 - offset * 1.2)
                                        return effect
                                            .scaleEffect(scale)
                                            .opacity(opacity)
                                }
                            }
                        }
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        if value.translation.height > 20 {
                                            cardViewModel.handleScrollGesture(direction: .up)
                                        } else if value.translation.height < -20 {
                                            cardViewModel.handleScrollGesture(direction: .down)
                                        }
                                    }
                                }
                        )
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .background(Color(hex: "#100c1c"))
                    .frame(height: 3 * 143)
                    .fixedSize(horizontal: false, vertical: true)
                    .clipped()
                }
                .padding(.horizontal, 3)
                
                Spacer().frame(height: 20)
                
                Text("Your insight")
                    .font(.headline)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.horizontal, 25)
                
                InsightCardView(insightTitle: "Your sleep quality has dropped 20% throughout this week. Consider winding down earlier.")
            }
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    HomeView()
}
