import Foundation
import HealthKit

enum SyncError: Error, LocalizedError {
    case notConfigured
    case noHealthKit
    case nightscoutError(Error)
    case healthKitError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Nightscout is not configured"
        case .noHealthKit:
            return "HealthKit is not available"
        case .nightscoutError(let error):
            return "Nightscout error: \(error.localizedDescription)"
        case .healthKitError(let error):
            return "HealthKit error: \(error.localizedDescription)"
        }
    }
}

struct SyncResult {
    var treatmentsProcessed: Int = 0
    var treatmentsSynced: Int = 0
    var glucoseProcessed: Int = 0
    var glucoseSynced: Int = 0
    var errors: [String] = []
}

actor SyncService {
    static let shared = SyncService()
    
    private init() {}
    
    func syncAll() async throws -> SyncResult {
        guard let healthKit = HealthKitService.shared else {
            throw SyncError.noHealthKit
        }
        
        let settings = UserSettings.shared
        guard await settings.nightscoutURL != nil, await settings.nightscoutAPISecret != nil else {
            throw SyncError.notConfigured
        }
        
        var result = SyncResult()
        
        let lastSync = await settings.lastSyncDate ?? Date.distantPast
        
        do {
            let nightscout = try await NightscoutService.shared
            let treatments = try await nightscout.fetchTreatments(since: lastSync)
            result.treatmentsProcessed = treatments.count
            
            for treatment in treatments {
                guard let id = treatment.id else { continue }
                guard !await settings.isTreatmentSynced(id) else { continue }
                
                if let carbs = treatment.carbs, carbs > 0, let date = treatment.treatmentDate {
                    do {
                        try await healthKit.saveCarbohydrates(grams: carbs, date: date)
                        result.treatmentsSynced += 1
                    } catch {
                        result.errors.append("Failed to save carbs: \(error.localizedDescription)")
                    }
                }
                
                if let insulin = treatment.insulin, insulin > 0, let date = treatment.treatmentDate {
                    let isBasal = treatment.eventType?.lowercased().contains("basal") ?? false
                    do {
                        try await healthKit.saveInsulin(units: insulin, date: date, isBasal: isBasal)
                        result.treatmentsSynced += 1
                    } catch {
                        result.errors.append("Failed to save insulin: \(error.localizedDescription)")
                    }
                }
                
                await settings.addSyncedTreatmentID(id)
            }
            
            let glucoseEntries = try await nightscout.fetchGlucoseEntries(since: lastSync)
            result.glucoseProcessed = glucoseEntries.count
            
            let unit = await settings.glucoseUnit
            
            for entry in glucoseEntries {
                guard let id = entry.id else { continue }
                guard !await settings.isGlucoseSynced(id) else { continue }
                
                let value: Double
                let hkUnit: HKUnit
                
                switch unit {
                case .mgdl:
                    value = entry.mgDlValue
                    hkUnit = HKUnit.gramUnit(with: .deci).unitDivided(by: .deciliter())
                case .mmol:
                    value = entry.mmolValue
                    hkUnit = HKUnit.gramUnit(with: .milli).unitDivided(by: .liter())
                }
                
                do {
                    try await healthKit.saveBloodGlucose(value: value, unit: hkUnit, date: entry.timestamp)
                    result.glucoseSynced += 1
                } catch {
                    result.errors.append("Failed to save glucose: \(error.localizedDescription)")
                }
                
                await settings.addSyncedGlucoseID(id)
            }
            
            await settings.lastSyncDate = Date()
            
        } catch let error as NightscoutError {
            throw SyncError.nightscoutError(error)
        } catch let error as HealthKitError {
            throw SyncError.healthKitError(error)
        }
        
        return result
    }
    
    func testConnection() async throws -> Bool {
        let nightscout = try await NightscoutService.shared
        return try await nightscout.testConnection()
    }
    
    func getLastSyncDate() async -> Date? {
        return await UserSettings.shared.lastSyncDate
    }
}
