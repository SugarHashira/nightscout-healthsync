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
        static let syncCarbs = "syncCarbs"
        static let syncInsulin = "syncInsulin"
        static let syncGlucose = "syncGlucose"
        static let backgroundSyncInterval = "backgroundSyncInterval"
        static let syncLogs = "syncLogs"
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

    var syncCarbs: Bool {
        get { defaults.object(forKey: Keys.syncCarbs) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.syncCarbs) }
    }

    var syncInsulin: Bool {
        get { defaults.object(forKey: Keys.syncInsulin) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.syncInsulin) }
    }

    var syncGlucose: Bool {
        get { defaults.object(forKey: Keys.syncGlucose) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.syncGlucose) }
    }

    /// How often to sync in minutes (e.g. 15, 30, 60)
    var backgroundSyncInterval: Int {
        get { defaults.object(forKey: Keys.backgroundSyncInterval) as? Int ?? 15 }
        set { defaults.set(newValue, forKey: Keys.backgroundSyncInterval) }
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

    func setNightscoutURL(_ url: String) {
        nightscoutURL = url.isEmpty ? nil : url
    }

    func setNightscoutAPISecret(_ secret: String) {
        nightscoutAPISecret = secret.isEmpty ? nil : secret
    }

    func setGlucoseUnit(_ unit: GlucoseUnit) {
        glucoseUnit = unit
    }

    func setAutoSyncEnabled(_ enabled: Bool) {
        autoSyncEnabled = enabled
    }

    func setSyncCarbs(_ value: Bool) { syncCarbs = value }
    func setSyncInsulin(_ value: Bool) { syncInsulin = value }
    func setSyncGlucose(_ value: Bool) { syncGlucose = value }
    func setBackgroundSyncInterval(_ minutes: Int) { backgroundSyncInterval = minutes }

    func setLastSyncDate(_ date: Date?) {
        lastSyncDate = date
    }

    var syncLogs: [SyncLog] {
        get {
            guard let data = defaults.data(forKey: Keys.syncLogs),
                  let logs = try? JSONDecoder().decode([SyncLog].self, from: data) else { return [] }
            return logs
        }
        set {
            let kept = Array(newValue.suffix(100)) // keep last 100
            if let data = try? JSONEncoder().encode(kept) {
                defaults.set(data, forKey: Keys.syncLogs)
            }
        }
    }

    func appendSyncLog(_ log: SyncLog) {
        var logs = syncLogs
        logs.append(log)
        syncLogs = logs
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
