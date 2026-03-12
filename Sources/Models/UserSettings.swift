import Foundation

actor UserSettings {
    static let shared = UserSettings()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let nightscoutURL = "nightscoutURL"
        static let nightscoutAPISecret = "nightscoutAPISecret"
        static let lastSyncDate = "lastSyncDate"
        static let syncedTreatmentIDs = "syncedTreatmentIDs"
        static let syncedGlucoseIDs = "syncedGlucoseIDs"
        static let glucoseUnit = "glucoseUnit"
        static let autoSyncEnabled = "autoSyncEnabled"
    }
    
    private init() {}
    
    var nightscoutURL: String? {
        get { defaults.string(forKey: Keys.nightscoutURL) }
        set { defaults.set(newValue, forKey: Keys.nightscoutURL) }
    }
    
    var nightscoutAPISecret: String? {
        get { defaults.string(forKey: Keys.nightscoutAPISecret) }
        set { defaults.set(newValue, forKey: Keys.nightscoutAPISecret) }
    }
    
    var lastSyncDate: Date? {
        get { defaults.object(forKey: Keys.lastSyncDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastSyncDate) }
    }
    
    var syncedTreatmentIDs: Set<String> {
        get { Set(defaults.stringArray(forKey: Keys.syncedTreatmentIDs) ?? []) }
        set { defaults.set(Array(newValue), forKey: Keys.syncedTreatmentIDs) }
    }
    
    var syncedGlucoseIDs: Set<String> {
        get { Set(defaults.stringArray(forKey: Keys.syncedGlucoseIDs) ?? []) }
        set { defaults.set(Array(newValue), forKey: Keys.syncedGlucoseIDs) }
    }
    
    var glucoseUnit: GlucoseUnit {
        get {
            let raw = defaults.string(forKey: Keys.glucoseUnit) ?? "mgdl"
            return GlucoseUnit(rawValue: raw) ?? .mgdl
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.glucoseUnit) }
    }
    
    var autoSyncEnabled: Bool {
        get { defaults.bool(forKey: Keys.autoSyncEnabled) }
        set { defaults.set(newValue, forKey: Keys.autoSyncEnabled) }
    }
    
    func addSyncedTreatmentID(_ id: String) {
        var ids = syncedTreatmentIDs
        ids.insert(id)
        syncedTreatmentIDs = ids
    }
    
    func addSyncedGlucoseID(_ id: String) {
        var ids = syncedGlucoseIDs
        ids.insert(id)
        syncedGlucoseIDs = ids
    }
    
    func isTreatmentSynced(_ id: String) -> Bool {
        syncedTreatmentIDs.contains(id)
    }
    
    func isGlucoseSynced(_ id: String) -> Bool {
        syncedGlucoseIDs.contains(id)
    }
}

enum GlucoseUnit: String {
    case mgdl = "mgdl"
    case mmol = "mmol"
    
    var displayName: String {
        switch self {
        case .mgdl: return "mg/dL"
        case .mmol: return "mmol/L"
        }
    }
}
