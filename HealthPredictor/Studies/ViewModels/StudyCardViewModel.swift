import Foundation
import SwiftUI

class StudyCardViewModel: ObservableObject {

    @Published var study: Study

    init(study: Study) {
        self.study = study
    }

    var formattedDate: String {
        let date = study.importDate
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d'<<suffix>>' yyyy 'at' HH:mm"
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let suffix: String

        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }

        let dateString = formatter.string(from: date)

        return dateString.replacingOccurrences(of: "<<suffix>>", with: suffix)
    }

    var summaryText: String {
        study.summary.isEmpty ? "No summary yet" : study.summary
    }

    var isSummaryEmpty: Bool {
        study.summary.isEmpty
    }

    var title: String {
        study.title
    }
}
