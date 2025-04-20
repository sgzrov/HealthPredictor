import SwiftUI

struct HomeView: View {

    @StateObject var cardViewModel = CardManagerViewModel()
    @State private var isScrolling = false
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Color(hex: "#100c1c").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                GreetingView()
                    
                MenuSelectorView()
                
                CardScrollView(cardViewModel: cardViewModel, isScrolling: $isScrolling, scrollOffset: $scrollOffset)
                
                HStack {
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
                            .font(.title2)
                            .padding(3)
                            .background(Circle().fill(Color(hex: "#28242c").opacity(0.8)))
                    }
                    Spacer()
                }
                .padding(.vertical, 3)
                
                HighlightsView()
            }
            .padding(.horizontal, 3)
            
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 12)
            }
        }
    }
}

#Preview {
    TabView {
        HomeView()
            .tabItem {
                Label("Home", systemImage: "house")
            }
    }
}
