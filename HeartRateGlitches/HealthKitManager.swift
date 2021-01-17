import HealthKit

final class HealthKitManager {
    let healthStore: HKHealthStore
    let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
    
    private init() {
        healthStore = HKHealthStore()
    }
    
    static let shared = HealthKitManager()
    
    func authorizeHeartRateData(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else { completion(false, nil); return }
        healthStore.requestAuthorization(toShare: [heartRateType], read: [heartRateType]) { (success, error) in
            completion(success, error)
        }
    }
    
    func getHeartRateSample(amount: Int = HKObjectQueryNoLimit, ascending: Bool, completion: @escaping ([HKQuantitySample]) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
        let sampleQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: amount, sortDescriptors: [sortDescriptor])
        { (query, samples, error) in
            guard let heartRateSamples = samples as? [HKQuantitySample] else { print("HealthKit: There is no samples."); return }
            completion(heartRateSamples)
        }
        healthStore.execute(sampleQuery)
    }
    
    func getHeartRateData(amount: Int = HKObjectQueryNoLimit, ascending: Bool = false, completion: @escaping ([HeartRate]) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
        let sampleQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: amount, sortDescriptors: [sortDescriptor])
        { (query, samples, error) in
            guard let heartRateSamples = samples as? [HKQuantitySample] else { print("HealthKit: There is no samples."); return }
            completion(heartRateSamples.map({ HeartRate(heartRate: $0.quantity.doubleValue(for: HKUnit.init(from: "count/min")), startDate: $0.startDate, endDate: $0.endDate) }))
        }
        healthStore.execute(sampleQuery)
    }
    
    enum FilterLevel {
        case high, middle, low
        
        var threshold: Double {
            switch self {
            case .high: return 10
            case .middle: return 10
            case .low: return 10
            }
        }
        
        var range: TimeInterval {
            switch self {
            case .high: return 60*10
            case .middle: return 60*10
            case .low: return 60*10
            }
        }
    }
    
    func findGlitches(level: FilterLevel, completion: @escaping ([HeartRate]) -> Void) {
        getHeartRateData {
            var glitches = [HeartRate]()
            var data: HeartRate?
            $0.forEach({ sample in
                if let previous = data {
                    guard previous.startDate == previous.endDate else { fatalError() }
                    let inRange = sample.endDate.timeIntervalSince(previous.endDate) < level.range
                    let overThreshold = abs(sample.heartRate - previous.heartRate) > level.threshold
                    if inRange && overThreshold {
                        glitches.append(HeartRate(heartRate: sample.heartRate, startDate: sample.startDate, endDate: sample.endDate))
                    }
                }
                data = sample
            })
            
            completion(glitches)
        }
    }
    
    func exportData(_ data: [HeartRate], fileName: String, as fileType: FileType, completion: @escaping (URL) -> Void) {
        let filePath = FileManager().temporaryDirectory.appendingPathComponent(fileName + fileType.fileNameExtension)
        switch fileType {
        case .csv:
            var csvText = "HeartRate,Date\n"
            for sample in data {
                guard sample.startDate == sample.endDate else { fatalError() }
                
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "ko_KR")
                //dateFormatter.dateStyle = .short
                //dateFormatter.timeStyle = .short
                dateFormatter.dateFormat = "yyyy-MM-dd 'at' HH:mm"
                
                let newData = sample.heartRate.description + "," + dateFormatter.string(from: sample.endDate) + "\n"
                csvText.append(newData)
            }
            do {
                try csvText.write(to: filePath, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        completion(filePath)
    }
}
