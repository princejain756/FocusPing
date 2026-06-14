import BackgroundTasks
import UIKit

enum BackgroundRefreshService {
    static let taskID = "com.focusping.app.refresh"

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handle(refreshTask)
        }
    }

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(_ task: BGAppRefreshTask) {
        schedule()
        NotificationCenter.default.post(name: .focusPingBackgroundRefresh, object: nil)
        task.setTaskCompleted(success: true)
    }
}

extension Notification.Name {
    static let focusPingBackgroundRefresh = Notification.Name("focusPingBackgroundRefresh")
    static let focusPingCompleteFromNotification = Notification.Name("focusPingCompleteFromNotification")
}
