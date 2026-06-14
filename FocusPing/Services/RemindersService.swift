import EventKit
import Foundation

struct ReminderImportItem: Identifiable, Hashable {
    let id: String
    let title: String
    let note: String
    let dueDate: Date?
}

actor RemindersService {
    static let shared = RemindersService()
    private let store = EKEventStore()

    func authorizationStatus() -> EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .reminder)
    }

    func requestAccess() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await store.requestFullAccessToReminders()
        }
        return try await withCheckedThrowingContinuation { continuation in
            store.requestAccess(to: .reminder) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func fetchIncompleteReminders(limit: Int = 50) async throws -> [ReminderImportItem] {
        let calendars = store.calendars(for: .reminder)
        let predicate = store.predicateForReminders(in: calendars)

        return try await withCheckedThrowingContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                let items = (reminders ?? [])
                    .filter { !$0.isCompleted }
                    .prefix(limit)
                    .map { reminder in
                        ReminderImportItem(
                            id: reminder.calendarItemIdentifier,
                            title: reminder.title ?? "Reminder",
                            note: reminder.notes ?? "",
                            dueDate: reminder.dueDateComponents.flatMap {
                                Calendar.current.date(from: $0)
                            }
                        )
                    }
                continuation.resume(returning: Array(items))
            }
        }
    }
}
