import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showingHelp = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: FocusTheme.spacingM) {
                        BrandMark(size: 48)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FocusPing")
                                .font(.headline)
                            Text("Focus Gate v1.4")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button {
                        showingHelp = true
                    } label: {
                        Label("How FocusPing works", systemImage: "lightbulb.fill")
                    }
                } header: {
                    Text("Help")
                }

                Section {
                    Toggle("Manual Deep Work mode", isOn: Binding(
                        get: { appModel.manualQuietMode },
                        set: { _ in
                            HapticService.light()
                            appModel.toggleManualQuietMode()
                        }
                    ))
                } header: {
                    Text("Deep Work")
                } footer: {
                    Text("Hold pings without enabling system Focus. Great for hyperfocus sessions.")
                }

                Section {
                    Toggle("Only deliver inside window", isOn: Binding(
                        get: { appModel.useDeliveryWindow },
                        set: {
                            appModel.useDeliveryWindow = $0
                            appModel.saveDeliveryWindow()
                        }
                    ))
                    if appModel.useDeliveryWindow {
                        DeliveryWindowPreview(
                            window: appModel.deliveryWindow,
                            isEnabled: true
                        )
                        Stepper(
                            "Start: \(formatted(hour: appModel.deliveryWindow.startHour, minute: appModel.deliveryWindow.startMinute))",
                            value: Binding(
                                get: { appModel.deliveryWindow.startHour },
                                set: {
                                    appModel.deliveryWindow.startHour = $0
                                    appModel.saveDeliveryWindow()
                                }
                            ),
                            in: 0...23
                        )
                        Stepper(
                            "End: \(formatted(hour: appModel.deliveryWindow.endHour, minute: appModel.deliveryWindow.endMinute))",
                            value: Binding(
                                get: { appModel.deliveryWindow.endHour },
                                set: {
                                    appModel.deliveryWindow.endHour = $0
                                    appModel.saveDeliveryWindow()
                                }
                            ),
                            in: 0...23
                        )
                    }
                } header: {
                    Text("Delivery window")
                } footer: {
                    Text("Optional quiet hours outside which pings stay queued.")
                }

                Section {
                    permissionRow(
                        title: "Notifications",
                        enabled: appModel.notificationsAuthorized,
                        symbol: "bell.badge.fill"
                    ) {
                        Task { await appModel.requestNotifications() }
                    }
                    permissionRow(
                        title: "Focus Status",
                        enabled: appModel.focusStatusAuthorized,
                        symbol: "moon.fill"
                    ) {
                        Task { await appModel.requestFocusStatus() }
                    }
                    Button("Open iOS Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                } header: {
                    Text("Permissions")
                }

                Section {
                    ShareLink(
                        item: URL(string: "https://focusping.prince.sh")!,
                        subject: Text("FocusPing"),
                        message: Text("Wrong-time notifications stop here. FocusPing delivers reminders when you can actually act.")
                    ) {
                        Label("Share FocusPing", systemImage: "square.and.arrow.up")
                    }
                    tipRow(symbol: "mic.fill", text: "Say \"Start Deep Work in FocusPing\" or add to Shortcuts app")
                    tipRow(symbol: "square.grid.2x2", text: "Add the home screen widget for queue count at a glance")
                    tipRow(symbol: "hand.tap.fill", text: "Long-press the app icon for Add Ping and Deep Work shortcuts")
                    tipRow(symbol: "lock.display", text: "Live Activity shows on Lock Screen during Deep Work")
                    Text("FocusPing holds reminders while you are in Focus and delivers them when you can act. It is not another planner — it is a delivery gate for your brain.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Link("Privacy Policy", destination: URL(string: "https://focusping.prince.sh/privacy")!)
                        .font(.footnote)
                    Link("Support", destination: URL(string: "https://focusping.prince.sh/support")!)
                        .font(.footnote)
                    Link("Email support", destination: URL(string: "mailto:mail@prince.sh")!)
                        .font(.footnote)
                    Link("WhatsApp", destination: URL(string: "https://wa.me/918005634678")!)
                        .font(.footnote)
                    Button("Show onboarding again") {
                        UserDefaults.standard.set(false, forKey: SettingsKey.hasCompletedOnboarding)
                        appModel.hasCompletedOnboarding = false
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingHelp) {
                HelpTipsView()
            }
        }
    }

    private func permissionRow(
        title: String,
        enabled: Bool,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            Label(title, systemImage: symbol)
            Spacer()
            if enabled {
                Text("On")
                    .foregroundStyle(FocusTheme.available)
                    .font(.subheadline.weight(.semibold))
            } else {
                Button("Enable", action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(FocusTheme.accent)
                    .controlSize(.small)
            }
        }
    }

    private func tipRow(symbol: String, text: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    private func formatted(hour: Int, minute: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}
