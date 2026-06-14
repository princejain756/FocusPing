import AppIntents

struct FocusPingShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: EnableDeepWorkIntent(),
            phrases: [
                "Start Deep Work in \(.applicationName)",
                "Hold my pings in \(.applicationName)",
                "Focus mode in \(.applicationName)"
            ],
            shortTitle: "Start Deep Work",
            systemImageName: "brain.head.profile"
        )
        AppShortcut(
            intent: DisableDeepWorkIntent(),
            phrases: [
                "End Deep Work in \(.applicationName)",
                "Release my pings in \(.applicationName)",
                "I'm available in \(.applicationName)"
            ],
            shortTitle: "End Deep Work",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: AddQuickPingIntent(),
            phrases: [
                "Remind me in \(.applicationName)",
                "Add ping in \(.applicationName)",
                "Ping me in \(.applicationName)"
            ],
            shortTitle: "Add Ping",
            systemImageName: "bell.badge"
        )
    }
}
