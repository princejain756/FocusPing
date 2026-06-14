import Foundation
import UserNotifications

actor NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        await registerCategories()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func registerCategories() async {
        let done = UNNotificationAction(
            identifier: NotificationAction.done,
            title: "Done",
            options: []
        )
        let snooze = UNNotificationAction(
            identifier: NotificationAction.snooze,
            title: "Snooze 15m",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: NotificationAction.categoryID,
            actions: [done, snooze],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    func schedulePing(_ ping: Ping) async {
        guard let dueAt = ping.dueAt, dueAt > Date() else { return }
        let content = makeContent(for: ping, body: ping.note.isEmpty ? "FocusPing reminder" : ping.note)
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: dueAt
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: ping.repeatDaily)
        let request = UNNotificationRequest(
            identifier: ping.id.uuidString,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    func cancelPing(_ ping: Ping) async {
        center.removePendingNotificationRequests(withIdentifiers: [ping.id.uuidString])
        center.removeDeliveredNotifications(withIdentifiers: [ping.id.uuidString])
    }

    func deliverNow(for ping: Ping) async {
        let content = makeContent(
            for: ping,
            body: ping.note.isEmpty ? "Ready when you are." : ping.note
        )
        let request = UNNotificationRequest(
            identifier: "deliver-\(ping.id.uuidString)-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        try? await center.add(request)
    }

    func deliverQueuedSummary(count: Int) async {
        guard count > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = count == 1 ? "1 ping is ready" : "\(count) pings are ready"
        content.body = "You are available again. Tap to open FocusPing."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "queue-summary-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        try? await center.add(request)
    }

    func scheduleSnooze(for ping: Ping, minutes: Int) async {
        await cancelPing(ping)
        let content = makeContent(for: ping, body: ping.note.isEmpty ? "Snoozed reminder" : ping.note)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(
            identifier: ping.id.uuidString,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    private func makeContent(for ping: Ping, body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = ping.title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = NotificationAction.categoryID
        content.userInfo = ["pingID": ping.id.uuidString]
        return content
    }
}
