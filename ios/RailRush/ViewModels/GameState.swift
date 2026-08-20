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
    /// Meters covered in the current run, drives the HUD distance bar.
    var distanceRun = 0
    var multiplier = 1
    var activePowerUp: PowerUpType?
    var powerUpProgress: Double = 0
    var inspectorClose = false

    // Combo: consecutive note pickups within a short window.
    var comboCount = 0
    /// 0...1 time remaining in the current combo window, drives the drain bar.
    var comboProgress: Double = 0
    var bestComboThisRun = 0

    // Spray boost meter (mockup HUD): fills to 8, then Paint Rush fires.
    static let sprayMeterMax = 8
    var sprayMeter = 0
    var paintRushActive = false
    var paintRushProgress: Double = 0

    // Per-run mission counters
    var runJumps = 0
    var runSlides = 0
    var runPowerUps = 0
    var runSprays = 0

    // Persistent values
    var bestScore: Int
    var selectedCharacterID: String

    // Last run results
    var lastRunScore = 0
    var lastRunCoins = 0
    var lastRunWasBest = false
    var endReason: RunEndReason = .crashedIntoTrain

    /// Meta-game hub: wallet, missions, season, store, settings.
    let meta: MetaState

    private let store = ScoreStore()

    init() {
        bestScore = store.bestScore
        selectedCharacterID = store.selectedCharacterID
        meta = MetaState(legacyCoins: store.totalCoins)
    }

    /// Persists the chosen playable character between launches.
    func selectCharacter(_ id: String) {
        selectedCharacterID = id
        store.selectedCharacterID = id
    }

    func beginRun() {
        score = 0
        coins = 0
        distanceRun = 0
        multiplier = 1
        activePowerUp = nil
        powerUpProgress = 0
        inspectorClose = false
        comboCount = 0
        comboProgress = 0
        bestComboThisRun = 0
        sprayMeter = 0
        paintRushActive = false
        paintRushProgress = 0
        runJumps = 0
        runSlides = 0
        runPowerUps = 0
        runSprays = 0
        isPaused = false
        phase = .running
    }

    func finishRun(reason: RunEndReason) {
        endReason = reason
        lastRunScore = score
        lastRunCoins = coins
        lastRunWasBest = store.recordBest(score: score)
        bestScore = store.bestScore
        paintRushActive = false
        paintRushProgress = 0

        // Feed the meta layer: wallet, missions, season, weekly event.
        meta.applyRun(
            score: score,
            notesCollected: coins,
            spraysCollected: runSprays,
            jumps: runJumps,
            slides: runSlides,
            powerUps: runPowerUps
        )

        phase = .gameOver
    }
}
