import SwiftUI

struct HelpTipsView: View {
    @Environment(\.dismiss) private var dismiss

    private let tips: [(String, String, String)] = [
        ("hand.wave.fill", "I'm ready", "When pings are held, tap I'm ready to deliver them all at once — no guilt, no expired tasks."),
        ("moon.fill", "Focus hold", "Pings wait during system Focus or Deep Work instead of interrupting hyperfocus."),
        ("tray.full", "The queue", "Missed pings stay in the queue. They never vanish at midnight like planner apps."),
        ("clock.arrow.circlepath", "Snooze freely", "Snooze 15 minutes to 3 hours. Being late is normal — FocusPing doesn't punish you."),
        ("brain.head.profile", "Deep Work", "Manual hold when you need quiet without enabling system Focus."),
        ("bell.badge", "Siri", "Say \"Remind me in FocusPing\" or \"Start Deep Work in FocusPing\"."),
        ("list.bullet.rectangle.portrait", "Import", "Bring open Apple Reminders in — no re-typing.")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("FocusPing is a delivery gate, not a day planner. It solves wrong-time notifications — the #1 complaint in ADHD reminder apps.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("How to win with FocusPing") {
                    ForEach(tips, id: \.1) { symbol, title, detail in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: symbol)
                                .font(.title3)
                                .foregroundStyle(FocusTheme.accent)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(title)
                                    .font(.headline)
                                Text(detail)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Text("Compared to planner apps: no minute-by-minute schedule, no red overdue badges, no blank slate at midnight.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Why FocusPing?")
                }
            }
            .navigationTitle("Tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
