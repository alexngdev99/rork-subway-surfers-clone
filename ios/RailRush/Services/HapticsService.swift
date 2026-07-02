import UIKit

/// Centralized haptic feedback for game events.
final class HapticsService {
    static let shared = HapticsService()

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        light.prepare()
        medium.prepare()
        heavy.prepare()
    }

    func laneChange() {
        light.impactOccurred(intensity: 0.7)
        light.prepare()
    }

    func jump() {
        medium.impactOccurred(intensity: 0.8)
        medium.prepare()
    }

    func coin() {
        light.impactOccurred(intensity: 0.45)
        light.prepare()
    }

    func powerUp() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    func stumble() {
        notification.notificationOccurred(.warning)
        notification.prepare()
    }

    func crash() {
        heavy.impactOccurred(intensity: 1.0)
        heavy.prepare()
    }
}
