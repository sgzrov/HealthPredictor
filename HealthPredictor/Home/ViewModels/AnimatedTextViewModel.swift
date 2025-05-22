import Foundation
import SwiftUI

class AnimatedTextViewModel: ObservableObject {
    @Published var revealedChunks: [String] = []
    private var allChunks: [String] = []
    private var currentIndex = 0
    private var timer: Timer?


    func configure(with text: String, chunkSize: Int = 4) {
        let sentences = TextChunker.sentences(from: text)
        allChunks = []
        for (index, sentence) in sentences.enumerated() {
            if index < 2 {
                allChunks += TextChunker.words(from: sentence)
            } else {
                allChunks += TextChunker.chunkedWords(from: sentence, chunkSize: chunkSize)
            }
        }
        revealedChunks = []
        currentIndex = 0
    }

    /// Starts the animation, revealing chunks at the given speed.
    func startAnimation(speed: Double = 0.15) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.currentIndex < self.allChunks.count {
                self.revealedChunks.append(self.allChunks[self.currentIndex])
                self.currentIndex += 1
            } else {
                self.timer?.invalidate()
            }
        }
    }

    /// Stops the animation.
    func stopAnimation() {
        timer?.invalidate()
    }
}
