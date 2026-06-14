import SwiftUI

// MARK: - Design tokens (8pt grid, HIG semantic colors)

enum FocusTheme {
    static let accent = Color(red: 0.93, green: 0.42, blue: 0.18)
    static let accentSoft = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.22, green: 0.14, blue: 0.10, alpha: 1)
            : UIColor(red: 0.98, green: 0.88, blue: 0.82, alpha: 1)
    })
    static let deepWork = Color(red: 0.45, green: 0.38, blue: 0.82)
    static let available = Color(red: 0.22, green: 0.68, blue: 0.48)
    static let calmBackground = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let elevatedBackground = Color(.tertiarySystemGroupedBackground)

    static let cornerRadius: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 24
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let minTouchTarget: CGFloat = 44

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(uiColor: UIColor { traits in
                    traits.userInterfaceStyle == .dark
                        ? UIColor(red: 0.14, green: 0.12, blue: 0.18, alpha: 1)
                        : UIColor(red: 0.98, green: 0.94, blue: 0.90, alpha: 1)
                }),
                Color(uiColor: UIColor { traits in
                    traits.userInterfaceStyle == .dark
                        ? UIColor(red: 0.10, green: 0.12, blue: 0.16, alpha: 1)
                        : UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1)
                })
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var brandAccent: Color { accent }
}

// MARK: - Motion

enum FocusMotion {
    static var quick: Animation {
        reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.22)
    }

    static var spring: Animation {
        reduceMotion ? .linear(duration: 0.01) : .spring(response: 0.32, dampingFraction: 0.82)
    }

    private static var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
}

// MARK: - Modifiers

struct FocusCardModifier: ViewModifier {
    var padding: CGFloat = FocusTheme.spacingM

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(FocusTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: FocusTheme.cornerRadius, style: .continuous))
    }
}

struct FocusPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(FocusMotion.quick, value: configuration.isPressed)
    }
}

struct FocusPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(minHeight: FocusTheme.minTouchTarget)
            .background(FocusTheme.accent.opacity(configuration.isPressed ? 0.85 : 1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .animation(FocusMotion.quick, value: configuration.isPressed)
    }
}

extension View {
    func focusCard(padding: CGFloat = FocusTheme.spacingM) -> some View {
        modifier(FocusCardModifier(padding: padding))
    }

    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Brand

struct BrandMark: View {
    var size: CGFloat = 56

    var body: some View {
        Image("LaunchBrand")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            .shadow(color: FocusTheme.accent.opacity(0.2), radius: 6, y: 3)
            .accessibilityLabel("FocusPing")
    }
}

// MARK: - Status

struct FocusStatusBadge: View {
    let snapshot: FocusSnapshot
    var compact: Bool = false

    var body: some View {
        HStack(spacing: FocusTheme.spacingS + 2) {
            Image(systemName: snapshot.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(statusColor)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.label)
                    .font(compact ? .subheadline.weight(.semibold) : .headline)
                if !compact {
                    Text(snapshot.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, FocusTheme.spacingM - 2)
        .padding(.vertical, compact ? 10 : 14)
        .background(statusColor.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: FocusTheme.cornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Focus status: \(snapshot.label). \(snapshot.subtitle)")
    }

    private var statusColor: Color {
        switch snapshot {
        case .unfocused: return FocusTheme.available
        case .focused, .manualQuiet: return FocusTheme.deepWork
        case .unknown: return .secondary
        }
    }
}

struct DeepWorkToggle: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            HapticService.light()
            withAnimation(reduceMotion ? nil : FocusMotion.spring) {
                appModel.toggleManualQuietMode()
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: appModel.manualQuietMode ? "brain.head.profile.fill" : "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(appModel.manualQuietMode ? FocusTheme.deepWork : FocusTheme.accent)
                    .frame(width: FocusTheme.minTouchTarget, height: FocusTheme.minTouchTarget)
                    .background((appModel.manualQuietMode ? FocusTheme.deepWork : FocusTheme.accent).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .contentTransition(.symbolEffect(.replace))

                VStack(alignment: .leading, spacing: 4) {
                    Text(appModel.manualQuietMode ? "Deep Work is ON" : "Start Deep Work")
                        .font(.headline)
                    Text(appModel.manualQuietMode ? "Pings held until you turn this off" : "Hold pings without system Focus")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: appModel.manualQuietMode ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(appModel.manualQuietMode ? FocusTheme.deepWork : FocusTheme.accent)
            }
            .focusCard()
        }
        .buttonStyle(FocusPressStyle())
        .accessibilityLabel(appModel.manualQuietMode ? "Turn off Deep Work" : "Turn on Deep Work")
        .accessibilityHint("Holds incoming pings until you are ready")
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: FocusTheme.spacingM) {
            ZStack {
                Circle()
                    .fill(FocusTheme.accentSoft)
                    .frame(width: 88, height: 88)
                Image(systemName: systemImage)
                    .font(.system(size: 36))
                    .foregroundStyle(FocusTheme.accent)
                    .symbolRenderingMode(.hierarchical)
            }
            VStack(spacing: FocusTheme.spacingS) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(FocusTheme.accent)
                    .controlSize(.large)
                    .padding(.top, FocusTheme.spacingXS)
            }
        }
        .padding(FocusTheme.spacingL)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Ping icon

struct PingIconView: View {
    let symbol: String
    var size: CGFloat = 40
    var tint: Color = FocusTheme.accent

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .accessibilityHidden(true)
    }
}

// MARK: - Reason chip

struct ReasonChip: View {
    let text: String
    var color: Color = FocusTheme.accent

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Template chip

struct TemplateChip: View {
    let template: PingTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: FocusTheme.spacingS) {
                Image(systemName: template.symbol)
                    .font(.title3)
                    .foregroundStyle(FocusTheme.accent)
                    .frame(width: 28, height: 28)
                Text(template.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 120)
            .frame(minHeight: 96, alignment: .leading)
            .padding(FocusTheme.spacingM - 4)
            .background(FocusTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: FocusTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FocusTheme.cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(FocusPressStyle())
        .accessibilityLabel("Quick add: \(template.title)")
    }
}

// MARK: - Floating action

struct FloatingAddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Add ping", systemImage: "plus")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(minHeight: FocusTheme.minTouchTarget)
                .background(FocusTheme.accent)
                .clipShape(Capsule())
                .shadow(color: FocusTheme.accent.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(FocusPressStyle())
        .accessibilityLabel("Add ping")
    }
}
