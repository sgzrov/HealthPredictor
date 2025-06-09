//
//  RelevantHealthDataFetcher.swift
//  HealthPredictor
//
//  Created by Stephan  on 08.06.2025.
//

import Foundation
import HealthKit

class RelevantHealthDataFetcher {

    private let healthStore = HKHealthStore()

    // Fetch average or total values for supported subtags over the past 7 days
    func fetchMetrics(for subtags: [String]) async -> [String: String] {
        var results: [String: String] = [:]

        for subtag in subtags {
            if let quantityID = HealthMetricMapper.quantityType(for: subtag),
               let quantityType = HKObjectType.quantityType(forIdentifier: quantityID) {
                if let value = await fetchQuantityAverage(for: quantityType, subtag: subtag) {
                    results[subtag] = value
                }
            } else if let categoryID = HealthMetricMapper.categoryType(for: subtag),
                      let categoryType = HKObjectType.categoryType(forIdentifier: categoryID) {
                if let value = await fetchCategorySummary(for: categoryType, subtag: subtag) {
                    results[subtag] = value
                }
            }
        }

        return results
    }

    // Quantity Fetch
    private func fetchQuantityAverage(for type: HKQuantityType, subtag: String) async -> String? {
        let now = Date()
        guard let start = Calendar.current.date(byAdding: .day, value: -7, to: now) else { return nil }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: now)

        return await withCheckedContinuation { continuation in
            let options = HealthMetricMapper.statisticsOption(for: subtag)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: options) { _, stats, _ in
                if let avg = stats?.averageQuantity() {
                    let unitString = HealthMetricMapper.unit(for: subtag)
                    let unit = HKUnit(from: unitString.isEmpty ? "count" : unitString)
                    let value = avg.doubleValue(for: unit)
                    let formatted = String(format: "%.1f", value) + (unitString.isEmpty ? "" : " \(unitString)")
                    continuation.resume(returning: formatted)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            healthStore.execute(query)
        }
    }

    // Category Fetch
    private func fetchCategorySummary(for type: HKCategoryType, subtag: String) async -> String? {
        let now = Date()
        guard let start = Calendar.current.date(byAdding: .day, value: -7, to: now) else { return nil }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: now)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                guard let categorySamples = samples as? [HKCategorySample], !categorySamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let totalMinutes = categorySamples.reduce(0.0) { sum, sample in
                    let duration = sample.endDate.timeIntervalSince(sample.startDate) / 60
                    return sum + duration
                }

                let unit = HealthMetricMapper.unit(for: subtag)
                let formatted = String(format: "%.1f", totalMinutes) + (unit.isEmpty ? " min" : " \(unit)")
                continuation.resume(returning: formatted)
            }

            healthStore.execute(query)
        }
    }
}
