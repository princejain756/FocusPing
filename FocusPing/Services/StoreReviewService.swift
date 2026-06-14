import StoreKit
import UIKit

enum StoreReviewService {
    private static let completionThreshold = 8

    @MainActor
    static func considerPrompt(totalCompleted: Int) {
        let key = SettingsKey.reviewPrompted
        guard totalCompleted >= completionThreshold else { return }
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
            UserDefaults.standard.set(true, forKey: key)
        }
    }
}
