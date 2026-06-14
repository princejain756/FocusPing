import SwiftUI
import SwiftData

struct AddPingView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var pingStore: PingStore
    var template: PingTemplate?

    @State private var title = ""
    @State private var note = ""
    @State private var iconSymbol = "bell.fill"
    @State private var scheduleMode: ScheduleMode = .scheduled
    @State private var dueDate = Date().addingTimeInterval(3600)
    @State private var holdDuringFocus = true
    @State private var repeatDaily = false
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
                            TextField("What do you need to remember?", text: $title)
                                .font(.headline)
                                .accessibilityLabel("Ping title")
                            TextField("Optional note", text: $note, axis: .vertical)
                                .lineLimit(2...4)
                                .font(.subheadline)
                                .accessibilityLabel("Optional note")
                        }
                    }
                    .padding(.vertical, 4)

                    iconPicker
                } header: {
                    Text("Ping")
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
                } footer: {
                    Text(scheduleMode == .whenReady
                         ? "Deliver as soon as Focus and your delivery window allow."
                         : "If due during Focus, the ping waits in queue.")
                }

                Section {
                    Toggle("Hold during Focus", isOn: $holdDuringFocus)
                } footer: {
                    Text("Recommended. Avoids wrong-time interruptions during hyperfocus.")
                }
            }
            .navigationTitle("New ping")
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
            .onAppear {
                if let template {
                    title = template.id == "custom" ? "" : template.title
                    note = template.note
                    iconSymbol = template.symbol
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
                    .accessibilityLabel("Icon: \(symbol)")
                    .accessibilityAddTraits(iconSymbol == symbol ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func save() async {
        isSaving = true
        await pingStore.addPing(
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
