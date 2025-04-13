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

                VStack(spacing: LayoutConstants.headerToScrollableContent) {
                    GoalHeaderView(cardViewModel: cardViewModel)
                    CardScrollView(cardViewModel: cardViewModel, isScrolling: $isScrolling, scrollOffset: $scrollOffset)
                }

                HighlightsView()
            }
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 0)
            }
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
