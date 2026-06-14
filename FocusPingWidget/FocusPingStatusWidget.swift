import SwiftUI
import WidgetKit

struct FocusPingStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusPingStatusEntry {
        FocusPingStatusEntry(date: Date(), snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusPingStatusEntry) -> Void) {
        completion(FocusPingStatusEntry(date: Date(), snapshot: AppGroupStore.loadSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusPingStatusEntry>) -> Void) {
        let snapshot = AppGroupStore.loadSnapshot()
        let entry = FocusPingStatusEntry(date: Date(), snapshot: snapshot)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct FocusPingStatusEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct FocusPingStatusWidgetView: View {
    var entry: FocusPingStatusEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .accessoryCircular:
            accessoryCircular
        case .accessoryRectangular:
            accessoryRectangular
        default:
            mediumView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "bell.and.waves.left.and.right.fill")
                    .foregroundStyle(FocusTheme.accent)
                Spacer()
                if entry.snapshot.deepWorkEnabled {
                    Image(systemName: "brain.head.profile.fill")
                        .foregroundStyle(FocusTheme.deepWork)
                }
            }
            Text("\(entry.snapshot.queuedCount)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
            Text(entry.snapshot.queuedCount == 1 ? "ping waiting" : "pings waiting")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(entry.snapshot.focusLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(FocusTheme.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(red: 0.98, green: 0.94, blue: 0.90), Color(red: 0.95, green: 0.97, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("FocusPing")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FocusTheme.accent)
                Text(entry.snapshot.queuedCount == 0 ? "Queue clear" : "\(entry.snapshot.queuedCount) waiting")
                    .font(.title2.weight(.bold))
                Text(entry.snapshot.focusLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let next = entry.snapshot.nextQueuedTitle {
                    Text("Next: \(next)")
                        .font(.caption2)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(spacing: 8) {
                Button(intent: EnableDeepWorkIntent()) {
                    Label("Deep Work", systemImage: "brain.head.profile")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(FocusTheme.deepWork)
                .disabled(entry.snapshot.deepWorkEnabled)
            }
            .frame(width: 120)
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    private var accessoryCircular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text("\(entry.snapshot.queuedCount)")
                    .font(.headline)
                Image(systemName: "tray.full")
                    .font(.caption2)
            }
        }
    }

    private var accessoryRectangular: some View {
        HStack {
            Image(systemName: "bell.badge.fill")
            VStack(alignment: .leading) {
                Text("\(entry.snapshot.queuedCount) queued")
                    .font(.headline)
                Text(entry.snapshot.focusLabel)
                    .font(.caption2)
            }
        }
        .containerBackground(for: .widget) {
            AccessoryWidgetBackground()
        }
    }
}

struct FocusPingStatusWidget: Widget {
    let kind = "FocusPingStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusPingStatusProvider()) { entry in
            FocusPingStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("FocusPing Status")
        .description("See queued pings and Focus status at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

extension FocusTheme {
    static let deepWork = Color(red: 0.35, green: 0.28, blue: 0.72)
}
