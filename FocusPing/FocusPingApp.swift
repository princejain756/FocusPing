import SwiftUI
import SwiftData

@main
struct FocusPingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if QATestHarness.isActive {
                    QATestRunnerView()
                } else {
                    RootView()
                        .environment(appModel)
                }
            }
            .modelContainer(for: [Ping.self, QueuedDelivery.self])
            .task {
                guard !QATestHarness.isActive, MarketingScreenshotSeeder.activeScreen == nil else { return }
                await appModel.bootstrap()
            }
            .environment(appModel)
        }
    }
}
