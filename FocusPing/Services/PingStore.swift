import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class PingStore {
    var activeCount = 0
    var queuedCount = 0
    var completedTodayCount = 0
    var totalCompletedCount = 0

    private let notificationService = NotificationService.shared

    func refreshCounts(context: ModelContext) {
        let pings = (try? context.fetch(FetchDescriptor<Ping>())) ?? []
        let queue = (try? context.fetch(FetchDescriptor<QueuedDelivery>())) ?? []
        activeCount = pings.filter { !$0.isCompleted }.count
        queuedCount = queue.count

        let startOfDay = Calendar.current.startOfDay(for: Date())
        completedTodayCount = pings.filter {
            $0.isCompleted && ($0.completedAt ?? $0.createdAt) >= startOfDay
        }.count
        totalCompletedCount = pings.filter(\.isCompleted).count
    }

    func findPing(id: UUID, context: ModelContext) -> Ping? {
        let all = (try? context.fetch(FetchDescriptor<Ping>())) ?? []
        return all.first { $0.id == id }
    }

    func addPing(
        title: String,
        note: String,
        iconSymbol: String,
        dueAt: Date?,
        holdDuringFocus: Bool,
        repeatDaily: Bool,
        context: ModelContext,
        appModel: AppModel
    ) async {
        let ping = Ping(
            title: title,
            note: note,
            iconSymbol: iconSymbol,
            dueAt: dueAt,
            holdDuringFocus: holdDuringFocus,
            repeatDaily: repeatDaily
        )
        context.insert(ping)
        if let dueAt, dueAt > Date() {
            await notificationService.schedulePing(ping)
        } else {
            await routePing(ping, context: context, appModel: appModel, at: dueAt ?? Date())
        }
        try? context.save()
        refreshCounts(context: context)
        HapticService.success()
    }

    func completePing(_ ping: Ping, context: ModelContext) async {
        ping.isCompleted = true
        ping.completedAt = Date()
        await notificationService.cancelPing(ping)
        removeFromQueue(pingID: ping.id, context: context)
        try? context.save()
        refreshCounts(context: context)
        HapticService.light()
        StoreReviewService.considerPrompt(totalCompleted: totalCompletedCount)
    }

    func completePing(id: UUID, context: ModelContext) async {
        guard let ping = findPing(id: id, context: context) else { return }
        await completePing(ping, context: context)
    }

    func snoozePing(_ ping: Ping, minutes: Int, context: ModelContext, appModel: AppModel) async {
        ping.dueAt = Date().addingTimeInterval(TimeInterval(minutes * 60))
        removeFromQueue(pingID: ping.id, context: context)
        await notificationService.cancelPing(ping)
        if let dueAt = ping.dueAt, dueAt > Date() {
            await notificationService.schedulePing(ping)
        } else {
            await routePing(ping, context: context, appModel: appModel, at: Date())
        }
        try? context.save()
        refreshCounts(context: context)
    }

    func deletePing(_ ping: Ping, context: ModelContext) async {
        await notificationService.cancelPing(ping)
        removeFromQueue(pingID: ping.id, context: context)
        context.delete(ping)
        try? context.save()
        refreshCounts(context: context)
    }

    func deletePingWithUndo(_ ping: Ping, context: ModelContext, appModel: AppModel) async {
        let snapshot = PingSnapshot(from: ping)
        await deletePing(ping, context: context)
        BannerService.shared.show(
            "Ping deleted",
            duration: 5,
            undo: "Undo"
        ) { [weak self] in
            Task { @MainActor in
                await self?.restorePing(snapshot, context: context, appModel: appModel)
            }
        }
    }

    func restorePing(_ snapshot: PingSnapshot, context: ModelContext, appModel: AppModel) async {
        let ping = snapshot.makePing()
        context.insert(ping)
        if let dueAt = ping.dueAt, dueAt > Date() {
            await notificationService.schedulePing(ping)
        } else if ping.dueAt == nil {
            await routePing(ping, context: context, appModel: appModel, at: Date())
        }
        try? context.save()
        refreshCounts(context: context)
        HapticService.light()
        BannerService.shared.show("Ping restored")
    }

    func releaseAllQueued(context: ModelContext, appModel: AppModel) async {
        await flushQueueIfAllowed(context: context, appModel: appModel, force: true)
        WidgetSyncService.sync(context: context, appModel: appModel, pingStore: self)
        NotificationCenter.default.post(name: .focusPingBackgroundRefresh, object: nil)
        BannerService.shared.show("Delivered your waiting pings")
    }

    func updatePing(
        _ ping: Ping,
        title: String,
        note: String,
        iconSymbol: String,
        dueAt: Date?,
        holdDuringFocus: Bool,
        repeatDaily: Bool,
        context: ModelContext,
        appModel: AppModel
    ) async {
        ping.title = title
        ping.note = note
        ping.iconSymbol = iconSymbol
        ping.dueAt = dueAt
        ping.holdDuringFocus = holdDuringFocus
        ping.repeatDaily = repeatDaily

        await notificationService.cancelPing(ping)
        removeFromQueue(pingID: ping.id, context: context)

        if let dueAt, dueAt > Date() {
            await notificationService.schedulePing(ping)
        } else {
            await routePing(ping, context: context, appModel: appModel, at: Date())
        }

        try? context.save()
        refreshCounts(context: context)
    }

    func addQuickPing(title: String, context: ModelContext, appModel: AppModel) async {
        await addPing(
            title: title,
            note: "",
            iconSymbol: "bell.fill",
            dueAt: nil,
            holdDuringFocus: true,
            repeatDaily: false,
            context: context,
            appModel: appModel
        )
    }

    func duplicatePing(_ ping: Ping, context: ModelContext, appModel: AppModel) async {
        await addPing(
            title: ping.title,
            note: ping.note,
            iconSymbol: ping.iconSymbol,
            dueAt: ping.dueAt,
            holdDuringFocus: ping.holdDuringFocus,
            repeatDaily: ping.repeatDaily,
            context: context,
            appModel: appModel
        )
        BannerService.shared.show("Ping duplicated")
    }

    func releaseQueueItem(_ item: QueuedDelivery, context: ModelContext, appModel: AppModel) async {
        if let ping = findPing(id: item.pingID, context: context) {
            await notificationService.deliverNow(for: ping)
        }
        context.delete(item)
        try? context.save()
        refreshCounts(context: context)
        HapticService.light()
    }

    func processDuePings(context: ModelContext, appModel: AppModel) async {
        let pings = (try? context.fetch(FetchDescriptor<Ping>())) ?? []
        let now = Date()

        for ping in pings where !ping.isCompleted {
            guard let dueAt = ping.dueAt, dueAt <= now else { continue }
            await routePing(ping, context: context, appModel: appModel, at: now, advanceSchedule: true)
        }
        try? context.save()
        refreshCounts(context: context)
    }

    func processAmbientPings(context: ModelContext, appModel: AppModel) async {
        let pings = (try? context.fetch(FetchDescriptor<Ping>())) ?? []
        for ping in pings where !ping.isCompleted && ping.dueAt == nil {
            let hold = appModel.shouldHoldDelivery(holdDuringFocus: ping.holdDuringFocus)
            if hold.hold, let reason = hold.reason, !isQueued(pingID: ping.id, context: context) {
                enqueue(ping: ping, reason: reason, context: context)
            }
        }
        try? context.save()
        refreshCounts(context: context)
    }

    func flushQueueIfAllowed(context: ModelContext, appModel: AppModel, force: Bool = false) async {
        if !force {
            guard !appModel.focusSnapshot.blocksDelivery else { return }
            if appModel.useDeliveryWindow && !appModel.deliveryWindow.contains(Date()) {
                return
            }
        }

        let queue = (try? context.fetch(FetchDescriptor<QueuedDelivery>())) ?? []
        if !force && queue.count >= 2 {
            await appModel.deliverQueuedSummary(queue: queue, context: context, pingStore: self)
        } else {
            await appModel.deliverQueuedItems(queue: queue, context: context, pingStore: self)
        }
    }

    private func routePing(
        _ ping: Ping,
        context: ModelContext,
        appModel: AppModel,
        at date: Date,
        advanceSchedule: Bool = false
    ) async {
        let hold = appModel.shouldHoldDelivery(holdDuringFocus: ping.holdDuringFocus, at: date)
        if hold.hold, let reason = hold.reason {
            enqueue(ping: ping, reason: reason, context: context)
            if advanceSchedule, let dueAt = ping.dueAt {
                if ping.repeatDaily {
                    await notificationService.cancelPing(ping)
                    ping.dueAt = Calendar.current.date(byAdding: .day, value: 1, to: dueAt)
                    await notificationService.schedulePing(ping)
                } else {
                    ping.dueAt = nil
                }
            }
        } else {
            removeFromQueue(pingID: ping.id, context: context)
            await notificationService.deliverNow(for: ping)
            if advanceSchedule, let dueAt = ping.dueAt {
                if ping.repeatDaily {
                    ping.dueAt = Calendar.current.date(byAdding: .day, value: 1, to: dueAt)
                    await notificationService.schedulePing(ping)
                } else {
                    ping.isCompleted = true
                    ping.completedAt = Date()
                }
            } else if ping.dueAt == nil {
                ping.isCompleted = true
                ping.completedAt = Date()
            }
        }
    }

    func requeuePing(_ ping: Ping, reason: QueueReason, context: ModelContext) async {
        enqueue(ping: ping, reason: reason, context: context)
        try? context.save()
        refreshCounts(context: context)
    }

    private func enqueue(ping: Ping, reason: QueueReason, context: ModelContext) {
        guard !isQueued(pingID: ping.id, context: context) else { return }
        let item = QueuedDelivery(
            pingID: ping.id,
            title: ping.title,
            note: ping.note,
            iconSymbol: ping.iconSymbol,
            reason: reason.rawValue
        )
        context.insert(item)
        refreshCounts(context: context)
    }

    private func removeFromQueue(pingID: UUID, context: ModelContext) {
        let descriptor = FetchDescriptor<QueuedDelivery>()
        let items = (try? context.fetch(descriptor)) ?? []
        for item in items where item.pingID == pingID {
            context.delete(item)
        }
    }

    private func isQueued(pingID: UUID, context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<QueuedDelivery>()
        let items = (try? context.fetch(descriptor)) ?? []
        return items.contains { $0.pingID == pingID }
    }
}
