import ActivityKit
import Foundation

struct FocusPingLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var queuedCount: Int
        var focusLabel: String
        var nextTitle: String?
        var deepWorkEnabled: Bool
    }

    var name: String = "FocusPing"
}
