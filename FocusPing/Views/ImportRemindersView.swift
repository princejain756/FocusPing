import SwiftUI
import SwiftData
import UIKit

struct ImportRemindersView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var pingStore: PingStore

    @State private var items: [ReminderImportItem] = []
    @State private var selectedIDs: Set<String> = []
    @State private var isLoading = true
    @State private var isImporting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: FocusTheme.spacingM) {
                        ProgressView()
                        Text("Loading reminders…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    EmptyStateView(
                        title: "Cannot access Reminders",
                        message: errorMessage,
                        systemImage: "exclamationmark.triangle",
                        actionTitle: "Open Settings"
                    ) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                } else if items.isEmpty {
                    EmptyStateView(
                        title: "No open reminders",
                        message: "Your Apple Reminders inbox is clear, or nothing matched.",
                        systemImage: "checklist"
                    )
                } else {
                    List(items) { item in
                        Button {
                            toggle(item.id)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(selectedIDs.contains(item.id) ? FocusTheme.accent : .secondary)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    if !item.note.isEmpty {
                                        Text(item.note)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    if let due = item.dueDate {
                                        Label(due.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                                            .font(.caption2)
                                            .foregroundStyle(FocusTheme.accent)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .frame(minHeight: FocusTheme.minTouchTarget)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selectedIDs.contains(item.id) ? .isSelected : [])
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Import Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isImporting)
                }
                ToolbarItem(placement: .primaryAction) {
                    if !items.isEmpty && errorMessage == nil && !isLoading {
                        Button(selectedIDs.count == items.count ? "Deselect all" : "Select all") {
                            if selectedIDs.count == items.count {
                                selectedIDs.removeAll()
                            } else {
                                selectedIDs = Set(items.map(\.id))
                            }
                        }
                        .font(.subheadline)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isImporting {
                        ProgressView()
                    } else {
                        Button("Import (\(selectedIDs.count))") {
                            Task { await importSelected() }
                        }
                        .disabled(selectedIDs.isEmpty)
                    }
                }
            }
            .task { await load() }
            .interactiveDismissDisabled(isImporting)
        }
    }

    private func toggle(_ id: String) {
        HapticService.light()
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let granted = try await RemindersService.shared.requestAccess()
            guard granted else {
                errorMessage = "Allow Reminders access in Settings to import."
                isLoading = false
                return
            }
            items = try await RemindersService.shared.fetchIncompleteReminders()
            selectedIDs = Set(items.prefix(3).map(\.id))
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func importSelected() async {
        isImporting = true
        for item in items where selectedIDs.contains(item.id) {
            await pingStore.addPing(
                title: item.title,
                note: item.note,
                iconSymbol: "list.bullet",
                dueAt: item.dueDate,
                holdDuringFocus: true,
                repeatDaily: false,
                context: modelContext,
                appModel: appModel
            )
        }
        HapticService.success()
        dismiss()
    }
}
