//
//  HealthMetricMapper.swift
//  HealthPredictor
//
//  Created by Stephan  on 09.06.2025.
//

import Foundation
import HealthKit

struct HealthMetricMapper {

    static let quantitySubtagToType: [String: HKQuantityTypeIdentifier] = [
        "HRV": .heartRateVariabilitySDNN,
        "Resting HR": .restingHeartRate,
        "Walking HR": .walkingHeartRateAverage,
        "Blood Pressure": .bloodPressureSystolic,
        "Step Count": .stepCount,
        "Walking Speed": .walkingSpeed,
        "VO2 Max": .vo2Max,
        "Active Energy": .activeEnergyBurned,
        "Hydration": .dietaryWater,
        "Weight": .bodyMass,
        "BMI": .bodyMassIndex,
        "Blood Glucose": .bloodGlucose,
        "Oxygen Saturation": .oxygenSaturation
    ]

    static let categorySubtagToType: [String: HKCategoryTypeIdentifier] = [
        "Sleep Duration": .sleepAnalysis,
        "Mindfulness Minutes": .mindfulSession
    ]

    static let subtagToUnit: [String: String] = [
        "Resting HR": "count/min",
        "Walking HR": "count/min",
        "HRV": "ms",
        "Step Count": "steps",
        "Walking Speed": "m/s",
        "VO2 Max": "ml/kg/min",
        "Active Energy": "kcal",
        "Hydration": "mL",
        "Blood Glucose": "mg/dL",
        "Oxygen Saturation": "%",
        "Weight": "kg",
        "BMI": "",
        "Blood Pressure": "mmHg",
        "Mindfulness Minutes": "min",
        "Sleep Duration": "hours"
    ]

    static func quantityType(for subtag: String) -> HKQuantityTypeIdentifier? {
        quantitySubtagToType[subtag]
    }

    static func categoryType(for subtag: String) -> HKCategoryTypeIdentifier? {
        categorySubtagToType[subtag]
    }

    static func statisticsOption(for subtag: String) -> HKStatisticsOptions {
        switch subtag {
        case "Step Count", "Active Energy", "Hydration":
            return .cumulativeSum
        default:
            return .discreteAverage
        }
    }

    static func unit(for subtag: String) -> String {
        subtagToUnit[subtag] ?? ""
    }
}
