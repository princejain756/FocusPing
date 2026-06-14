import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Ping> { $0.isCompleted }, sort: \Ping.completedAt, order: .reverse)
    private var completedPings: [Ping]

    var body: some View {
        NavigationStack {
            Group {
                if completedPings.isEmpty {
                    ScrollView {
                        EmptyStateView(
                            title: "Nothing completed yet",
                            message: "Finished pings show up here. No streaks. No guilt. Just a quiet record of what you got done.",
                            systemImage: "checkmark.seal"
                        )
                        .padding(.top, 56)
                    }
                } else {
                    List {
                        ForEach(groupedSections, id: \.title) { section in
                            Section(section.title) {
                                ForEach(section.pings) { ping in
                                    HistoryRow(ping: ping)
                                }
                                .onDelete { offsets in
                                    deletePings(in: section.pings, at: offsets)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(FocusTheme.calmBackground)
            .navigationTitle("History")
        }
    }

    private var groupedSections: [HistorySection] {
        let calendar = Calendar.current
        var today: [Ping] = []
        var thisWeek: [Ping] = []
        var earlier: [Ping] = []

        for ping in completedPings {
            guard let date = ping.completedAt else {
                earlier.append(ping)
                continue
            }
            if calendar.isDateInToday(date) {
                today.append(ping)
            } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
                thisWeek.append(ping)
            } else {
                earlier.append(ping)
            }
        }

        var sections: [HistorySection] = []
        if !today.isEmpty { sections.append(HistorySection(title: "Today", pings: today)) }
        if !thisWeek.isEmpty { sections.append(HistorySection(title: "This week", pings: thisWeek)) }
        if !earlier.isEmpty { sections.append(HistorySection(title: "Earlier", pings: earlier)) }
        return sections
    }

    private func deletePings(in pings: [Ping], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(pings[index])
        }
        try? modelContext.save()
    }
}

private struct HistorySection {
    let title: String
    let pings: [Ping]
}

private struct HistoryRow: View {
    let ping: Ping

    var body: some View {
        HStack(spacing: 14) {
            PingIconView(symbol: ping.iconSymbol, size: 36, tint: FocusTheme.available)
            VStack(alignment: .leading, spacing: 4) {
                Text(ping.title)
                    .font(.body.weight(.medium))
                if let completedAt = ping.completedAt {
                    Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(FocusTheme.available.opacity(0.7))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
    }
}
