import UIKit

/// Centralized haptic feedback for game events.
final class HapticsService {
    static let shared = HapticsService()

    /// Settings toggle: silences all game haptics when false.
    var isEnabled = true

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        light.prepare()
        medium.prepare()
        heavy.prepare()
    }

    /// Gentle tap for UI buttons and cards (store, menus).
    func uiTap() {
        guard isEnabled else { return }
        light.impactOccurred(intensity: 0.5)
        light.prepare()
    }

    func laneChange() {
        guard isEnabled else { return }
        light.impactOccurred(intensity: 0.7)
        light.prepare()
    }

    func jump() {
        guard isEnabled else { return }
        medium.impactOccurred(intensity: 0.8)
        medium.prepare()
    }

    func coin() {
        guard isEnabled else { return }
        light.impactOccurred(intensity: 0.45)
        light.prepare()
    }

    func powerUp() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    func stumble() {
        guard isEnabled else { return }
        notification.notificationOccurred(.warning)
        notification.prepare()
    }

    func crash() {
        guard isEnabled else { return }
        heavy.impactOccurred(intensity: 1.0)
        heavy.prepare()
    }
}
