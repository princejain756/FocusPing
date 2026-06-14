import Foundation
import Observation

@Observable
@MainActor
final class BannerService {
    static let shared = BannerService()

    var message: String?
    var undoTitle: String?
    private var undoHandler: (() -> Void)?
    private var dismissTask: Task<Void, Never>?

    func show(
        _ message: String,
        duration: TimeInterval = 2.5,
        undo undoTitle: String? = nil,
        undoAction: (() -> Void)? = nil
    ) {
        dismissTask?.cancel()
        self.message = message
        self.undoTitle = undoTitle
        self.undoHandler = undoAction
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            clear()
        }
    }

    func performUndo() {
        undoHandler?()
        clear()
    }

    func dismiss() {
        dismissTask?.cancel()
        clear()
    }

    private func clear() {
        message = nil
        undoTitle = nil
        undoHandler = nil
    }
}
