import Foundation

enum AppGroupConstants {
    static let suiteName = "group.com.focusping.shared"
    static let snapshotKey = "widgetSnapshot"
    static let deepWorkToggleKey = "deepWorkToggleRequested"
    static let quickPingTitleKey = "pendingQuickPingTitle"
    static let quickPingOpenAddKey = "pendingOpenAddPing"
}

struct WidgetSnapshot: Codable, Equatable {
    var queuedCount: Int
    var activeCount: Int
    var deepWorkEnabled: Bool
    var focusLabel: String
    var nextQueuedTitle: String?
    var updatedAt: Date

    static let empty = WidgetSnapshot(
        queuedCount: 0,
        activeCount: 0,
        deepWorkEnabled: false,
        focusLabel: "Available",
        nextQueuedTitle: nil,
        updatedAt: Date()
    )
}

enum AppGroupStore {
    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConstants.suiteName)
    }

    static func saveSnapshot(_ snapshot: WidgetSnapshot) {
        guard let defaults else { return }
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: AppGroupConstants.snapshotKey)
        }
    }

    static func loadSnapshot() -> WidgetSnapshot {
        guard let defaults,
              let data = defaults.data(forKey: AppGroupConstants.snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }

    static func consumeDeepWorkToggleRequest() -> Bool? {
        guard let defaults else { return nil }
        guard defaults.object(forKey: AppGroupConstants.deepWorkToggleKey) != nil else { return nil }
        let value = defaults.bool(forKey: AppGroupConstants.deepWorkToggleKey)
        defaults.removeObject(forKey: AppGroupConstants.deepWorkToggleKey)
        return value
    }

    static func requestDeepWorkToggle(enabled: Bool) {
        defaults?.set(enabled, forKey: AppGroupConstants.deepWorkToggleKey)
        applyDeepWorkState(enabled)
    }

    static func applyDeepWorkState(_ enabled: Bool) {
        var snapshot = loadSnapshot()
        snapshot.deepWorkEnabled = enabled
        snapshot.focusLabel = enabled ? "Deep Work" : "Available"
        snapshot.updatedAt = Date()
        saveSnapshot(snapshot)
    }

    static func queueQuickPing(title: String) {
        defaults?.set(title, forKey: AppGroupConstants.quickPingTitleKey)
    }

    static func consumeQuickPingTitle() -> String? {
        guard let defaults else { return nil }
        guard let title = defaults.string(forKey: AppGroupConstants.quickPingTitleKey) else { return nil }
        defaults.removeObject(forKey: AppGroupConstants.quickPingTitleKey)
        return title
    }

    static func requestOpenAddPing() {
        defaults?.set(true, forKey: AppGroupConstants.quickPingOpenAddKey)
    }

    static func consumeOpenAddPingRequest() -> Bool {
        guard let defaults else { return false }
        let value = defaults.bool(forKey: AppGroupConstants.quickPingOpenAddKey)
        if value {
            defaults.removeObject(forKey: AppGroupConstants.quickPingOpenAddKey)
        }
        return value
    }
}
