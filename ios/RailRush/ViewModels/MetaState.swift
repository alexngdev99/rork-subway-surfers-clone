import Foundation
import Observation

/// Observable meta-game hub: wallet, missions, season, logins, store,
/// upgrades, weekly event, and settings. Single source of truth for every
/// screen outside the live run.
@Observable
final class MetaState {
    private let store = MetaStore()

    // MARK: Wallet

    var notes: Int { didSet { store.notes = notes } }
    var keys: Int { didSet { store.keys = keys } }
    var sprays: Int { didSet { store.sprays = sprays } }

    // MARK: Upgrades (level 1...7 per kind)

    var upgradeLevels: [UpgradeKind: Int]

    // MARK: Missions & season

    var dailyMissions: [Mission]
    var seasonMissions: [Mission]
    var seasonPoints: Int { didSet { store.seasonPoints = seasonPoints } }
    var seasonLevel: Int { didSet { store.seasonLevel = seasonLevel } }
    var seasonEnd: Date

    /// Season chest becomes claimable once the progress bar fills.
    var seasonChestReady: Bool { seasonPoints >= Self.seasonTarget }
    static let seasonTarget = 10

    // MARK: Daily login / free rewards

    var loginStreak: Int
    var dailyLoginReady: Bool
    var freeRewardReadyAt: Date
    var freeRewardReady: Bool { Date() >= freeRewardReadyAt }
    /// Auto-open guard so the login sheet pops only once per app session.
    var didAutoShowLogin = false

    // MARK: Weekly event

    var weeklyBest: Int
    var claimedTiers: Set<Int>

    // MARK: Lifetime stats

    var totalRuns: Int
    var lifetimeNotes: Int

    // MARK: Settings

    var musicOn: Bool {
        didSet {
            store.musicOn = musicOn
            AudioService.shared.musicEnabled = musicOn
        }
    }

    var sfxOn: Bool {
        didSet {
            store.sfxOn = sfxOn
            AudioService.shared.sfxEnabled = sfxOn
        }
    }

    var hapticsOn: Bool {
        didSet {
            store.hapticsOn = hapticsOn
            HapticsService.shared.isEnabled = hapticsOn
        }
    }

    var batterySaver: Bool { didSet { store.batterySaver = batterySaver } }

    /// Music volume 0...1, applied live to the music manager.
    var musicVolume: Double {
        didSet {
            store.musicVolume = musicVolume
            AudioService.shared.musicVolume = Float(musicVolume)
        }
    }

    /// Sound-effects volume 0...1.
    var sfxVolume: Double {
        didSet {
            store.sfxVolume = sfxVolume
            AudioService.shared.sfxVolume = Float(sfxVolume)
        }
    }

    /// Currently selected soundtrack (resource name).
    var musicTrackID: String {
        didSet {
            store.musicTrackID = musicTrackID
            AudioService.shared.selectTrack(id: musicTrackID)
        }
    }

    /// Steps the playlist forward/backward from the settings screen.
    func stepMusicTrack(_ delta: Int) {
        musicTrackID = AudioService.shared.stepTrack(delta).id
    }

    // MARK: Navigation

    /// Full-screen meta destination layered over the home hub (nil → home).
    var route: MetaRoute?

    // MARK: Init

    init(legacyCoins: Int) {
        store.migrateWalletIfNeeded(legacyCoins: legacyCoins)

        notes = store.notes
        keys = store.keys
        sprays = store.sprays

        var levels: [UpgradeKind: Int] = [:]
        let rawLevels = store.upgradeLevels
        for kind in UpgradeKind.allCases {
            levels[kind] = max(1, rawLevels[kind.rawValue] ?? 1)
        }
        upgradeLevels = levels

        dailyMissions = store.dailyMissions
        seasonMissions = store.seasonMissions
        seasonPoints = store.seasonPoints
        seasonLevel = store.seasonLevel
        seasonEnd = store.seasonEnd
        loginStreak = store.loginStreak
        dailyLoginReady = false
        freeRewardReadyAt = store.lastFreeReward.addingTimeInterval(Self.freeRewardInterval)
        weeklyBest = store.weeklyBest
        claimedTiers = Set(store.claimedTiers)
        totalRuns = store.totalRuns
        lifetimeNotes = store.lifetimeNotes
        musicOn = store.musicOn
        sfxOn = store.sfxOn
        hapticsOn = store.hapticsOn
        batterySaver = store.batterySaver
        musicVolume = store.musicVolume
        sfxVolume = store.sfxVolume
        let savedTrack = store.musicTrackID
        musicTrackID = savedTrack.isEmpty ? (AudioService.playlist.first?.id ?? "") : savedTrack

        AudioService.shared.musicEnabled = musicOn
        AudioService.shared.sfxEnabled = sfxOn
        AudioService.shared.musicVolume = Float(musicVolume)
        AudioService.shared.sfxVolume = Float(sfxVolume)
        AudioService.shared.setInitialTrack(id: musicTrackID)
        HapticsService.shared.isEnabled = hapticsOn

        refreshTimedContent()
    }

    private static let freeRewardInterval: TimeInterval = 4 * 3600

    // MARK: Day / week rollover

    /// Regenerates dailies, checks login availability, renews the season and
    /// weekly event when their windows lapse. Safe to call on every foreground.
    func refreshTimedContent() {
        let today = Self.dayString(Date())

        if store.dailyMissionsDay != today || dailyMissions.isEmpty {
            dailyMissions = Self.makeDailyMissions()
            store.dailyMissions = dailyMissions
            store.dailyMissionsDay = today
        }

        dailyLoginReady = store.lastLoginDay != today

        if seasonMissions.isEmpty {
            seasonMissions = Self.makeSeasonMissions(level: seasonLevel)
            store.seasonMissions = seasonMissions
        }

        if seasonEnd <= Date() {
            seasonEnd = Date().addingTimeInterval(21 * 24 * 3600)
            store.seasonEnd = seasonEnd
        }

        let week = Self.weekString(Date())
        if store.eventWeek != week {
            store.eventWeek = week
            weeklyBest = 0
            store.weeklyBest = 0
            claimedTiers = []
            store.claimedTiers = []
        }
    }

    // MARK: Run results → missions & wallet

    /// Applies a finished run to the wallet, missions, and event standings.
    func applyRun(score: Int, notesCollected: Int, spraysCollected: Int, jumps: Int, slides: Int, powerUps: Int) {
        notes += notesCollected
        sprays += spraysCollected
        lifetimeNotes += notesCollected
        store.lifetimeNotes = lifetimeNotes
        totalRuns += 1
        store.totalRuns = totalRuns

        if score > weeklyBest {
            weeklyBest = score
            store.weeklyBest = score
        }

        advanceMissions(kind: .collectNotes, by: notesCollected)
        advanceMissions(kind: .collectSprays, by: spraysCollected)
        advanceMissions(kind: .jumpTimes, by: jumps)
        advanceMissions(kind: .slideTimes, by: slides)
        advanceMissions(kind: .usePowerUps, by: powerUps)
        advanceMissions(kind: .completeRuns, by: 1)
        advanceMissions(kind: .scoreSingleRun, best: score)
        persistMissions()
    }

    private func advanceMissions(kind: MissionKind, by amount: Int = 0, best: Int = 0) {
        func advance(_ missions: inout [Mission]) {
            for index in missions.indices where missions[index].kind == kind && !missions[index].claimed {
                if kind == .scoreSingleRun {
                    missions[index].progress = max(missions[index].progress, best)
                } else {
                    missions[index].progress = min(missions[index].target, missions[index].progress + amount)
                }
            }
        }
        advance(&dailyMissions)
        advance(&seasonMissions)
    }

    private func persistMissions() {
        store.dailyMissions = dailyMissions
        store.seasonMissions = seasonMissions
    }

    // MARK: Claims

    /// Claims a completed mission: pays the reward and adds a season point.
    func claimMission(_ mission: Mission) {
        guard mission.canClaim else { return }
        if let index = dailyMissions.firstIndex(where: { $0.id == mission.id }) {
            dailyMissions[index].claimed = true
        } else if let index = seasonMissions.firstIndex(where: { $0.id == mission.id }) {
            seasonMissions[index].claimed = true
        } else {
            return
        }
        grant(mission.reward)
        seasonPoints = min(Self.seasonTarget, seasonPoints + 1)
        persistMissions()
        HapticsService.shared.powerUp()
    }

    /// Opens the big season chest, levels the season up, and refreshes goals.
    func claimSeasonChest() {
        guard seasonChestReady else { return }
        grant(RewardBundle(notes: 5000, keys: 5, sprays: 10))
        seasonPoints = 0
        seasonLevel += 1
        seasonMissions = Self.makeSeasonMissions(level: seasonLevel)
        persistMissions()
        HapticsService.shared.powerUp()
    }

    /// Claims today's login gift; consecutive days advance the 7-day track.
    func claimDailyLogin() {
        guard dailyLoginReady else { return }
        let today = Self.dayString(Date())
        let yesterday = Self.dayString(Date().addingTimeInterval(-24 * 3600))
        loginStreak = store.lastLoginDay == yesterday ? loginStreak + 1 : 1
        store.loginStreak = loginStreak
        store.lastLoginDay = today
        dailyLoginReady = false

        let day = LoginDay.week[(loginStreak - 1) % 7]
        grant(day.reward)
        HapticsService.shared.powerUp()
    }

    /// Claims the 4-hour free gift with a small randomized bundle.
    @discardableResult
    func claimFreeReward() -> RewardBundle? {
        guard freeRewardReady else { return nil }
        let roll = Int.random(in: 0...9)
        let reward: RewardBundle
        if roll < 6 {
            reward = RewardBundle(notes: Int.random(in: 3...6) * 100)
        } else if roll < 9 {
            reward = RewardBundle(sprays: Int.random(in: 1...3))
        } else {
            reward = RewardBundle(keys: 1)
        }
        grant(reward)
        store.lastFreeReward = Date()
        freeRewardReadyAt = Date().addingTimeInterval(Self.freeRewardInterval)
        HapticsService.shared.powerUp()
        return reward
    }

    /// Claims a weekly event tier once the weekly best clears its target.
    func claimEventTier(_ tier: EventTier) {
        guard weeklyBest >= tier.scoreTarget, !claimedTiers.contains(tier.id) else { return }
        claimedTiers.insert(tier.id)
        store.claimedTiers = Array(claimedTiers)
        grant(RewardBundle(keys: tier.keys))
        HapticsService.shared.powerUp()
    }

    // MARK: Store purchases (soft currency)

    @discardableResult
    func buyCoinPack(_ pack: CoinPack) -> Bool {
        guard keys >= pack.keyCost else { return false }
        keys -= pack.keyCost
        notes += pack.notes
        HapticsService.shared.powerUp()
        return true
    }

    @discardableResult
    func buyOffer(_ offer: OfferPack) -> Bool {
        guard keys >= offer.keyCost else { return false }
        keys -= offer.keyCost
        grant(offer.reward)
        HapticsService.shared.powerUp()
        return true
    }

    static let mysteryBoxCost = 15

    /// Opens a mystery box for keys; returns the rolled reward for the reveal.
    func openMysteryBox() -> MysteryReward? {
        guard keys >= Self.mysteryBoxCost else { return nil }
        keys -= Self.mysteryBoxCost

        let upgradable = UpgradeKind.allCases.filter { level(of: $0) < UpgradeKind.maxLevel }
        let roll = Int.random(in: 0...9)
        let reward: MysteryReward
        if roll < 4 {
            reward = .notes(Int.random(in: 2...8) * 1000)
        } else if roll < 7 {
            reward = .sprays(Int.random(in: 5...15))
        } else if roll < 9, let kind = upgradable.randomElement() {
            reward = .upgrade(kind)
        } else {
            reward = .keys(Int.random(in: 3...8))
        }

        switch reward {
        case .notes(let amount): notes += amount
        case .sprays(let amount): sprays += amount
        case .keys(let amount): keys += amount
        case .upgrade(let kind): setLevel(level(of: kind) + 1, for: kind)
        }
        HapticsService.shared.powerUp()
        return reward
    }

    // MARK: Upgrades

    func level(of kind: UpgradeKind) -> Int {
        upgradeLevels[kind] ?? 1
    }

    @discardableResult
    func buyUpgrade(_ kind: UpgradeKind) -> Bool {
        let current = level(of: kind)
        guard current < UpgradeKind.maxLevel else { return false }
        let cost = UpgradeKind.upgradeCost(fromLevel: current)
        guard notes >= cost else { return false }
        notes -= cost
        setLevel(current + 1, for: kind)
        HapticsService.shared.powerUp()
        return true
    }

    private func setLevel(_ level: Int, for kind: UpgradeKind) {
        upgradeLevels[kind] = min(UpgradeKind.maxLevel, level)
        var raw: [String: Int] = [:]
        for (key, value) in upgradeLevels { raw[key.rawValue] = value }
        store.upgradeLevels = raw
    }

    // MARK: Gameplay effect scaling

    /// Duration multiplier for timed power-ups (magnet / 2x / jetpack).
    func durationScale(for type: PowerUpType) -> Float {
        let kind: UpgradeKind
        switch type {
        case .magnet: kind = .magnet
        case .doubleScore: kind = .multiplier
        case .jetpack: kind = .jetpack
        }
        return 1 + 0.18 * Float(level(of: kind) - 1)
    }

    /// Jump velocity multiplier from the Super Sneakers track.
    var sneakerJumpBoost: Float {
        1 + 0.04 * Float(level(of: .sneakers) - 1)
    }

    // MARK: Badges

    var missionBadgeCount: Int {
        dailyMissions.filter(\.canClaim).count
            + seasonMissions.filter(\.canClaim).count
            + (seasonChestReady ? 1 : 0)
    }

    var eventsBadgeCount: Int {
        EventTier.all.filter { weeklyBest >= $0.scoreTarget && !claimedTiers.contains($0.id) }.count
    }

    // MARK: Helpers

    private func grant(_ reward: RewardBundle) {
        notes += reward.notes
        keys += reward.keys
        sprays += reward.sprays
    }

    private static func makeDailyMissions() -> [Mission] {
        [
            Mission(id: "d.notes", kind: .collectNotes, title: "COLLECT 150 NOTES", target: 150, progress: 0, reward: RewardBundle(notes: 300), claimed: false),
            Mission(id: "d.jump", kind: .jumpTimes, title: "JUMP 20 TIMES", target: 20, progress: 0, reward: RewardBundle(notes: 250), claimed: false),
            Mission(id: "d.slide", kind: .slideTimes, title: "SLIDE 15 TIMES", target: 15, progress: 0, reward: RewardBundle(sprays: 2), claimed: false),
            Mission(id: "d.runs", kind: .completeRuns, title: "COMPLETE 2 RUNS", target: 2, progress: 0, reward: RewardBundle(keys: 1), claimed: false),
        ]
    }

    private static func makeSeasonMissions(level: Int) -> [Mission] {
        let scale = max(1, level)
        return [
            Mission(id: "s.notes.\(level)", kind: .collectNotes, title: "COLLECT \((1000 * scale).formatted()) NOTES", target: 1000 * scale, progress: 0, reward: RewardBundle(notes: 1500), claimed: false),
            Mission(id: "s.jump.\(level)", kind: .jumpTimes, title: "JUMP \(100 * scale) TIMES", target: 100 * scale, progress: 0, reward: RewardBundle(notes: 1500), claimed: false),
            Mission(id: "s.score.\(level)", kind: .scoreSingleRun, title: "SCORE \((5000 * scale).formatted()) IN ONE RUN", target: 5000 * scale, progress: 0, reward: RewardBundle(keys: 2), claimed: false),
            Mission(id: "s.power.\(level)", kind: .usePowerUps, title: "USE \(8 * scale) POWER-UPS", target: 8 * scale, progress: 0, reward: RewardBundle(notes: 1500), claimed: false),
            Mission(id: "s.runs.\(level)", kind: .completeRuns, title: "COMPLETE \(10 * scale) RUNS", target: 10 * scale, progress: 0, reward: RewardBundle(sprays: 3), claimed: false),
        ]
    }

    private static func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func weekString(_ date: Date) -> String {
        let calendar = Calendar(identifier: .iso8601)
        let week = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.yearForWeekOfYear, from: date)
        return "\(year)-W\(week)"
    }
}
