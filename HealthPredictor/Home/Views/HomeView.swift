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

                VStack {
                    GoalHeaderView(cardViewModel: cardViewModel)
                    CardScrollView(cardViewModel: cardViewModel, isScrolling: $isScrolling, scrollOffset: $scrollOffset)
                }

                HighlightsView()
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: LayoutConstants.headerToContent)
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
