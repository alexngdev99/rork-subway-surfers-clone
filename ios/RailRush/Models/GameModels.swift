import Foundation

/// High-level phase of the app / game session.
enum GamePhase {
    case loading
    case home
    case running
    case gameOver
}

/// Power-ups the runner can collect during a run.
enum PowerUpType: CaseIterable {
    case magnet
    case doubleScore
    case superJump
    case jetpack

    var displayName: String {
        switch self {
        case .magnet: return "Note Magnet"
        case .doubleScore: return "2x Beat"
        case .superJump: return "Rocket Kicks"
        case .jetpack: return "Jetpack"
        }
    }

    var symbolName: String {
        switch self {
        case .magnet: return "wand.and.stars"
        case .doubleScore: return "music.note"
        case .superJump: return "bolt.fill"
        case .jetpack: return "flame.fill"
        }
    }

    /// Generated sticker art for HUD badges (falls back to `symbolName`).
    var iconAssetName: String {
        switch self {
        case .magnet: return "magnet_music_notes_spark"
        case .doubleScore: return "gold_star_2x_multiplier"
        case .superJump: return "red_white_sneaker_lightning"
        case .jetpack: return "twin_tank_jetpack"
        }
    }

    var duration: Float {
        switch self {
        case .magnet: return 8
        case .doubleScore: return 8
        case .superJump: return 8
        case .jetpack: return 6
        }
    }
}

/// Kinds of obstacles that can appear on the tracks.
enum ObstacleKind {
    case trainParked
    case trainMoving
    case barrierLow
    case barrierOverhead
}

/// Why the run ended — used for game-over flavor text.
enum RunEndReason {
    case crashedIntoTrain
    case hitBarrier
    case caughtByInspector

    var message: String {
        switch self {
        case .crashedIntoTrain: return "Smacked into a train!"
        case .hitBarrier: return "Tripped on a barrier!"
        case .caughtByInspector: return "The inspector got you!"
        }
    }
}
