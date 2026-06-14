import Foundation
import SwiftData

/// Seeds deterministic UI state for App Store / website screenshots.
/// Launch with: `-MarketingScreenshots <onboarding|home|queue|settings>`
enum MarketingScreenshotSeeder {
    enum Screen: String {
        case onboarding
        case home
        case queue
        case settings
    }

    static var activeScreen: Screen? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-MarketingScreenshots"),
              index + 1 < args.count else { return nil }
        return Screen(rawValue: args[index + 1])
    }

    static var isActive: Bool { activeScreen != nil }

    @MainActor
    static func apply(screen: Screen, appModel: AppModel, context: ModelContext) {
        switch screen {
        case .onboarding:
            UserDefaults.standard.set(false, forKey: SettingsKey.hasCompletedOnboarding)
            appModel.hasCompletedOnboarding = false
            appModel.notificationsAuthorized = false
            appModel.focusStatusAuthorized = false
            appModel.manualQuietMode = false

        case .home:
            finishOnboarding(appModel)
            appModel.manualQuietMode = false
            appModel.screenshotInitialTab = 0
            seedHome(context: context, appModel: appModel)

        case .queue:
            finishOnboarding(appModel)
            appModel.manualQuietMode = true
            appModel.focusSnapshot = .manualQuiet
            appModel.screenshotInitialTab = 1
            seedQueue(context: context)

        case .settings:
            finishOnboarding(appModel)
            appModel.useDeliveryWindow = true
            appModel.screenshotInitialTab = 3
            seedHome(context: context, appModel: appModel)
        }
    }

    @MainActor
    private static func finishOnboarding(_ appModel: AppModel) {
        appModel.hasCompletedOnboarding = true
        appModel.notificationsAuthorized = true
        appModel.focusStatusAuthorized = true
        UserDefaults.standard.set(true, forKey: SettingsKey.hasCompletedOnboarding)
    }

    @MainActor
    private static func seedHome(context: ModelContext, appModel: AppModel) {
        clearData(context: context)
        let pings: [(String, String, String)] = [
            ("Take medication", "Morning dose when you can act.", "pills.fill"),
            ("Drink water", "Hydrate when you are ready.", "drop.fill"),
            ("Send that message", "Reply when you have capacity.", "message.fill"),
        ]
        for (title, note, symbol) in pings {
            let ping = Ping(title: title, note: note, iconSymbol: symbol, holdDuringFocus: true)
            context.insert(ping)
        }
        try? context.save()
        appModel.focusSnapshot = .unfocused
    }

    @MainActor
    private static func seedQueue(context: ModelContext) {
        clearData(context: context)
        let queued: [(String, String, String, String)] = [
            ("Take medication", "Held during Deep Work", "pills.fill", "Deep Work"),
            ("Time to leave", "Waiting for you to be ready", "figure.walk", "Deep Work"),
            ("Resume what you started", "Pick up where you left off.", "arrow.uturn.forward.circle.fill", "Focus"),
        ]
        for (title, note, symbol, reason) in queued {
            let ping = Ping(title: title, note: note, iconSymbol: symbol, holdDuringFocus: true)
            context.insert(ping)
            let delivery = QueuedDelivery(pingID: ping.id, title: title, note: note, iconSymbol: symbol, reason: reason)
            context.insert(delivery)
        }
        try? context.save()
    }

    @MainActor
    private static func clearData(context: ModelContext) {
        let pings = (try? context.fetch(FetchDescriptor<Ping>())) ?? []
        let queue = (try? context.fetch(FetchDescriptor<QueuedDelivery>())) ?? []
        pings.forEach { context.delete($0) }
        queue.forEach { context.delete($0) }
        try? context.save()
    }
}
