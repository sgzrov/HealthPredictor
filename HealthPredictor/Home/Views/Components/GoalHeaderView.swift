import SwiftUI

struct GoalHeaderView: View {
    @ObservedObject var cardViewModel: CardManagerViewModel

    var body: some View {
        HStack {
            Text("Daily goals")
                .font(.title3)
                .bold()
                .foregroundColor(.white)
                .padding(.leading, LayoutConstants.leadingPadding)

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
            }
            .padding(.horizontal, LayoutConstants.horizontalPadding)
        }
    }
}

#Preview {
    GoalHeaderView(cardViewModel: CardManagerViewModel())
        .background(Color(hex: "#100c1c"))
}
