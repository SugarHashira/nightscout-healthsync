import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    static let backgroundTaskIdentifier = "com.diyDiabetes.nightscout-healthsync.refresh"
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        registerBackgroundTasks()
        return true
    }
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundTaskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    func scheduleBackgroundRefresh() {
        Task {
            let interval = await UserSettings.shared.backgroundSyncInterval
            let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
            request.earliestBeginDate = Date(timeIntervalSinceNow: Double(interval) * 60)
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                print("Failed to schedule background refresh: \(error)")
            }
        }
    }
    
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        scheduleBackgroundRefresh() // Schedule next refresh

        let syncTask = Task {
            do {
                try await SyncService.shared.syncAll()
                task.setTaskCompleted(success: true)
            } catch {
                print("Background sync failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
        
        task.expirationHandler = {
            syncTask.cancel()
        }
    }
}
