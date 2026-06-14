import UIKit
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        guard let idString = notification.request.content.userInfo["pingID"] as? String,
              let pingID = UUID(uuidString: idString) else {
            return [.banner, .sound, .badge]
        }

        if DeliveryInterceptService.shared.holdsDelivery(for: pingID) {
            NotificationCenter.default.post(
                name: .focusPingRequeueFromNotification,
                object: nil,
                userInfo: ["pingID": idString]
            )
            return []
        }

        return [.banner, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let pingID = userInfo["pingID"] as? String else { return }

        switch response.actionIdentifier {
        case NotificationAction.done:
            NotificationCenter.default.post(
                name: .focusPingCompleteFromNotification,
                object: nil,
                userInfo: ["pingID": pingID]
            )
        case NotificationAction.snooze:
            NotificationCenter.default.post(
                name: .focusPingSnoozeFromNotification,
                object: nil,
                userInfo: ["pingID": pingID, "minutes": 15]
            )
        case UNNotificationDefaultActionIdentifier:
            NotificationCenter.default.post(name: .focusPingOpenQueue, object: nil)
        default:
            break
        }
    }
}

enum QuickAction {
    static let addPing = "com.focusping.addPing"
    static let startDeepWork = "com.focusping.startDeepWork"
}

extension Notification.Name {
    static let focusPingSnoozeFromNotification = Notification.Name("focusPingSnoozeFromNotification")
    static let focusPingOpenAddPing = Notification.Name("focusPingOpenAddPing")
    static let focusPingOpenQueue = Notification.Name("focusPingOpenQueue")
    static let focusPingRequeueFromNotification = Notification.Name("focusPingRequeueFromNotification")
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    private let notificationDelegate = NotificationDelegate()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        BackgroundRefreshService.register()
        configureQuickActions(for: application)

        if let item = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            handleShortcut(item)
        }

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        BackgroundRefreshService.schedule()
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        handleShortcut(shortcutItem)
        completionHandler(true)
    }

    private func configureQuickActions(for application: UIApplication) {
        application.shortcutItems = [
            UIApplicationShortcutItem(
                type: QuickAction.addPing,
                localizedTitle: "Add Ping",
                localizedSubtitle: "New reminder",
                icon: UIApplicationShortcutIcon(systemImageName: "plus.circle.fill"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: QuickAction.startDeepWork,
                localizedTitle: "Start Deep Work",
                localizedSubtitle: "Hold pings now",
                icon: UIApplicationShortcutIcon(systemImageName: "brain.head.profile"),
                userInfo: nil
            )
        ]
    }

    private func handleShortcut(_ item: UIApplicationShortcutItem) {
        switch item.type {
        case QuickAction.addPing:
            AppGroupStore.requestOpenAddPing()
            NotificationCenter.default.post(name: .focusPingOpenAddPing, object: nil)
        case QuickAction.startDeepWork:
            AppGroupStore.requestDeepWorkToggle(enabled: true)
        default:
            break
        }
    }
}
