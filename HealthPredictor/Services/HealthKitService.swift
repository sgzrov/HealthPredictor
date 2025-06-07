//
//  HealthKitService.swift
//  HealthPredictor
//
//  Created by Stephan  on 07.06.2025.
//

import Foundation
import HealthKit

class HealthStoreService {
    let healthStore = HKHealthStore()

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
            return
        }

        let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

        let readTypes: Set = [stepCount, heartRate, activeEnergy, sleep]

        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
            completion(success, error)
        }
    }
}
