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

        if let activity = resolvedActivity() {
            currentActivity = activity
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
        let activities = resolvedActivity().map { [$0] } ?? Activity<FocusPingLiveActivityAttributes>.activities
        guard !activities.isEmpty else {
            currentActivity = nil
            return
        }
        Task {
            for activity in activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        currentActivity = nil
    }

    private static func resolvedActivity() -> Activity<FocusPingLiveActivityAttributes>? {
        if let currentActivity { return currentActivity }
        return Activity<FocusPingLiveActivityAttributes>.activities.first
    }
}
