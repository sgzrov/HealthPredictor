import SwiftUI

struct HomeView: View {

    @StateObject var cardViewModel = CardManagerViewModel()
    @State private var isScrolling = false
    @State private var scrollOffset: CGFloat = 0

    private enum Layout {
        static let sectionSpacing: CGFloat = 28
        static let headerToContent: CGFloat = 12
        static let leadingPadding: CGFloat = 25
        static let buttonPadding: CGFloat = 5
        static let cardPadding: CGFloat = 12
    }

    var body: some View {
        ZStack {
            Color(hex: "#100c1c").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                VStack(alignment: .leading) {
                    Text("Hello, Max")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)

                    Text("Let's check how you feel today")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(.leading, Layout.leadingPadding)
                .padding(.bottom, Layout.sectionSpacing)

                VStack {
                    HStack {
                        Text("Today's goal")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.leading, Layout.leadingPadding)

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
                    }

                    HStack {
                        if isScrolling && cardViewModel.shouldShowDock {
                            CardDockView(
                                cardsAbove: cardViewModel.cardsAbove,
                                cardsBelow: cardViewModel.cardsBelow
                            )
                            .frame(width: CardDockView.defaultWidth, height: cardViewModel.minimizedCards.isEmpty ? CardDockView.defaultHeight : CGFloat(cardViewModel.minimizedCards.count) * (CardDockView.iconHeight + CardDockView.iconSpacing) + CardDockView.verticalPadding * 2)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .move(edge: .leading)).combined(with: .opacity),
                                removal: .scale(scale: 0.8).combined(with: .move(edge: .leading)).combined(with: .opacity)
                            ))
                        }

                        ScrollView(.vertical) {
                            LazyVStack(spacing: 12) {
                                ForEach(cardViewModel.visibleCards) { card in
                                    HealthCardView(card: card)
                                }
                            }
                            .background(
                                GeometryReader { geometry in
                                    Color.clear.preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: geometry.frame(in: .named("scroll")).minY
                                    )
                                }
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if cardViewModel.hasAddedCards && !cardViewModel.isAtBoundary(for: value.translation.height) {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                                isScrolling = true
                                            }
                                        }
                                    }
                                    .onEnded { value in
                                        if cardViewModel.hasAddedCards && !cardViewModel.isAtBoundary(for: value.translation.height) {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                                if value.translation.height > 25 {
                                                    cardViewModel.handleScrollGesture(direction: .upwardMovement)
                                                } else if value.translation.height < -25 {
                                                    cardViewModel.handleScrollGesture(direction: .downwardMovement)
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                                        isScrolling = false
                                                    }
                                                }
                                            }
                                        }
                                    }
                            )
                        }
                        .frame(height: 3 * 136)
                        .coordinateSpace(name: "scroll")
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            if cardViewModel.hasAddedCards {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    isScrolling = abs(value - scrollOffset) > 1.5
                                    scrollOffset = value
                                }
                            }
                        }
                        .clipped()
                        .padding(.leading, cardViewModel.hasAddedCards && isScrolling ? 8 : 0)

                    }
                    .padding(.horizontal, Layout.cardPadding)
                }

                VStack(alignment: .leading, spacing: Layout.headerToContent) {
                    Text("Highlights")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.leading, Layout.leadingPadding)

                    InsightCardView(card: InsightCard(
                        title: "Your sleep quality has dropped 20% throughout this week. Consider winding down earlier.",
                        backgroundColor: Color(hex: "#28242c"),
                        textColor: .white
                    ))
                        .padding(.horizontal, Layout.cardPadding)
                }
                .padding(.top, Layout.sectionSpacing + Layout.buttonPadding)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: Layout.headerToContent)
            }
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
