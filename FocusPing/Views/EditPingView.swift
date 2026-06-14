import SwiftUI
import SwiftData

struct EditPingView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var pingStore: PingStore
    @Bindable var ping: Ping

    @State private var title: String
    @State private var note: String
    @State private var iconSymbol: String
    @State private var scheduleMode: ScheduleMode
    @State private var dueDate: Date
    @State private var holdDuringFocus: Bool
    @State private var repeatDaily: Bool
    @State private var isSaving = false

    private let iconOptions = [
        "bell.fill", "pills.fill", "drop.fill", "message.fill",
        "figure.walk", "clock.fill", "heart.fill", "list.bullet",
        "cart.fill", "phone.fill", "house.fill", "brain.head.profile"
    ]

    enum ScheduleMode: String, CaseIterable, Identifiable {
        case scheduled = "Schedule time"
        case whenReady = "When I am ready"

        var id: String { rawValue }
    }

    init(pingStore: PingStore, ping: Ping) {
        self.pingStore = pingStore
        self.ping = ping
        _title = State(initialValue: ping.title)
        _note = State(initialValue: ping.note)
        _iconSymbol = State(initialValue: ping.iconSymbol)
        _scheduleMode = State(initialValue: ping.dueAt == nil ? .whenReady : .scheduled)
        _dueDate = State(initialValue: ping.dueAt ?? Date().addingTimeInterval(3600))
        _holdDuringFocus = State(initialValue: ping.holdDuringFocus)
        _repeatDaily = State(initialValue: ping.repeatDaily)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        PingIconView(symbol: iconSymbol, size: 52)
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Title", text: $title)
                                .font(.headline)
                            TextField("Optional note", text: $note, axis: .vertical)
                                .lineLimit(2...4)
                                .font(.subheadline)
                        }
                    }
                    iconPicker
                }

                Section {
                    Picker("Delivery", selection: $scheduleMode) {
                        ForEach(ScheduleMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                    if scheduleMode == .scheduled {
                        DatePicker("Due", selection: $dueDate)
                        Toggle("Repeat daily", isOn: $repeatDaily)
                    }
                } header: {
                    Text("When")
                }

                Section {
                    Toggle("Hold during Focus", isOn: $holdDuringFocus)
                }
            }
            .navigationTitle("Edit ping")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task { await save() }
                        }
                        .disabled(trimmedTitle.isEmpty)
                    }
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }

    private var iconPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FocusTheme.spacingS) {
                ForEach(iconOptions, id: \.self) { symbol in
                    Button {
                        HapticService.light()
                        iconSymbol = symbol
                    } label: {
                        PingIconView(
                            symbol: symbol,
                            size: 40,
                            tint: iconSymbol == symbol ? FocusTheme.accent : .secondary
                        )
                        .overlay {
                            if iconSymbol == symbol {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .strokeBorder(FocusTheme.accent, lineWidth: 2)
                            }
                        }
                    }
                    .buttonStyle(FocusPressStyle())
                    .accessibilityLabel(iconAccessibilityLabel(symbol))
                    .accessibilityAddTraits(iconSymbol == symbol ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func iconAccessibilityLabel(_ symbol: String) -> String {
        switch symbol {
        case "pills.fill": return "Medication icon"
        case "drop.fill": return "Water icon"
        case "message.fill": return "Message icon"
        case "figure.walk": return "Leave icon"
        case "brain.head.profile": return "Deep work icon"
        default: return "Bell icon"
        }
    }

    private func save() async {
        isSaving = true
        await pingStore.updatePing(
            ping,
            title: trimmedTitle,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            iconSymbol: iconSymbol,
            dueAt: scheduleMode == .scheduled ? dueDate : nil,
            holdDuringFocus: holdDuringFocus,
            repeatDaily: repeatDaily && scheduleMode == .scheduled,
            context: modelContext,
            appModel: appModel
        )
        HapticService.success()
        dismiss()
    }
}
