import Foundation

final class DeliveryInterceptService {
    static let shared = DeliveryInterceptService()

    var shouldHoldDelivery: ((UUID) -> Bool)?

    func holdsDelivery(for pingID: UUID) -> Bool {
        shouldHoldDelivery?(pingID) ?? false
    }
}
