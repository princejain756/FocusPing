import ActivityKit
import Foundation

@MainActor
enum LiveActivityService {
    private static var currentActivity: Activity<FocusPingLiveActivityAttributes>?

    static func update(
        queuedCount: Int,
        focusLabel: String,
        nextTitle: String?,
        deepWorkEnabled: Bool
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = FocusPingLiveActivityAttributes.ContentState(
            queuedCount: queuedCount,
            focusLabel: focusLabel,
            nextTitle: nextTitle,
            deepWorkEnabled: deepWorkEnabled
        )

        if queuedCount == 0 && !deepWorkEnabled {
            end()
            return
        }

        if let activity = currentActivity {
            Task {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            }
            return
        }

        let attributes = FocusPingLiveActivityAttributes()
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            currentActivity = nil
        }
    }

    static func end() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }
}
