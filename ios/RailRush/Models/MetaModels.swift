import Foundation

/// A bundle of currencies granted by missions, logins, packs, and boxes.
nonisolated struct RewardBundle: Codable, Equatable {
    var notes: Int = 0
    var keys: Int = 0
    var sprays: Int = 0

    /// Compact display like "1,500 ♪ + 2 keys" built by the UI from parts.
    var isEmpty: Bool { notes == 0 && keys == 0 && sprays == 0 }
}

/// What a mission asks the player to do. Progress is fed from run results.
nonisolated enum MissionKind: String, Codable {
    case collectNotes
    case jumpTimes
    case slideTimes
    case scoreSingleRun
    case completeRuns
    case usePowerUps
    case collectSprays
}

/// One claimable mission with live progress.
nonisolated struct Mission: Codable, Identifiable, Equatable {
    let id: String
    let kind: MissionKind
    let title: String
    let target: Int
    var progress: Int
    let reward: RewardBundle
    var claimed: Bool

    var isComplete: Bool { progress >= target }
    var canClaim: Bool { isComplete && !claimed }
}

/// Permanent power-up upgrade tracks (7 levels each).
enum UpgradeKind: String, CaseIterable, Identifiable {
    case jetpack
    case sneakers
    case magnet
    case multiplier

    var id: String { rawValue }
    static let maxLevel = 7

    var displayName: String {
        switch self {
        case .jetpack: return "Rocket Kicks"
        case .sneakers: return "Super Sneakers"
        case .magnet: return "Note Magnet"
        case .multiplier: return "2x Beat"
        }
    }

    var subtitle: String {
        switch self {
        case .jetpack: return "Fly into the sky!"
        case .sneakers: return "Jump higher!"
        case .magnet: return "Attract notes!"
        case .multiplier: return "Double your score!"
        }
    }

    /// Generated sticker icon in the asset catalog.
    var iconAsset: String {
        switch self {
        case .jetpack: return "twin_tank_jetpack"
        case .sneakers: return "red_white_sneaker_lightning"
        case .magnet: return "magnet_music_notes_spark"
        case .multiplier: return "gold_star_2x_multiplier"
        }
    }

    /// Note cost to advance FROM the given level.
    static func upgradeCost(fromLevel level: Int) -> Int { 400 * level }
}

/// Tabs of the store screen (mockup: OFFERS / COINS / POWER-UPS / MYSTERY).
enum StoreTab: String, CaseIterable, Identifiable {
    case offers
    case coins
    case powerUps
    case mystery

    var id: String { rawValue }

    var label: String {
        switch self {
        case .offers: return "OFFERS"
        case .coins: return "COINS"
        case .powerUps: return "POWER-UPS"
        case .mystery: return "MYSTERY"
        }
    }

    var symbol: String {
        switch self {
        case .offers: return "tag.fill"
        case .coins: return "star.circle.fill"
        case .powerUps: return "bolt.fill"
        case .mystery: return "cube.box.fill"
        }
    }

    /// Generated sticker art for the tab icon (falls back to `symbol`).
    var iconAsset: String {
        switch self {
        case .offers: return "price_tag_sticker"
        case .coins: return "gold_coin_music_note"
        case .powerUps: return "lightning_bolt_sticker"
        case .mystery: return "mystery_cube_box_coins"
        }
    }
}

/// Full-screen meta destinations layered over the home hub.
enum MetaRoute: Equatable {
    case missions
    case dailyLogin
    case freeRewards
    case store(StoreTab)
    case characters
    case me
    case events
    case settings

    /// True for opaque full-screen destinations that completely cover the
    /// home hub and the 3D scene (everything except the reward dialogs).
    var coversScene: Bool {
        self != .dailyLogin && self != .freeRewards
    }
}

/// A purchasable pile of notes, priced in keys (soft-currency store).
struct CoinPack: Identifiable {
    let id: Int
    let notes: Int
    let keyCost: Int
    let iconAsset: String
    let badge: String?

    static let all: [CoinPack] = [
        CoinPack(id: 0, notes: 2500, keyCost: 5, iconAsset: "gold_coins_pile", badge: nil),
        CoinPack(id: 1, notes: 6500, keyCost: 12, iconAsset: "money_bag_coins", badge: "MOST POPULAR!"),
        CoinPack(id: 2, notes: 15000, keyCost: 25, iconAsset: "treasure_chest_coins", badge: nil),
        CoinPack(id: 3, notes: 40000, keyCost: 45, iconAsset: "glossy_3d_cartoon", badge: "BEST VALUE!"),
    ]
}

/// Special offer bundle (starter pack / mega bundle).
struct OfferPack: Identifiable {
    let id: String
    let title: String
    let iconAsset: String
    let reward: RewardBundle
    let keyCost: Int
    let discountLabel: String?

    static let starter = OfferPack(
        id: "starter",
        title: "STARTER PACK",
        iconAsset: "duffel_bag_paint_splashes",
        reward: RewardBundle(notes: 5000, keys: 0, sprays: 10),
        keyCost: 8,
        discountLabel: nil
    )

    static let mega = OfferPack(
        id: "mega",
        title: "MEGA BUNDLE",
        iconAsset: "crate_paint_cans_coins",
        reward: RewardBundle(notes: 25000, keys: 0, sprays: 30),
        keyCost: 20,
        discountLabel: "-70%"
    )
}

/// What tumbles out of a mystery box.
enum MysteryReward: Equatable {
    case notes(Int)
    case sprays(Int)
    case keys(Int)
    case upgrade(UpgradeKind)

    var title: String {
        switch self {
        case .notes(let amount): return "\(amount.formatted()) NOTES"
        case .sprays(let amount): return "\(amount) SPRAY CANS"
        case .keys(let amount): return "\(amount) KEYS"
        case .upgrade(let kind): return "FREE UPGRADE: \(kind.displayName.uppercased())"
        }
    }

    var iconAsset: String {
        switch self {
        case .notes: return "money_bag_coins"
        case .sprays: return "spray_can_lightning"
        case .keys: return "skeleton_key_blue"
        case .upgrade(let kind): return kind.iconAsset
        }
    }
}

/// Weekly event reward tier.
struct EventTier: Identifiable {
    let id: Int
    let scoreTarget: Int
    let keys: Int

    static let all: [EventTier] = [
        EventTier(id: 0, scoreTarget: 2500, keys: 2),
        EventTier(id: 1, scoreTarget: 6000, keys: 3),
        EventTier(id: 2, scoreTarget: 12000, keys: 5),
    ]
}

/// Daily login calendar — 7 escalating gifts.
struct LoginDay: Identifiable {
    let id: Int
    let reward: RewardBundle

    static let week: [LoginDay] = [
        LoginDay(id: 0, reward: RewardBundle(notes: 500)),
        LoginDay(id: 1, reward: RewardBundle(notes: 750)),
        LoginDay(id: 2, reward: RewardBundle(sprays: 3)),
        LoginDay(id: 3, reward: RewardBundle(notes: 1000)),
        LoginDay(id: 4, reward: RewardBundle(keys: 2)),
        LoginDay(id: 5, reward: RewardBundle(sprays: 5)),
        LoginDay(id: 6, reward: RewardBundle(notes: 2500, keys: 3)),
    ]
}
