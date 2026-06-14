import SwiftUI
import SwiftData

@main
struct FocusPingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
                .modelContainer(for: [Ping.self, QueuedDelivery.self])
                .task {
                    guard MarketingScreenshotSeeder.activeScreen == nil else { return }
                    await appModel.bootstrap()
                }
        }
    }
}
