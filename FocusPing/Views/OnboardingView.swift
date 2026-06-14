import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(AppModel.self) private var appModel
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if page < 2 {
                    Button("Skip") {
                        withAnimation(FocusMotion.quick) { page = 2 }
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(minHeight: FocusTheme.minTouchTarget)
                }
            }
            .padding(.horizontal, FocusTheme.spacingL)
            .padding(.top, FocusTheme.spacingS)

            TabView(selection: $page) {
                onboardingPage(
                    title: "Not when you're in hyperfocus",
                    message: "Planner apps ping at 9am even when you can't act. FocusPing holds reminders during Focus and delivers them when your brain is actually ready.",
                    symbol: "bell.and.waves.left.and.right.fill"
                )
                .tag(0)

                onboardingPage(
                    title: "Nothing expires. Nothing shames you.",
                    message: "Missed pings wait in a queue — they don't vanish at midnight. No red badges. No streaks. No punishment for being late.",
                    symbol: "heart.fill"
                )
                .tag(1)

                permissionsPage
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(FocusMotion.quick, value: page)

            bottomBar
        }
        .background(FocusTheme.calmBackground.ignoresSafeArea())
    }

    private func onboardingPage(title: String, message: String, symbol: String) -> some View {
        VStack(spacing: FocusTheme.spacingL) {
            Spacer()
            ZStack {
                Circle()
                    .fill(FocusTheme.accentSoft)
                    .frame(width: 120, height: 120)
                Image(systemName: symbol)
                    .font(.system(size: 44))
                    .foregroundStyle(FocusTheme.accent)
                    .symbolRenderingMode(.hierarchical)
            }
            VStack(spacing: FocusTheme.spacingM - 4) {
                Text(title)
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, FocusTheme.spacingS)
            }
            Spacer()
        }
        .padding(FocusTheme.spacingXL)
    }

    private var permissionsPage: some View {
        VStack(spacing: FocusTheme.spacingL) {
            Spacer()
            BrandMark(size: 72)
            Text("Two permissions unlock the magic")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            VStack(spacing: FocusTheme.spacingM - 4) {
                permissionRow(
                    title: "Notifications",
                    detail: "Deliver pings when you are ready",
                    enabled: appModel.notificationsAuthorized,
                    symbol: "bell.badge.fill",
                    actionTitle: appModel.notificationsAuthorized ? nil : "Enable"
                ) {
                    Task { await appModel.requestNotifications() }
                }
                permissionRow(
                    title: "Focus Status",
                    detail: "Hold pings during system Focus",
                    enabled: appModel.focusStatusAuthorized,
                    symbol: "moon.fill",
                    actionTitle: appModel.focusStatusAuthorized ? nil : "Enable"
                ) {
                    Task { await appModel.requestFocusStatus() }
                }
            }

            Text("You can always use Deep Work mode without Focus Status.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(FocusTheme.spacingXL)
    }

    private func permissionRow(
        title: String,
        detail: String,
        enabled: Bool,
        symbol: String,
        actionTitle: String?,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(FocusTheme.accent)
                .frame(width: FocusTheme.minTouchTarget, height: FocusTheme.minTouchTarget)
                .background(FocusTheme.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if enabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(FocusTheme.available)
                    .font(.title3)
                    .accessibilityLabel("\(title) enabled")
            } else if let actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(FocusTheme.accent)
                    .controlSize(.small)
            }
        }
        .focusCard()
    }

    private var bottomBar: some View {
        VStack(spacing: FocusTheme.spacingM - 4) {
            if page < 2 {
                Button(page == 1 ? "Set up permissions" : "Continue") {
                    HapticService.light()
                    withAnimation(FocusMotion.quick) { page += 1 }
                }
                .buttonStyle(FocusPrimaryButtonStyle())
            } else {
                Button("Get started") {
                    Task {
                        await appModel.bootstrap()
                        HapticService.success()
                        appModel.completeOnboarding()
                    }
                }
                .buttonStyle(FocusPrimaryButtonStyle())
            }
        }
        .padding(.horizontal, FocusTheme.spacingL)
        .padding(.bottom, FocusTheme.spacingXL)
    }
}
