import Foundation
import SwiftData
import WidgetKit

enum WidgetSyncService {
    @MainActor
    static func sync(context: ModelContext, appModel: AppModel, pingStore: PingStore) {
        let queue = (try? context.fetch(FetchDescriptor<QueuedDelivery>())) ?? []
        let nextTitle = queue.first?.title
        let snapshot = WidgetSnapshot(
            queuedCount: pingStore.queuedCount,
            activeCount: pingStore.activeCount,
            deepWorkEnabled: appModel.manualQuietMode,
            focusLabel: appModel.focusSnapshot.label,
            nextQueuedTitle: nextTitle,
            updatedAt: Date()
        )
        AppGroupStore.saveSnapshot(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    @MainActor
    static func applyWidgetRequests(appModel: AppModel) {
        if let requested = AppGroupStore.consumeDeepWorkToggleRequest() {
            if appModel.manualQuietMode != requested {
                appModel.setManualQuietMode(requested)
                if !requested {
                    BannerService.shared.show("Deep Work ended — checking queue")
                } else {
                    BannerService.shared.show("Deep Work started — pings will wait")
                }
            }
        }
    }

    @MainActor
    static func applyPendingQuickActions(
        context: ModelContext,
        appModel: AppModel,
        pingStore: PingStore
    ) async {
        if AppGroupStore.consumeOpenAddPingRequest() {
            NotificationCenter.default.post(name: .focusPingOpenAddPing, object: nil)
        }
        if let title = AppGroupStore.consumeQuickPingTitle() {
            await pingStore.addQuickPing(title: title, context: context, appModel: appModel)
            BannerService.shared.show("Added \"\(title)\"")
        }
    }
}
