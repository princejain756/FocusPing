import Foundation
import SwiftData
import SwiftUI
import UserNotifications

/// Automated simulator QA. Launch with: `-QATest`
/// Prints `QA_PASS:` / `QA_FAIL:` lines to stdout for log parsing.
enum QATestHarness {
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-QATest")
    }

    @MainActor
    static func run(context: ModelContext) async {
        let appModel = AppModel()
        appModel.hasCompletedOnboarding = true
        appModel.notificationsAuthorized = true
        appModel.focusStatusAuthorized = true
        appModel.focusSnapshot = .unfocused
        appModel.manualQuietMode = false

        let store = PingStore()
        var passed = 0
        var failed = 0
        var resultLines: [String] = []

        func appendResult(_ line: String) {
            resultLines.append(line)
        }

        _ = await NotificationService.shared.requestAuthorization()

        func recordPass(_ name: String) {
            passed += 1
            print("QA_PASS: \(name)")
            NSLog("QA_PASS: %@", name)
            appendResult("PASS:\(name)")
        }

        func recordFail(_ name: String, _ detail: String) {
            failed += 1
            print("QA_FAIL: \(name) — \(detail)")
            NSLog("QA_FAIL: %@ — %@", name, detail)
            appendResult("FAIL:\(name):\(detail)")
        }

        // 1. Future scheduled ping must NOT queue immediately
        do {
            let name = "futureScheduledPingNotQueued"
            clearAll(context: context, store: store)
            appModel.manualQuietMode = false
            appModel.focusSnapshot = .unfocused
            let due = Date().addingTimeInterval(3600)
            await store.addPing(
                title: "Future ping",
                note: "",
                iconSymbol: "bell.fill",
                dueAt: due,
                holdDuringFocus: true,
                repeatDaily: false,
                context: context,
                appModel: appModel
            )
            store.refreshCounts(context: context)
            if store.queuedCount != 0 {
                recordFail(name, "queuedCount should be 0, got \(store.queuedCount)")
            } else {
                try? await Task.sleep(for: .milliseconds(500))
                let pending = await pendingNotifications(matching: context)
                if pending.isEmpty {
                    recordFail(name, "expected pending notification for future ping")
                } else {
                    recordPass(name)
                }
            }
        }

        // 2. Immediate ping during Deep Work must queue
        do {
            let name = "immediatePingDuringDeepWorkQueues"
            clearAll(context: context, store: store)
            appModel.setManualQuietMode(true)
            appModel.focusSnapshot = .manualQuiet
            await store.addPing(
                title: "Now ping",
                note: "",
                iconSymbol: "bell.fill",
                dueAt: nil,
                holdDuringFocus: true,
                repeatDaily: false,
                context: context,
                appModel: appModel
            )
            store.refreshCounts(context: context)
            if store.queuedCount != 1 {
                recordFail(name, "queuedCount should be 1, got \(store.queuedCount)")
            } else {
                recordPass(name)
            }
        }

        // 3. Release queue clears held pings
        do {
            let name = "releaseAllClearsQueue"
            clearAll(context: context, store: store)
            appModel.setManualQuietMode(true)
            appModel.focusSnapshot = .manualQuiet
            await store.addPing(
                title: "Held A",
                note: "",
                iconSymbol: "bell.fill",
                dueAt: nil,
                holdDuringFocus: true,
                repeatDaily: false,
                context: context,
                appModel: appModel
            )
            await store.addPing(
                title: "Held B",
                note: "",
                iconSymbol: "bell.fill",
                dueAt: nil,
                holdDuringFocus: true,
                repeatDaily: false,
                context: context,
                appModel: appModel
            )
            store.refreshCounts(context: context)
            if store.queuedCount < 2 {
                recordFail(name, "expected 2 queued, got \(store.queuedCount)")
            } else {
                appModel.setManualQuietMode(false)
                appModel.focusSnapshot = .unfocused
                await store.releaseAllQueued(context: context, appModel: appModel)
                store.refreshCounts(context: context)
                if store.queuedCount != 0 {
                    recordFail(name, "queuedCount should be 0 after release, got \(store.queuedCount)")
                } else {
                    recordPass(name)
                }
            }
        }

        // 4. Snooze removes from queue and schedules future delivery
        do {
            let name = "snoozeRequeuesWithSchedule"
            clearAll(context: context, store: store)
            appModel.setManualQuietMode(true)
            appModel.focusSnapshot = .manualQuiet
            await store.addPing(
                title: "Snooze me",
                note: "",
                iconSymbol: "bell.fill",
                dueAt: nil,
                holdDuringFocus: true,
                repeatDaily: false,
                context: context,
                appModel: appModel
            )
            let pings = (try? context.fetch(FetchDescriptor<Ping>())) ?? []
            guard let ping = pings.first else {
                recordFail(name, "ping not found")
                print("QA_SUMMARY: pass=\(passed) fail=\(failed)")
                writeResultsFile(passed: passed, failed: failed, lines: resultLines)
                return
            }
            await store.snoozePing(ping, minutes: 15, context: context, appModel: appModel)
            store.refreshCounts(context: context)
            if store.queuedCount != 0 {
                recordFail(name, "snooze should remove from queue, queued=\(store.queuedCount)")
            } else if ping.dueAt == nil {
                recordFail(name, "snooze should set dueAt")
            } else if ping.dueAt! <= Date() {
                recordFail(name, "snooze dueAt should be in the future")
            } else {
                recordPass(name)
            }
        }

        print("QA_SUMMARY: pass=\(passed) fail=\(failed)")
        NSLog("QA_SUMMARY: pass=%d fail=%d", passed, failed)
        writeResultsFile(passed: passed, failed: failed, lines: resultLines)
    }

    @MainActor
    private static func writeResultsFile(passed: Int, failed: Int, lines: [String]) {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        var body = lines.joined(separator: "\n")
        body += "\npass=\(passed)\nfail=\(failed)\ncomplete=1\n"
        try? body.write(to: docs.appendingPathComponent("focusping-qa.txt"), atomically: true, encoding: .utf8)
    }

    @MainActor
    private static func clearAll(context: ModelContext, store: PingStore) {
        let pings = (try? context.fetch(FetchDescriptor<Ping>())) ?? []
        let queue = (try? context.fetch(FetchDescriptor<QueuedDelivery>())) ?? []
        pings.forEach { context.delete($0) }
        queue.forEach { context.delete($0) }
        try? context.save()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        store.refreshCounts(context: context)
    }

    private static func pendingNotifications(matching context: ModelContext) async -> [UNNotificationRequest] {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let pings = (try? context.fetch(FetchDescriptor<Ping>())) ?? []
        let ids = Set(pings.map { $0.id.uuidString })
        return pending.filter { ids.contains($0.identifier) }
    }
}

struct QATestRunnerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var summary = "Running QA…"

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text(summary)
                .font(.footnote.monospaced())
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .foregroundStyle(.white)
        .task {
            await QATestHarness.run(context: modelContext)
            summary = "QA complete — see console for QA_PASS/QA_FAIL"
        }
    }
}
