import Foundation

/// Persists the whole meta-game (wallet, missions, season, logins, settings,
/// upgrades, event progress) in UserDefaults. Collections are stored as JSON.
final class MetaStore {
    private enum Keys {
        static let walletMigrated = "beatrunner.walletMigrated"
        static let notes = "beatrunner.notes"
        static let keys = "beatrunner.keys"
        static let sprays = "beatrunner.sprays"
        static let upgradeLevels = "beatrunner.upgradeLevels"
        static let dailyMissions = "beatrunner.dailyMissions"
        static let dailyMissionsDay = "beatrunner.dailyMissionsDay"
        static let seasonMissions = "beatrunner.seasonMissions"
        static let seasonPoints = "beatrunner.seasonPoints"
        static let seasonLevel = "beatrunner.seasonLevel"
        static let seasonEnd = "beatrunner.seasonEnd"
        static let loginStreak = "beatrunner.loginStreak"
        static let lastLoginDay = "beatrunner.lastLoginDay"
        static let lastFreeReward = "beatrunner.lastFreeReward"
        static let musicOn = "beatrunner.musicOn"
        static let sfxOn = "beatrunner.sfxOn"
        static let musicVolume = "beatrunner.musicVolume"
        static let sfxVolume = "beatrunner.sfxVolume"
        static let musicTrack = "beatrunner.musicTrack"
        static let hapticsOn = "beatrunner.hapticsOn"
        static let batterySaver = "beatrunner.batterySaver"
        static let totalRuns = "beatrunner.totalRuns"
        static let lifetimeNotes = "beatrunner.lifetimeNotes"
        static let eventWeek = "beatrunner.eventWeek"
        static let weeklyBest = "beatrunner.weeklyBest"
        static let claimedTiers = "beatrunner.claimedTiers"
    }

    private let defaults = UserDefaults.standard

    // MARK: Wallet

    /// One-time migration: seed the note wallet from the legacy coin bank.
    func migrateWalletIfNeeded(legacyCoins: Int) {
        guard !defaults.bool(forKey: Keys.walletMigrated) else { return }
        defaults.set(true, forKey: Keys.walletMigrated)
        defaults.set(legacyCoins, forKey: Keys.notes)
        // Friendly head start so the store is explorable on day one.
        defaults.set(5, forKey: Keys.keys)
        defaults.set(3, forKey: Keys.sprays)
    }

    var notes: Int {
        get { defaults.integer(forKey: Keys.notes) }
        set { defaults.set(newValue, forKey: Keys.notes) }
    }

    var keys: Int {
        get { defaults.integer(forKey: Keys.keys) }
        set { defaults.set(newValue, forKey: Keys.keys) }
    }

    var sprays: Int {
        get { defaults.integer(forKey: Keys.sprays) }
        set { defaults.set(newValue, forKey: Keys.sprays) }
    }

    // MARK: Upgrades

    var upgradeLevels: [String: Int] {
        get { decode([String: Int].self, forKey: Keys.upgradeLevels) ?? [:] }
        set { encode(newValue, forKey: Keys.upgradeLevels) }
    }

    // MARK: Missions

    var dailyMissions: [Mission] {
        get { decode([Mission].self, forKey: Keys.dailyMissions) ?? [] }
        set { encode(newValue, forKey: Keys.dailyMissions) }
    }

    var dailyMissionsDay: String {
        get { defaults.string(forKey: Keys.dailyMissionsDay) ?? "" }
        set { defaults.set(newValue, forKey: Keys.dailyMissionsDay) }
    }

    var seasonMissions: [Mission] {
        get { decode([Mission].self, forKey: Keys.seasonMissions) ?? [] }
        set { encode(newValue, forKey: Keys.seasonMissions) }
    }

    var seasonPoints: Int {
        get { defaults.integer(forKey: Keys.seasonPoints) }
        set { defaults.set(newValue, forKey: Keys.seasonPoints) }
    }

    var seasonLevel: Int {
        get { max(1, defaults.integer(forKey: Keys.seasonLevel)) }
        set { defaults.set(newValue, forKey: Keys.seasonLevel) }
    }

    var seasonEnd: Date {
        get {
            let raw = defaults.double(forKey: Keys.seasonEnd)
            return raw > 0 ? Date(timeIntervalSince1970: raw) : .distantPast
        }
        set { defaults.set(newValue.timeIntervalSince1970, forKey: Keys.seasonEnd) }
    }

    // MARK: Login & free rewards

    var loginStreak: Int {
        get { defaults.integer(forKey: Keys.loginStreak) }
        set { defaults.set(newValue, forKey: Keys.loginStreak) }
    }

    var lastLoginDay: String {
        get { defaults.string(forKey: Keys.lastLoginDay) ?? "" }
        set { defaults.set(newValue, forKey: Keys.lastLoginDay) }
    }

    var lastFreeReward: Date {
        get {
            let raw = defaults.double(forKey: Keys.lastFreeReward)
            return raw > 0 ? Date(timeIntervalSince1970: raw) : .distantPast
        }
        set { defaults.set(newValue.timeIntervalSince1970, forKey: Keys.lastFreeReward) }
    }

    // MARK: Settings (default ON except battery saver)

    var musicOn: Bool {
        get { defaults.object(forKey: Keys.musicOn) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.musicOn) }
    }

    var sfxOn: Bool {
        get { defaults.object(forKey: Keys.sfxOn) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.sfxOn) }
    }

    var hapticsOn: Bool {
        get { defaults.object(forKey: Keys.hapticsOn) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.hapticsOn) }
    }

    var batterySaver: Bool {
        get { defaults.bool(forKey: Keys.batterySaver) }
        set { defaults.set(newValue, forKey: Keys.batterySaver) }
    }

    var musicVolume: Double {
        get { defaults.object(forKey: Keys.musicVolume) as? Double ?? 0.7 }
        set { defaults.set(newValue, forKey: Keys.musicVolume) }
    }

    var sfxVolume: Double {
        get { defaults.object(forKey: Keys.sfxVolume) as? Double ?? 1.0 }
        set { defaults.set(newValue, forKey: Keys.sfxVolume) }
    }

    /// Selected soundtrack resource name (empty = playlist default).
    var musicTrackID: String {
        get { defaults.string(forKey: Keys.musicTrack) ?? "" }
        set { defaults.set(newValue, forKey: Keys.musicTrack) }
    }

    // MARK: Lifetime stats

    var totalRuns: Int {
        get { defaults.integer(forKey: Keys.totalRuns) }
        set { defaults.set(newValue, forKey: Keys.totalRuns) }
    }

    var lifetimeNotes: Int {
        get { defaults.integer(forKey: Keys.lifetimeNotes) }
        set { defaults.set(newValue, forKey: Keys.lifetimeNotes) }
    }

    // MARK: Weekly event

    var eventWeek: String {
        get { defaults.string(forKey: Keys.eventWeek) ?? "" }
        set { defaults.set(newValue, forKey: Keys.eventWeek) }
    }

    var weeklyBest: Int {
        get { defaults.integer(forKey: Keys.weeklyBest) }
        set { defaults.set(newValue, forKey: Keys.weeklyBest) }
    }

    var claimedTiers: [Int] {
        get { decode([Int].self, forKey: Keys.claimedTiers) ?? [] }
        set { encode(newValue, forKey: Keys.claimedTiers) }
    }

    // MARK: JSON helpers

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }
}
