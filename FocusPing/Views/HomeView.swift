import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Bindable var pingStore: PingStore
    @Binding var selectedTab: Int
    @Query(filter: #Predicate<Ping> { !$0.isCompleted }, sort: \Ping.createdAt, order: .reverse)
    private var activePings: [Ping]
    @State private var showingAdd = false
    @State private var showingImport = false
    @State private var addTemplate: PingTemplate?
    @State private var editingPing: Ping?
    @State private var searchText = ""
    @Query(sort: \QueuedDelivery.queuedAt, order: .forward)
    private var queueItems: [QueuedDelivery]

    private var filteredPings: [Ping] {
        guard !searchText.isEmpty else { return activePings }
        return activePings.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.note.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if pingStore.queuedCount > 0 {
                    Section {
                        ImReadyCard(
                            queuedCount: pingStore.queuedCount,
                            nextTitle: queueItems.first?.title
                        ) {
                            HapticService.success()
                            Task {
                                await pingStore.releaseAllQueued(
                                    context: modelContext,
                                    appModel: appModel
                                )
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                }

                Section {
                    heroHeader
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section {
                    DeepWorkToggle()
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)
                }

                Section {
                    statsRow
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section {
                    quickTemplates
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                } header: {
                    Text("Quick add")
                }

                if activePings.isEmpty {
                    Section {
                        EmptyStateView(
                            title: "No pings yet",
                            message: "Wrong-time notifications stop here. Add a ping — FocusPing holds it during Focus and delivers when you can act.",
                            systemImage: "bell.and.waves.left.and.right",
                            actionTitle: "Add your first ping"
                        ) {
                            addTemplate = nil
                            showingAdd = true
                        }
                        .frame(maxWidth: .infinity)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                } else if filteredPings.isEmpty {
                    Section {
                        ContentUnavailableView.search(text: searchText)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                } else {
                    Section {
                        ForEach(filteredPings) { ping in
                            PingRowContent(ping: ping)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingPing = ping
                                }
                                .accessibilityHint("Double tap to edit")
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        HapticService.success()
                                        Task { await pingStore.completePing(ping, context: modelContext) }
                                    } label: {
                                        Label("Done", systemImage: "checkmark")
                                    }
                                    .tint(FocusTheme.available)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        HapticService.light()
                                        Task { await pingStore.snoozePing(ping, minutes: 15, context: modelContext) }
                                    } label: {
                                        Label("Snooze", systemImage: "clock")
                                    }
                                    .tint(FocusTheme.accent)
                                    Button(role: .destructive) {
                                        Task {
                                            await pingStore.deletePingWithUndo(
                                                ping,
                                                context: modelContext,
                                                appModel: appModel
                                            )
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .contextMenu {
                                    Button("Edit", systemImage: "pencil") {
                                        editingPing = ping
                                    }
                                    Button("Duplicate", systemImage: "plus.square.on.square") {
                                        Task {
                                            await pingStore.duplicatePing(
                                                ping,
                                                context: modelContext,
                                                appModel: appModel
                                            )
                                        }
                                    }
                                    Button("Done", systemImage: "checkmark.circle.fill") {
                                        Task { await pingStore.completePing(ping, context: modelContext) }
                                    }
                                    Menu {
                                        snoozeButton(ping, minutes: 15, label: "15 minutes")
                                        snoozeButton(ping, minutes: 30, label: "30 minutes")
                                        snoozeButton(ping, minutes: 60, label: "1 hour")
                                        snoozeButton(ping, minutes: 180, label: "3 hours")
                                    } label: {
                                        Label("Snooze", systemImage: "clock.arrow.circlepath")
                                    }
                                    Divider()
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        Task {
                                            await pingStore.deletePingWithUndo(
                                                ping,
                                                context: modelContext,
                                                appModel: appModel
                                            )
                                        }
                                    }
                                }
                        }
                    } header: {
                        Text("Active pings")
                    } footer: {
                        Text("Tap a ping to edit. Swipe right to complete. Swipe left to snooze or delete.")
                            .font(.caption)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(FocusTheme.calmBackground)
            .navigationTitle("FocusPing")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search pings")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingImport = true
                    } label: {
                        Image(systemName: "list.bullet.rectangle.portrait")
                            .frame(minWidth: FocusTheme.minTouchTarget, minHeight: FocusTheme.minTouchTarget)
                    }
                    .accessibilityLabel("Import from Reminders")
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HStack {
                    Spacer()
                    FloatingAddButton {
                        HapticService.light()
                        addTemplate = nil
                        showingAdd = true
                    }
                    .padding(.trailing, FocusTheme.spacingM)
                    .padding(.bottom, FocusTheme.spacingS)
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddPingView(pingStore: pingStore, template: addTemplate)
            }
            .sheet(isPresented: $showingImport) {
                ImportRemindersView(pingStore: pingStore)
            }
            .sheet(item: $editingPing) { ping in
                EditPingView(pingStore: pingStore, ping: ping)
            }
            .onReceive(NotificationCenter.default.publisher(for: .focusPingOpenAddPing)) { _ in
                addTemplate = nil
                showingAdd = true
            }
        }
    }

    @ViewBuilder
    private func snoozeButton(_ ping: Ping, minutes: Int, label: String) -> some View {
        Button(label) {
            HapticService.light()
            Task { await pingStore.snoozePing(ping, minutes: minutes, context: modelContext) }
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: FocusTheme.spacingM) {
            HStack(spacing: 14) {
                BrandMark(size: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Focus Gate")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FocusTheme.accent)
                    Text("Remind you when you can act.")
                        .font(.title3.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Wrong-time notifications stop here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            FocusStatusBadge(snapshot: appModel.focusSnapshot)
        }
        .padding(FocusTheme.spacingM + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FocusTheme.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: FocusTheme.cornerRadiusLarge, style: .continuous))
    }

    private var statsRow: some View {
        HStack(spacing: FocusTheme.spacingS + 4) {
            StatCard(title: "Active", value: "\(pingStore.activeCount)", symbol: "bell.fill")
            StatCard(title: "Queued", value: "\(pingStore.queuedCount)", symbol: "tray.full.fill", highlighted: pingStore.queuedCount > 0) {
                selectedTab = 1
            }
            StatCard(title: "Done today", value: "\(pingStore.completedTodayCount)", symbol: "checkmark.circle.fill")
        }
    }

    private var quickTemplates: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FocusTheme.spacingS + 2) {
                ForEach(PingTemplate.all.filter { $0.id != "custom" }) { template in
                    TemplateChip(template: template) {
                        HapticService.light()
                        addTemplate = template
                        showingAdd = true
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let symbol: String
    var highlighted: Bool = false
    var action: (() -> Void)?

    var body: some View {
        Button(action: { action?() }) {
            VStack(alignment: .leading, spacing: FocusTheme.spacingS) {
                Image(systemName: symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(highlighted ? FocusTheme.accent : FocusTheme.accent.opacity(0.8))
                Text(value)
                    .font(.title2.weight(.bold))
                    .contentTransition(.numericText())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(FocusTheme.spacingM - 2)
            .background(FocusTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: FocusTheme.cornerRadius, style: .continuous))
            .overlay {
                if highlighted {
                    RoundedRectangle(cornerRadius: FocusTheme.cornerRadius, style: .continuous)
                        .strokeBorder(FocusTheme.accent.opacity(0.35), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(FocusPressStyle())
        .disabled(action == nil)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityHint(action != nil ? "Opens queue tab" : "")
    }
}

struct PingRowContent: View {
    let ping: Ping

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            PingIconView(symbol: ping.iconSymbol)
            VStack(alignment: .leading, spacing: FocusTheme.spacingS) {
                HStack(alignment: .firstTextBaseline) {
                    Text(ping.title)
                        .font(.body.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    if ping.holdDuringFocus {
                        ReasonChip(text: "Focus hold", color: FocusTheme.deepWork)
                    }
                }
                if !ping.note.isEmpty {
                    Text(ping.note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let dueAt = ping.dueAt {
                    Label(dueAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Label("Deliver when available", systemImage: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

// Legacy wrapper kept for any external references
struct PingRow: View {
    let ping: Ping
    let onComplete: () -> Void
    let onDelete: () -> Void
    let onSnooze: () -> Void

    var body: some View {
        PingRowContent(ping: ping)
    }
}
