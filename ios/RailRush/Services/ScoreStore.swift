import Foundation

/// Persists best score and total coin bank between runs.
final class ScoreStore {
    private enum Keys {
        static let bestScore = "railrush.bestScore"
        static let totalCoins = "railrush.totalCoins"
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

    /// Records a finished run and returns whether it set a new best score.
    @discardableResult
    func recordRun(score: Int, coins: Int) -> Bool {
        totalCoins += coins
        if score > bestScore {
            bestScore = score
            return true
        }
        return false
    }
}
