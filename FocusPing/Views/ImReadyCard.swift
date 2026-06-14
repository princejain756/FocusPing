import SwiftUI

/// Market differentiator: positive "I'm ready" moment vs planner apps that punish lateness.
struct ImReadyCard: View {
    let queuedCount: Int
    let nextTitle: String?
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FocusTheme.spacingM - 4) {
            HStack(spacing: 12) {
                Image(systemName: "hand.wave.fill")
                    .font(.title2)
                    .foregroundStyle(FocusTheme.accent)
                    .frame(width: 44, height: 44)
                    .background(FocusTheme.accentSoft)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(queuedCount == 1 ? "1 ping is waiting" : "\(queuedCount) pings are waiting")
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Button(action: action) {
                Label("I'm ready — deliver now", systemImage: "sparkles")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: FocusTheme.minTouchTarget)
            }
            .buttonStyle(FocusPrimaryButtonStyle())
            .accessibilityHint("Releases all held pings when you have capacity to act")
        }
        .focusCard()
        .accessibilityElement(children: .contain)
    }

    private var subtitle: String {
        if let nextTitle, !nextTitle.isEmpty {
            return "Next up: \(nextTitle). Nothing expired. Nothing turned red."
        }
        return "Held safely while you focused. Tap when you can act."
    }
}

struct DeliveryWindowPreview: View {
    let window: DeliveryWindow
    let isEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: FocusTheme.spacingS) {
            HStack {
                Text("Delivery hours")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(isEnabled ? "On" : "Off")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isEnabled ? FocusTheme.available : .secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(FocusTheme.accent.opacity(isEnabled ? 0.55 : 0.2))
                        .frame(width: activeWidth(total: geo.size.width))
                        .offset(x: activeOffset(total: geo.size.width))
                }
            }
            .frame(height: 10)
            HStack {
                Text(format(hour: window.startHour, minute: window.startMinute))
                Spacer()
                Text(format(hour: window.endHour, minute: window.endMinute))
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isEnabled
            ? "Delivery window from \(format(hour: window.startHour, minute: window.startMinute)) to \(format(hour: window.endHour, minute: window.endMinute))"
            : "Delivery window disabled")
    }

    private func minutes(_ hour: Int, _ minute: Int) -> CGFloat {
        CGFloat(hour * 60 + minute)
    }

    private func activeWidth(total: CGFloat) -> CGFloat {
        let start = minutes(window.startHour, window.startMinute)
        let end = minutes(window.endHour, window.endMinute)
        let day: CGFloat = 24 * 60
        let span = end >= start ? end - start : day - start + end
        return max(total * (span / day), 8)
    }

    private func activeOffset(total: CGFloat) -> CGFloat {
        total * (minutes(window.startHour, window.startMinute) / (24 * 60))
    }

    private func format(hour: Int, minute: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}
