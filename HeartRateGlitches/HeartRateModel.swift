import Foundation

struct HeartRate {
    let heartRate: Double
    let startDate: Date
    let endDate: Date
}

struct HeartRateSamples {
    let year: Date
    let samples: [HeartRate]
}

enum FileType {
    case csv
    
    var fileNameExtension: String {
        switch self {
        case .csv:
            return ".csv"
        }
    }
}
