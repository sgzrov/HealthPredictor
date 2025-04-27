import SwiftUI

struct HomeView: View {

    @StateObject var cardViewModel = CardManagerViewModel()
    @State private var isScrolling = false
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

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
            }
            .padding(.horizontal, 16)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 12)
            }
        }
    }
}

#Preview {
    TabView {
        HomeView()
            .preferredColorScheme(.dark)
            .tabItem {
                Label("Home", systemImage: "house")
            }
        ChatView()
            .preferredColorScheme(.dark)
            .tabItem {
                Label("Chat", systemImage: "message")
            }
    }
}
