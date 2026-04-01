import Foundation
import SwiftUI

@MainActor
class SyncViewModel: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncResult: SyncResult?
    @Published var errorMessage: String?
    @Published var isConfigured = false
    
    @Published var nightscoutURL: String = ""
    @Published var nightscoutSecret: String = ""
    @Published var selectedGlucoseUnit: GlucoseUnit = .mgdl
    @Published var autoSyncEnabled: Bool = false
    @Published var syncCarbs: Bool = true
    @Published var syncInsulin: Bool = true
    @Published var syncGlucose: Bool = true
    @Published var backgroundSyncInterval: Int = 15
    @Published var syncLogs: [SyncLog] = []
    
    private let settings = UserSettings.shared
    
    init() {
        Task {
            await loadSettings()
        }
    }
    
    func loadSettings() async {
        nightscoutURL = await settings.nightscoutURL ?? ""
        nightscoutSecret = await settings.nightscoutAPISecret ?? ""
        selectedGlucoseUnit = await settings.glucoseUnit
        autoSyncEnabled = await settings.autoSyncEnabled
        syncCarbs = await settings.syncCarbs
        syncInsulin = await settings.syncInsulin
        syncGlucose = await settings.syncGlucose
        backgroundSyncInterval = await settings.backgroundSyncInterval
        lastSyncDate = await settings.lastSyncDate
        syncLogs = await settings.syncLogs.reversed()
        isConfigured = nightscoutURL.isEmpty == false && nightscoutSecret.isEmpty == false
    }

    func saveSettings() async {
        await settings.setNightscoutURL(nightscoutURL)
        await settings.setNightscoutAPISecret(nightscoutSecret)
        await settings.setGlucoseUnit(selectedGlucoseUnit)
        await settings.setAutoSyncEnabled(autoSyncEnabled)
        await settings.setSyncCarbs(syncCarbs)
        await settings.setSyncInsulin(syncInsulin)
        await settings.setSyncGlucose(syncGlucose)
        await settings.setBackgroundSyncInterval(backgroundSyncInterval)
        isConfigured = nightscoutURL.isEmpty == false && nightscoutSecret.isEmpty == false
    }
    
    func syncNow() async {
        guard isConfigured else {
            errorMessage = "Please configure Nightscout first"
            return
        }
        
        isSyncing = true
        errorMessage = nil
        
        do {
            syncResult = try await SyncService.shared.syncAll()
            lastSyncDate = await SyncService.shared.getLastSyncDate()
            syncLogs = await settings.syncLogs.reversed()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSyncing = false
    }
    
    func testConnection() async -> Bool {
        guard !nightscoutURL.isEmpty else { return false }
        
        do {
            await saveSettings()
            return try await SyncService.shared.testConnection()
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func requestHealthKitAuthorization() async {
        guard let healthKit = HealthKitService.shared else {
            errorMessage = "HealthKit not available"
            return
        }
        
        do {
            try await healthKit.requestAuthorization()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
