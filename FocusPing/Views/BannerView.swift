import SwiftUI

struct BannerView: View {
    let message: String
    var undoTitle: String?
    var onUndo: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: undoTitle == nil ? "checkmark.circle.fill" : "arrow.uturn.backward.circle.fill")
                .foregroundStyle(undoTitle == nil ? FocusTheme.available : FocusTheme.accent)
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            if let undoTitle, let onUndo {
                Button(undoTitle, action: onUndo)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FocusTheme.accent)
                    .frame(minHeight: FocusTheme.minTouchTarget)
            }
        }
        .padding(.horizontal, FocusTheme.spacingM)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, FocusTheme.spacingM)
        .accessibilityElement(children: .combine)
    }
}

struct BannerOverlayModifier: ViewModifier {
    @Bindable var bannerService: BannerService

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message = bannerService.message {
                    BannerView(
                        message: message,
                        undoTitle: bannerService.undoTitle,
                        onUndo: bannerService.undoTitle == nil ? nil : { bannerService.performUndo() }
                    )
                    .padding(.top, FocusTheme.spacingS)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
                }
            }
            .animation(FocusMotion.quick, value: bannerService.message)
    }
}

extension View {
    func bannerOverlay(_ bannerService: BannerService) -> some View {
        modifier(BannerOverlayModifier(bannerService: bannerService))
    }
}
