import Foundation
import Observation

/// Observable game session state driving the SwiftUI HUD and overlays.
@Observable
final class GameState {
    var phase: GamePhase = .loading
    var isPaused = false

    /// 0...1 progress of the initial 3D asset preload, drives the loading screen.
    var loadingProgress: Double = 0

    // Live run values
    var score = 0
    var coins = 0
    var multiplier = 1
    var activePowerUp: PowerUpType?
    var powerUpProgress: Double = 0
    var inspectorClose = false

    // Persistent values
    var bestScore: Int
    var totalCoins: Int
    var selectedCharacterID: String

    // Last run results
    var lastRunScore = 0
    var lastRunCoins = 0
    var lastRunWasBest = false
    var endReason: RunEndReason = .crashedIntoTrain

    private let store = ScoreStore()

    init() {
        bestScore = store.bestScore
        totalCoins = store.totalCoins
        selectedCharacterID = store.selectedCharacterID
    }

    /// Persists the chosen playable character between launches.
    func selectCharacter(_ id: String) {
        selectedCharacterID = id
        store.selectedCharacterID = id
    }

    func beginRun() {
        score = 0
        coins = 0
        multiplier = 1
        activePowerUp = nil
        powerUpProgress = 0
        inspectorClose = false
        isPaused = false
        phase = .running
    }

    func finishRun(reason: RunEndReason) {
        endReason = reason
        lastRunScore = score
        lastRunCoins = coins
        lastRunWasBest = store.recordRun(score: score, coins: coins)
        bestScore = store.bestScore
        totalCoins = store.totalCoins
        phase = .gameOver
    }
}
