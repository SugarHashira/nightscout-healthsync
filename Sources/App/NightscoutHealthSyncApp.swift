import SwiftUI
import BackgroundTasks

@main
struct NightscoutHealthSyncApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var syncViewModel = SyncViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(syncViewModel)
        }
    }
}
