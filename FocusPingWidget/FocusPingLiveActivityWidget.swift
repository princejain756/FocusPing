import SwiftUI
import WidgetKit

struct FocusPingLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusPingLiveActivityAttributes.self) { context in
            FocusPingLiveActivityLockView(state: context.state)
                .activityBackgroundTint(FocusTheme.accent.opacity(0.12))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.deepWorkEnabled ? "brain.head.profile.fill" : "bell.badge.fill")
                        .foregroundStyle(FocusTheme.accent)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.queuedCount)")
                        .font(.title2.weight(.bold))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.nextTitle ?? context.state.focusLabel)
                        .font(.caption)
                        .lineLimit(1)
                }
            } compactLeading: {
                Image(systemName: "tray.full.fill")
                    .foregroundStyle(FocusTheme.accent)
            } compactTrailing: {
                Text("\(context.state.queuedCount)")
                    .font(.caption.weight(.bold))
            } minimal: {
                Image(systemName: "bell.fill")
            }
        }
    }
}

struct FocusPingLiveActivityLockView: View {
    let state: FocusPingLiveActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: state.deepWorkEnabled ? "brain.head.profile.fill" : "tray.full.fill")
                .font(.title2)
                .foregroundStyle(FocusTheme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(state.queuedCount == 0 ? "Focus Gate active" : "\(state.queuedCount) ping\(state.queuedCount == 1 ? "" : "s") waiting")
                    .font(.headline)
                Text(state.nextTitle ?? state.focusLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

enum FocusTheme {
    static let accent = Color(red: 0.93, green: 0.42, blue: 0.18)
}
