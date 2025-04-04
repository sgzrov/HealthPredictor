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
                        ForEach(cardViewModel.availableCardTemplates, id: \.title) { card in
                            Button("Add \(card.title)") {
                                cardViewModel.addCard(card)
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Circle().fill(Color(hex: "#28242c").opacity(0.5)))
                    }
                    .padding(.horizontal, 15)
                    .offset(y: 2)
                }

                HStack(spacing: 0) {
                    CardDockView(icons: cardViewModel.minimizedCards.map { $0.emoji })
                        .frame(width: CardDockView.defaultWidth, height: cardViewModel.minimizedCards.isEmpty ? CardDockView.defaultHeight : nil)
                    
                    Spacer()
                    
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 10) {
                            ForEach(cardViewModel.visibleCards) { card in
                                HealthCardView(card: card)
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
                .padding(.horizontal, 8)
                
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
