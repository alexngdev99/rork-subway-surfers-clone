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
    case jetpack

    var displayName: String {
        switch self {
        case .magnet: return "Note Magnet"
        case .doubleScore: return "2x Beat"
        case .jetpack: return "Rocket Kicks"
        }
    }

    var symbolName: String {
        switch self {
        case .magnet: return "wand.and.stars"
        case .doubleScore: return "music.note"
        case .jetpack: return "bolt.fill"
        }
    }

    var duration: Float {
        switch self {
        case .magnet: return 8
        case .doubleScore: return 8
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
