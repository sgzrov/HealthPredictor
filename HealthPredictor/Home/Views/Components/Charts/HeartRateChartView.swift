import SwiftUI

struct HeartRateChartView: View {
    @ObservedObject var viewModel: HealthCardViewModel

    var body: some View {
        VStack {
            // Replace with actual heart rate visualisation
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(hex: "#28242c"))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Text("Heart Rate Chart")
                            .foregroundColor(.white)
                        Text("BPM over time")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        // Example of using viewModel data
                        Text("\(viewModel.card.value) \(viewModel.card.metric)")
                            .foregroundColor(.white)
                            .font(.title)
                    }
                )
        }
    }
}

#Preview {
    HeartRateChartView(viewModel: HealthCardViewModel(card: HealthCard.heartRate))
}
