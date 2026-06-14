import Foundation

/// Captures ping state for undo-after-delete (HIG: prefer undo over confirmation).
struct PingSnapshot: Identifiable {
    let id: UUID
    let title: String
    let note: String
    let iconSymbol: String
    let createdAt: Date
    let dueAt: Date?
    let holdDuringFocus: Bool
    let repeatDaily: Bool

    init(from ping: Ping) {
        id = ping.id
        title = ping.title
        note = ping.note
        iconSymbol = ping.iconSymbol
        createdAt = ping.createdAt
        dueAt = ping.dueAt
        holdDuringFocus = ping.holdDuringFocus
        repeatDaily = ping.repeatDaily
    }

    func makePing() -> Ping {
        let ping = Ping(
            title: title,
            note: note,
            iconSymbol: iconSymbol,
            dueAt: dueAt,
            holdDuringFocus: holdDuringFocus,
            repeatDaily: repeatDaily
        )
        ping.id = id
        ping.createdAt = createdAt
        return ping
    }
}
