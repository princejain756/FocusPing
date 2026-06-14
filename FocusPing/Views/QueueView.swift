import SwiftUI
import SwiftData

struct QueueView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Bindable var pingStore: PingStore
    @Query(sort: \QueuedDelivery.queuedAt, order: .forward)
    private var queue: [QueuedDelivery]

    var body: some View {
        NavigationStack {
            Group {
                if queue.isEmpty {
                    ScrollView {
                        EmptyStateView(
                            title: "Queue is clear",
                            message: "Pings held during Focus or outside your delivery window wait here. No guilt — they stay until you are ready.",
                            systemImage: "tray"
                        )
                        .padding(.top, 56)
                    }
                } else {
                    List {
                        Section {
                            ForEach(queue) { item in
                                QueueRow(item: item)
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button {
                                            HapticService.success()
                                            Task {
                                                await pingStore.releaseQueueItem(
                                                    item,
                                                    context: modelContext,
                                                    appModel: appModel
                                                )
                                            }
                                        } label: {
                                            Label("Release", systemImage: "paperplane.fill")
                                        }
                                        .tint(FocusTheme.accent)
                                    }
                            }
                        } header: {
                            HStack {
                                Text("\(queue.count) waiting")
                                Spacer()
                                ReasonChip(text: "Swipe to release →", color: .secondary)
                            }
                        } footer: {
                            Text("Held pings are safe here. Release when you have capacity to act.")
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .safeAreaInset(edge: .bottom) {
                        releaseAllBar
                    }
                }
            }
            .background(FocusTheme.calmBackground)
            .navigationTitle("Queue")
        }
    }

    private var releaseAllBar: some View {
        Button {
            HapticService.light()
            Task {
                await pingStore.releaseAllQueued(
                    context: modelContext,
                    appModel: appModel
                )
            }
        } label: {
            Label("I'm ready — deliver all", systemImage: "sparkles")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(minHeight: FocusTheme.minTouchTarget)
        }
        .buttonStyle(FocusPrimaryButtonStyle())
        .padding(.horizontal, FocusTheme.spacingM)
        .padding(.vertical, FocusTheme.spacingM - 4)
        .background(.ultraThinMaterial)
        .accessibilityHint("Delivers every ping in the queue immediately")
    }
}

private struct QueueRow: View {
    let item: QueuedDelivery

    var body: some View {
        HStack(spacing: 14) {
            PingIconView(symbol: item.iconSymbol)
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.body.weight(.semibold))
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: 8) {
                    ReasonChip(text: item.reason, color: FocusTheme.accent)
                    Text(item.queuedAt.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
