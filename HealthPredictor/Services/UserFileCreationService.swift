//
//  CSVManager.swift
//  HealthPredictor
//
//  Created by Stephan  on 18.06.2025.
//

import Foundation
import HealthKit

class UserFileCreationService: UserFileCreationServiceProtocol {

    static let shared = UserFileCreationService()

    private let healthStoreService: HealthStoreServiceProtocol

    private init() {
        self.healthStoreService = HealthStoreService.shared
    }
    private let fileName = "user_health_data.csv"

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()

    func generateCSV(completion: @escaping (URL?) -> Void) {
        let metricNames = Self.metricNames()
        let header = (["Date"] + metricNames).joined(separator: ",")

        fetchAllMetricsData { dailyRows, monthlyRows in
            var csvRows: [String] = [header]
            csvRows.append(contentsOf: dailyRows)
            csvRows.append(contentsOf: monthlyRows)
            let csvString = csvRows.joined(separator: "\n")
            let fileURL = self.writeCSVToFile(csvString: csvString)
            completion(fileURL)
        }
    }

    static func metricNames() -> [String] {
        let quantityNames = Array(HealthMetricMapper.quantitySubtagToType.keys)
        let categoryNames = Array(HealthMetricMapper.categorySubtagToType.keys)
        return quantityNames + categoryNames
    }

    private func fetchAllMetricsData(completion: @escaping ([String], [String]) -> Void) {
        let metricNames = Self.metricNames()
        let today = Date()
        let calendar = Calendar.current
        let group = DispatchGroup()

        var dailyData: [String: [String: Double]] = [:]

        // Build date range
        let dailyDates: [Date] = (0..<180).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }

        for metric in metricNames {
            if let quantityType = HealthMetricMapper.quantityType(for: metric),
               let hkType = HKObjectType.quantityType(forIdentifier: quantityType) {
                group.enter()
                fetchQuantityData(
                    type: hkType,
                    metric: metric,
                    dailyDates: dailyDates
                ) { daily in
                    for (date, value) in daily { dailyData[date, default: [:]][metric] = value }
                    group.leave()
                }
            } else if let categoryType = HealthMetricMapper.categoryType(for: metric),
                      let hkType = HKObjectType.categoryType(forIdentifier: categoryType) {
                group.enter()
                fetchCategoryData(
                    type: hkType,
                    metric: metric,
                    dailyDates: dailyDates
                ) { daily in
                    for (date, value) in daily { dailyData[date, default: [:]][metric] = value }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            let sortedDaily = dailyDates.map { Self.dateFormatter.string(from: $0) }
            let dailyRows: [String] = sortedDaily.map { dateStr in
                let values = metricNames.map { metric in
                    if let val = dailyData[dateStr]?[metric] {
                        return String(format: "%.2f", val)
                    } else {
                        return ""
                    }
                }
                return ([dateStr] + values).joined(separator: ",")
            }

            completion(dailyRows, [])
        }
    }

    private func fetchQuantityData(type: HKQuantityType, metric: String, dailyDates: [Date], completion: @escaping ([String: Double]) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -149, to: now) ?? now
        let anchorDate = calendar.startOfDay(for: startDate)
        let dailyInterval = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(withStart: calendar.date(byAdding: .year, value: -2, to: now), end: now, options: .strictStartDate)
        let unit = HKUnit(from: HealthMetricMapper.unit(for: metric))
        let statsOption = HealthMetricMapper.statisticsOption(for: metric)

        var dailyResults: [String: Double] = [:]

        let dailyQuery = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: predicate, options: statsOption, anchorDate: anchorDate, intervalComponents: dailyInterval)
        dailyQuery.initialResultsHandler = { [weak self] _, results, error in
            if let error = error {
                print("Error fetching daily \(metric): \(error.localizedDescription)")
                completion(dailyResults)
                return
            }

            if let statsCollection = results {
                for date in dailyDates {
                    let stat = statsCollection.statistics(for: date)
                    let value = self?.extractQuantityValue(stat: stat, unit: unit, statsOption: statsOption)
                    if let value = value {
                        dailyResults[Self.dateFormatter.string(from: date)] = value
                    }
                }
            }
            completion(dailyResults)
        }
        self.healthStoreService.healthStore.execute(dailyQuery)
    }

    private func extractQuantityValue(stat: HKStatistics?, unit: HKUnit, statsOption: HKStatisticsOptions) -> Double? {
        if statsOption == .cumulativeSum {
            return stat?.sumQuantity()?.doubleValue(for: unit)
        } else {
            return stat?.averageQuantity()?.doubleValue(for: unit)
        }
    }

    private func fetchCategoryData(type: HKCategoryType, metric: String, dailyDates: [Date], completion: @escaping ([String: Double]) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .year, value: -2, to: now) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        var dailyResults: [String: Double] = [:]

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, error in
            if let error = error {
                print("Error fetching category \(metric): \(error.localizedDescription)")
                completion(dailyResults)
                return
            }

            guard let samples = samples as? [HKCategorySample] else {
                completion(dailyResults)
                return
            }

            for date in dailyDates {
                let dayStart = calendar.startOfDay(for: date)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
                let daySamples = samples.filter { $0.startDate >= dayStart && $0.startDate < dayEnd }
                if !daySamples.isEmpty {
                    let total = self?.calculateCategoryTotal(samples: daySamples, metric: metric)
                    if let total = total {
                        dailyResults[Self.dateFormatter.string(from: date)] = total
                    }
                }
            }
            completion(dailyResults)
        }
        self.healthStoreService.healthStore.execute(query)
    }

    private func calculateCategoryTotal(samples: [HKCategorySample], metric: String) -> Double {
        if metric == "Sleep Duration" {
            let totalSeconds = samples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            return totalSeconds / 3600.0 // Return in hours
        } else if metric == "Mindfulness Minutes" {
            let totalSeconds = samples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            return totalSeconds / 60.0 // Return in minutes
        }
        fatalError("Unknown category metric: \(metric)") // Should never be reached
    }

    private func writeCSVToFile(csvString: String) -> URL? {
        let fileManager = FileManager.default
        guard let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileURL = docsURL.appendingPathComponent(fileName)
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }
}
