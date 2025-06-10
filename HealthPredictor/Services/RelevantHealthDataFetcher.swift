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

    func fetchMetricHistories(for subtags: [String]) async -> [String: HealthMetricHistory] {
        var results: [String: HealthMetricHistory] = [:]
        
        for subtag in subtags {
            if let quantityID = HealthMetricMapper.quantityType(for: subtag),
               let quantityType = HKObjectType.quantityType(forIdentifier: quantityID) {
                let daily = await fetchQuantityHistory(for: quantityType, subtag: subtag, days: 7)
                let monthly = await fetchQuantityMonthlyHistory(for: quantityType, subtag: subtag)
                results[subtag] = HealthMetricHistory(daily: daily, monthly: monthly)
            } else if let categoryID = HealthMetricMapper.categoryType(for: subtag),
                      let categoryType = HKObjectType.categoryType(forIdentifier: categoryID) {
                let daily = await fetchCategoryHistory(for: categoryType, subtag: subtag, days: 7)
                let monthly = await fetchCategoryMonthlyHistory(for: categoryType, subtag: subtag)
                results[subtag] = HealthMetricHistory(daily: daily, monthly: monthly)
            }
        }
        return results
    }
    
    private func fetchQuantityHistory(for type: HKQuantityType, subtag: String, days: Int) async -> [Double] {
        let calendar = Calendar.current
        let now = Date()
        var results: [Double] = []
        
        for dayOffset in (0...days).reversed() {
            guard let dayStart = calendar.date(byAdding: .day, value: -dayOffset, to: calendar.startOfDay(for: now)),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }
            let predicate = HKQuery.predicateForSamples(withStart: dayStart, end: dayEnd)
            let value = await fetchQuantityValue(for: type, subtag: subtag, predicate: predicate)
            results.append(value)
        }
        return results
    }

    private func fetchQuantityMonthlyHistory(for type: HKQuantityType, subtag: String) async -> [Double] {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        var results: [Double] = []
        
        for month in 1..<(currentMonth) {
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = 1
            guard let monthStart = calendar.date(from: comps),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }
            let predicate = HKQuery.predicateForSamples(withStart: monthStart, end: monthEnd)
            let value = await fetchQuantityValue(for: type, subtag: subtag, predicate: predicate)
            results.append(value)
        }
        return results
    }

    private func fetchQuantityValue(for type: HKQuantityType, subtag: String, predicate: NSPredicate) async -> Double {
        await withCheckedContinuation { continuation in
            let options = HealthMetricMapper.statisticsOption(for: subtag)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: options) { _, stats, _ in
                let unitString = HealthMetricMapper.unit(for: subtag)
                let unit = HKUnit(from: unitString.isEmpty ? "count" : unitString)
                var value: Double = 0.0
                if options == .cumulativeSum, let sum = stats?.sumQuantity() {
                    value = sum.doubleValue(for: unit)
                } else if let avg = stats?.averageQuantity() {
                    value = avg.doubleValue(for: unit)
                }
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func fetchCategoryHistory(for type: HKCategoryType, subtag: String, days: Int) async -> [Double] {
        let calendar = Calendar.current
        let now = Date()
        var results: [Double] = []
        
        for dayOffset in (0...days).reversed() {
            guard let dayStart = calendar.date(byAdding: .day, value: -dayOffset, to: calendar.startOfDay(for: now)),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }
            let predicate = HKQuery.predicateForSamples(withStart: dayStart, end: dayEnd)
            let value = await fetchCategoryValue(for: type, subtag: subtag, predicate: predicate)
            results.append(value)
        }
        return results
    }

    private func fetchCategoryMonthlyHistory(for type: HKCategoryType, subtag: String) async -> [Double] {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        var results: [Double] = []
        
        for month in 1..<(currentMonth) {
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = 1
            guard let monthStart = calendar.date(from: comps),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }
            let predicate = HKQuery.predicateForSamples(withStart: monthStart, end: monthEnd)
            let value = await fetchCategoryValue(for: type, subtag: subtag, predicate: predicate)
            results.append(value)
        }
        return results
    }

    private func fetchCategoryValue(for type: HKCategoryType, subtag: String, predicate: NSPredicate) async -> Double {
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                guard let categorySamples = samples as? [HKCategorySample], !categorySamples.isEmpty else {
                    continuation.resume(returning: 0.0)
                    return
                }
                let totalMinutes = categorySamples.reduce(0.0) { sum, sample in
                    let duration = sample.endDate.timeIntervalSince(sample.startDate) / 60
                    return sum + duration
                }
                continuation.resume(returning: totalMinutes)
            }
            healthStore.execute(query)
        }
    }
}
