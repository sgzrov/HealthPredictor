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
        ChatView(session: ChatSession(title: "Preview Chat"))
            .preferredColorScheme(.dark)
            .tabItem {
                Label("Chat", systemImage: "message")
            }
    }
}
