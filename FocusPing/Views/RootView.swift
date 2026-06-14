import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var pingStore = PingStore()
    @State private var selectedTab = 0
    @Bindable private var bannerService = BannerService.shared

    var body: some View {
        Group {
            if appModel.hasCompletedOnboarding {
                mainTabs
            } else {
                OnboardingView()
            }
        }
        .bannerOverlay(bannerService)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await syncEngine() }
        }
        .onChange(of: appModel.focusSnapshot) { _, _ in
            Task { await syncEngine() }
        }
        .onChange(of: appModel.manualQuietMode) { _, _ in
            Task { await publishSurfaceState() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusPingBackgroundRefresh)) { _ in
            Task { await syncEngine() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusPingCompleteFromNotification)) { note in
            guard let idString = note.userInfo?["pingID"] as? String,
                  let id = UUID(uuidString: idString) else { return }
            Task {
                await pingStore.completePing(id: id, context: modelContext)
                await publishSurfaceState()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusPingSnoozeFromNotification)) { note in
            guard let idString = note.userInfo?["pingID"] as? String,
                  let id = UUID(uuidString: idString),
                  let ping = pingStore.findPing(id: id, context: modelContext) else { return }
            let minutes = note.userInfo?["minutes"] as? Int ?? 15
            Task {
                await pingStore.snoozePing(ping, minutes: minutes, context: modelContext)
                await publishSurfaceState()
            }
        }
        .task {
            pingStore.refreshCounts(context: modelContext)
            await publishSurfaceState()
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            HomeView(pingStore: pingStore, selectedTab: $selectedTab)
                .tabItem {
                    Label("Pings", systemImage: "bell.badge")
                }
                .tag(0)

            QueueView(pingStore: pingStore)
                .tabItem {
                    Label("Queue", systemImage: "tray.full")
                }
                .badge(pingStore.queuedCount)
                .tag(1)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "checkmark.seal")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
        .tint(FocusTheme.accent)
    }

    private func syncEngine() async {
        WidgetSyncService.applyWidgetRequests(appModel: appModel)
        await WidgetSyncService.applyPendingQuickActions(
            context: modelContext,
            appModel: appModel,
            pingStore: pingStore
        )
        await appModel.refreshFocusState()
        await pingStore.processDuePings(context: modelContext, appModel: appModel)
        await pingStore.processAmbientPings(context: modelContext, appModel: appModel)
        await pingStore.flushQueueIfAllowed(context: modelContext, appModel: appModel)
        await publishSurfaceState()
    }

    private func publishSurfaceState() async {
        WidgetSyncService.sync(context: modelContext, appModel: appModel, pingStore: pingStore)
        let queue = (try? modelContext.fetch(FetchDescriptor<QueuedDelivery>())) ?? []
        LiveActivityService.update(
            queuedCount: pingStore.queuedCount,
            focusLabel: appModel.focusSnapshot.label,
            nextTitle: queue.first?.title,
            deepWorkEnabled: appModel.manualQuietMode
        )
    }
}
