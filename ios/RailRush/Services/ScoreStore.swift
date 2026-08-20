import Foundation

/// Persists best score and total coin bank between runs.
final class ScoreStore {
    private enum Keys {
        static let bestScore = "railrush.bestScore"
        static let totalCoins = "railrush.totalCoins"
        static let selectedCharacter = "railrush.selectedCharacter"
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
}
