import SwiftUI
import WidgetKit

@main
struct FocusPingWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusPingStatusWidget()
        FocusPingLiveActivityWidget()
    }
}
