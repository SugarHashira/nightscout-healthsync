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
        lastSyncDate = await settings.lastSyncDate
        isConfigured = nightscoutURL.isEmpty == false && nightscoutSecret.isEmpty == false
    }
    
    func saveSettings() async {
        await settings.nightscoutURL = nightscoutURL
        await settings.nightscoutAPISecret = nightscoutSecret
        await settings.glucoseUnit = selectedGlucoseUnit
        await settings.autoSyncEnabled = autoSyncEnabled
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
