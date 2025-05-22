import SwiftUI

struct AnimatedTextView: View {
    @StateObject private var viewModel = AnimatedTextViewModel()
    let text: String
    var font: Font = .body
    var textColor: Color = .primary
    var chunkSize: Int = 4
    var speed: Double = 0.15

    var body: some View {
        Text(viewModel.revealedChunks.joined(separator: " "))
            .font(font)
            .foregroundColor(textColor)
            .transition(.opacity)
        .onAppear {
            viewModel.configure(with: text, chunkSize: chunkSize)
            viewModel.startAnimation(speed: speed)
        }
        .onDisappear {
            viewModel.stopAnimation()
        }
    }
}

#Preview {
    AnimatedTextView(
        text: "Your heart rate has been stable. Keep maintaining a regular exercise routine to maintain this healthy pattern.",
        font: .system(size: 15, weight: .regular),
        textColor: .white.opacity(0.9)
    )
}