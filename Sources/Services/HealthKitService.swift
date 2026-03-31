import Foundation
import HealthKit

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case authorizationDenied
    case typeNotAvailable
    case saveFailed(Error)
    case queryFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        case .typeNotAvailable:
            return "Requested HealthKit type is not available"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .queryFailed(let error):
            return "Query failed: \(error.localizedDescription)"
        }
    }
}

actor HealthKitService {
    private let healthStore: HKHealthStore
    
    static var shared: HealthKitService? {
        guard HKHealthStore.isHealthDataAvailable() else {
            return nil
        }
        return HealthKitService()
    }
    
    private init() {
        self.healthStore = HKHealthStore()
    }
    
    private var typesToShare: Set<HKSampleType> {
        [
            HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!,
            HKQuantityType.quantityType(forIdentifier: .insulinDelivery)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!
        ]
    }
    
    private var typesToRead: Set<HKObjectType> {
        [
            HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!,
            HKQuantityType.quantityType(forIdentifier: .insulinDelivery)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth)!
        ]
    }
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
    }
    
    func saveBloodGlucose(value: Double, unit: HKUnit, date: Date) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) else {
            throw HealthKitError.typeNotAvailable
        }
        
        let quantity = HKQuantity(unit: unit, doubleValue: value)
        
        let sample = HKQuantitySample(
            type: type,
            quantity: quantity,
            start: date,
            end: date,
            metadata: ["HKWasUserEntered": false]
        )
        
        do {
            try await healthStore.save(sample)
        } catch {
            throw HealthKitError.saveFailed(error)
        }
    }
    
    func saveInsulin(units: Double, date: Date, isBasal: Bool) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: .insulinDelivery) else {
            throw HealthKitError.typeNotAvailable
        }
        
        let quantity = HKQuantity(unit: .internationalUnit(), doubleValue: units)
        
        let reason: HKInsulinDeliveryReason = isBasal ? .basal : .bolus

        let sample = HKQuantitySample(
            type: type,
            quantity: quantity,
            start: date,
            end: date,
            metadata: [HKMetadataKeyInsulinDeliveryReason: reason.rawValue]
        )
        
        do {
            try await healthStore.save(sample)
        } catch {
            throw HealthKitError.saveFailed(error)
        }
    }
    
    func saveCarbohydrates(grams: Double, date: Date) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) else {
            throw HealthKitError.typeNotAvailable
        }
        
        let quantity = HKQuantity(unit: .gram(), doubleValue: grams)
        
        let sample = HKQuantitySample(
            type: type,
            quantity: quantity,
            start: date,
            end: date,
            metadata: ["HKWasUserEntered": false]
        )
        
        do {
            try await healthStore.save(sample)
        } catch {
            throw HealthKitError.saveFailed(error)
        }
    }
    
    func fetchLastSyncDate() async -> Date? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .insulinDelivery) else {
            return nil
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: type,
                    predicate: nil,
                    limit: 1,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: samples ?? [])
                    }
                }
                healthStore.execute(query)
            }
            
            return samples.first?.endDate
        } catch {
            return nil
        }
    }
}
