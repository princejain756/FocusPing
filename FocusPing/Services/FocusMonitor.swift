import Foundation
#if canImport(FocusStatus)
import FocusStatus
#endif

actor FocusMonitor {
    func requestAuthorizationIfNeeded() async -> Bool {
        #if canImport(FocusStatus)
        let center = FocusStatusCenter.shared
        switch center.authorizationStatus {
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                center.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
        #else
        return false
        #endif
    }

    func isAuthorized() -> Bool {
        #if canImport(FocusStatus)
        return FocusStatusCenter.shared.authorizationStatus == .authorized
        #else
        return false
        #endif
    }

    func currentSnapshot() async -> FocusSnapshot {
        #if canImport(FocusStatus)
        let center = FocusStatusCenter.shared
        guard center.authorizationStatus == .authorized else {
            return .unknown
        }
        guard let status = center.focusStatus else {
            return .unknown
        }
        return status.isFocused ? .focused : .unfocused
        #else
        return .unknown
        #endif
    }
}
