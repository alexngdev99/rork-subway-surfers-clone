import Foundation

/// Persists best score and total coin bank between runs.
final class ScoreStore {
    private enum Keys {
        static let bestScore = "railrush.bestScore"
        static let totalCoins = "railrush.totalCoins"
        static let selectedCharacter = "railrush.selectedCharacter"
        static let bestDistance = "railrush.bestDistance"
        static let bestCombo = "railrush.bestCombo"
    }

    private let defaults = UserDefaults.standard

    var bestScore: Int {
        get { defaults.integer(forKey: Keys.bestScore) }
        set { defaults.set(newValue, forKey: Keys.bestScore) }
    }

    var totalCoins: Int {
        get { defaults.integer(forKey: Keys.totalCoins) }
        set { defaults.set(newValue, forKey: Keys.totalCoins) }
    }

    var selectedCharacterID: String {
        get { defaults.string(forKey: Keys.selectedCharacter) ?? "boy" }
        set { defaults.set(newValue, forKey: Keys.selectedCharacter) }
    }

    /// Longest single-run distance in meters.
    var bestDistance: Int {
        get { defaults.integer(forKey: Keys.bestDistance) }
        set { defaults.set(newValue, forKey: Keys.bestDistance) }
    }

    /// Highest note-pickup combo ever reached.
    var bestCombo: Int {
        get { defaults.integer(forKey: Keys.bestCombo) }
        set { defaults.set(newValue, forKey: Keys.bestCombo) }
    }

    /// Records a finished run's score and returns whether it set a new best.
    /// The note wallet now lives in MetaStore; `totalCoins` remains only as
    /// the legacy migration source.
    @discardableResult
    func recordBest(score: Int) -> Bool {
        if score > bestScore {
            bestScore = score
            return true
        }
        return false
    }

    /// Records a finished run's distance; returns whether it set a new record.
    @discardableResult
    func recordDistance(_ meters: Int) -> Bool {
        if meters > bestDistance {
            bestDistance = meters
            return true
        }
        return false
    }

    /// Records a finished run's best combo; returns whether it set a new record.
    @discardableResult
    func recordCombo(_ combo: Int) -> Bool {
        if combo > bestCombo {
            bestCombo = combo
            return true
        }
        return false
    }
}
