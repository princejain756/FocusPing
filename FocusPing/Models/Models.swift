import Foundation
import SwiftData

@Model
final class Ping: Identifiable {
    var id: UUID
    var title: String
    var note: String
    var iconSymbol: String
    var createdAt: Date
    var dueAt: Date?
    var isCompleted: Bool
    var holdDuringFocus: Bool
    var repeatDaily: Bool
    var completedAt: Date?

    init(
        title: String,
        note: String = "",
        iconSymbol: String = "bell.fill",
        dueAt: Date? = nil,
        holdDuringFocus: Bool = true,
        repeatDaily: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.note = note
        self.iconSymbol = iconSymbol
        self.createdAt = Date()
        self.dueAt = dueAt
        self.isCompleted = false
        self.holdDuringFocus = holdDuringFocus
        self.repeatDaily = repeatDaily
        self.completedAt = nil
    }
}

@Model
final class QueuedDelivery: Identifiable {
    var id: UUID
    var pingID: UUID
    var title: String
    var note: String
    var iconSymbol: String
    var queuedAt: Date
    var reason: String

    init(pingID: UUID, title: String, note: String, iconSymbol: String = "bell.fill", reason: String) {
        self.id = UUID()
        self.pingID = pingID
        self.title = title
        self.note = note
        self.iconSymbol = iconSymbol
        self.queuedAt = Date()
        self.reason = reason
    }
}

struct PingTemplate: Identifiable, Hashable {
    let id: String
    let title: String
    let note: String
    let symbol: String

    static let all: [PingTemplate] = [
        PingTemplate(id: "meds", title: "Take medication", note: "Now that you can act on it.", symbol: "pills.fill"),
        PingTemplate(id: "resume", title: "Resume what you started", note: "Pick up where you left off.", symbol: "arrow.uturn.forward.circle.fill"),
        PingTemplate(id: "water", title: "Drink water", note: "Hydrate when you are ready.", symbol: "drop.fill"),
        PingTemplate(id: "leave", title: "Time to leave", note: "Head out when context allows.", symbol: "figure.walk"),
        PingTemplate(id: "call", title: "Send that message", note: "Reply or reach out now.", symbol: "message.fill"),
        PingTemplate(id: "custom", title: "Custom ping", note: "", symbol: "bell.badge.fill")
    ]
}

struct DeliveryWindow: Codable, Equatable {
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int

    static let defaultWindow = DeliveryWindow(startHour: 8, startMinute: 0, endHour: 22, endMinute: 0)

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return true }
        let current = hour * 60 + minute
        let start = startHour * 60 + startMinute
        let end = endHour * 60 + endMinute
        if start <= end {
            return current >= start && current <= end
        }
        return current >= start || current <= end
    }
}

enum FocusSnapshot: Equatable {
    case unknown
    case unfocused
    case focused
    case manualQuiet

    var blocksDelivery: Bool {
        switch self {
        case .focused, .manualQuiet:
            return true
        case .unknown, .unfocused:
            return false
        }
    }

    var label: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .unfocused:
            return "Available"
        case .focused:
            return "In Focus"
        case .manualQuiet:
            return "Deep Work"
        }
    }

    var subtitle: String {
        switch self {
        case .unknown:
            return "Share Focus Status for auto-hold"
        case .unfocused:
            return "Pings deliver normally"
        case .focused:
            return "Pings wait in queue"
        case .manualQuiet:
            return "Manual hold active"
        }
    }

    var systemImage: String {
        switch self {
        case .unknown:
            return "questionmark.circle"
        case .unfocused:
            return "checkmark.circle.fill"
        case .focused:
            return "moon.fill"
        case .manualQuiet:
            return "brain.head.profile"
        }
    }
}

enum QueueReason: String {
    case focus = "Held during Focus"
    case window = "Outside delivery window"
    case manualQuiet = "Deep Work mode on"
}

enum SettingsKey {
    static let manualQuietMode = "focusping.manualQuietMode"
    static let deliveryWindow = "focusping.deliveryWindow"
    static let useDeliveryWindow = "focusping.useDeliveryWindow"
    static let hasCompletedOnboarding = "focusping.hasCompletedOnboarding"
    static let hasSeenQueueTip = "focusping.hasSeenQueueTip"
    static let reviewPrompted = "focusping.reviewPrompted"
}

enum NotificationAction {
    static let categoryID = "PING_DELIVERY"
    static let done = "DONE"
    static let snooze = "SNOOZE"
}
