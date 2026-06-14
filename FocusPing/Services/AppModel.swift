import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class AppModel {
    var focusSnapshot: FocusSnapshot = .unknown
    var focusStatusAuthorized = false
    var notificationsAuthorized = false
    var manualQuietMode = false
    var deliveryWindow = DeliveryWindow.defaultWindow
    var useDeliveryWindow = false
    var lastQueueFlushAt: Date?
    var hasCompletedOnboarding = false
    var screenshotInitialTab: Int?

    private let focusMonitor = FocusMonitor()
    private let notificationService = NotificationService.shared
    private var monitorTask: Task<Void, Never>?

    func bootstrap() async {
        if let screen = MarketingScreenshotSeeder.activeScreen {
            hasCompletedOnboarding = screen != .onboarding
            notificationsAuthorized = screen != .onboarding
            focusStatusAuthorized = screen != .onboarding
            loadSettings()
            if screen != .onboarding {
                startMonitoring()
                await refreshFocusState()
            }
            return
        }

        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: SettingsKey.hasCompletedOnboarding)
        loadSettings()
        await notificationService.registerCategories()
        await refreshAuthorizationStatus()
        if hasCompletedOnboarding {
            startMonitoring()
            await refreshFocusState()
        }
    }

    func finishOnboarding() async {
        completeOnboarding()
        await refreshAuthorizationStatus()
        startMonitoring()
        await refreshFocusState()
    }

    func refreshAuthorizationStatus() async {
        notificationsAuthorized = await notificationService.isAuthorized()
        focusStatusAuthorized = await focusMonitor.isAuthorized()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: SettingsKey.hasCompletedOnboarding)
    }

    func requestNotifications() async {
        notificationsAuthorized = await notificationService.requestAuthorization()
    }

    func requestFocusStatus() async {
        focusStatusAuthorized = await focusMonitor.requestAuthorizationIfNeeded()
        await refreshFocusState()
    }

    func startMonitoring() {
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.refreshFocusState()
                try? await Task.sleep(for: .seconds(12))
            }
        }
    }

    func refreshFocusState() async {
        if manualQuietMode {
            focusSnapshot = .manualQuiet
            return
        }
        focusSnapshot = await focusMonitor.currentSnapshot()
    }

    func toggleManualQuietMode() {
        setManualQuietMode(!manualQuietMode)
    }

    func setManualQuietMode(_ enabled: Bool) {
        manualQuietMode = enabled
        UserDefaults.standard.set(manualQuietMode, forKey: SettingsKey.manualQuietMode)
        Task { await refreshFocusState() }
    }

    func saveDeliveryWindow() {
        if let data = try? JSONEncoder().encode(deliveryWindow) {
            UserDefaults.standard.set(data, forKey: SettingsKey.deliveryWindow)
        }
        UserDefaults.standard.set(useDeliveryWindow, forKey: SettingsKey.useDeliveryWindow)
    }

    private func loadSettings() {
        manualQuietMode = UserDefaults.standard.bool(forKey: SettingsKey.manualQuietMode)
        useDeliveryWindow = UserDefaults.standard.bool(forKey: SettingsKey.useDeliveryWindow)
        if let data = UserDefaults.standard.data(forKey: SettingsKey.deliveryWindow),
           let window = try? JSONDecoder().decode(DeliveryWindow.self, from: data) {
            deliveryWindow = window
        }
    }

    func shouldHoldDelivery(holdDuringFocus: Bool, at date: Date = Date()) -> (hold: Bool, reason: QueueReason?) {
        if holdDuringFocus && focusSnapshot.blocksDelivery {
            return (true, focusSnapshot == .manualQuiet ? .manualQuiet : .focus)
        }
        if useDeliveryWindow && !deliveryWindow.contains(date) {
            return (true, .window)
        }
        return (false, nil)
    }

    func deliverQueuedItems(
        queue: [QueuedDelivery],
        context: ModelContext,
        pingStore: PingStore
    ) async {
        guard !queue.isEmpty else { return }
        for item in queue {
            if let ping = pingStore.findPing(id: item.pingID, context: context) {
                await notificationService.deliverNow(for: ping)
                if ping.dueAt == nil {
                    ping.isCompleted = true
                    ping.completedAt = Date()
                }
            }
            context.delete(item)
        }
        lastQueueFlushAt = Date()
        try? context.save()
        pingStore.refreshCounts(context: context)
        HapticService.success()
    }
}
