import AppIntents
import Foundation

struct ToggleDeepWorkIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Deep Work"
    static var description = IntentDescription("Turn Deep Work mode on or off in FocusPing.")

    @Parameter(title: "Enable Deep Work")
    var enable: Bool

    init() {}

    init(enable: Bool) {
        self.enable = enable
    }

    func perform() async throws -> some IntentResult {
        AppGroupStore.requestDeepWorkToggle(enabled: enable)
        return .result()
    }
}

struct EnableDeepWorkIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Deep Work"
    static var description = IntentDescription("Hold pings until you turn Deep Work off.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        AppGroupStore.requestDeepWorkToggle(enabled: true)
        return .result()
    }
}

struct DisableDeepWorkIntent: AppIntent {
    static var title: LocalizedStringResource = "End Deep Work"
    static var description = IntentDescription("Release held pings when you are ready.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        AppGroupStore.requestDeepWorkToggle(enabled: false)
        return .result()
    }
}

struct AddQuickPingIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Ping"
    static var description = IntentDescription("Queue a reminder in FocusPing.")
    static var openAppWhenRun = true

    @Parameter(title: "Reminder")
    var title: String

    init() {
        self.title = ""
    }

    init(title: String) {
        self.title = title
    }

    func perform() async throws -> some IntentResult {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw IntentError.emptyTitle
        }
        AppGroupStore.queueQuickPing(title: trimmed)
        return .result(dialog: "Added \"\(trimmed)\" to FocusPing")
    }
}

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case emptyTitle

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .emptyTitle:
            return "Say what you want to remember."
        }
    }
}
