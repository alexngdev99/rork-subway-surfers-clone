import Foundation

/// Redundant local save-data protection layer.
///
/// All progress already lives in UserDefaults (MetaStore / ScoreStore). This
/// service adds a second copy on disk (Application Support) so a corrupted or
/// wiped defaults database never loses the player's progress:
/// - `backupNow()` snapshots every game key into `beatrunner_save.plist`.
/// - `restoreIfNeeded()` runs at launch, and if defaults look empty while a
///   backup exists, replays the backup into UserDefaults before any store reads.
final class SaveDataService {
    static let shared = SaveDataService()

    /// All persisted game keys use one of these prefixes.
    private static let keyPrefixes = ["beatrunner.", "railrush."]
    /// Presence marker: set once the wallet migration ran, so an empty value
    /// means "fresh install or lost data".
    private static let sentinelKey = "beatrunner.walletMigrated"

    private let defaults = UserDefaults.standard
    private let fileManager = FileManager.default

    private init() {}

    /// Backup file lives in Application Support (backed up by iOS, not user-visible).
    private var backupURL: URL? {
        guard let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let directory = base.appendingPathComponent("BeatRunner", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory.appendingPathComponent("beatrunner_save.plist")
    }

    /// Snapshots every game key to the backup file. Cheap (a few KB) — safe to
    /// call after each run and whenever the app leaves the foreground.
    func backupNow() {
        guard let url = backupURL else { return }
        let snapshot = defaults.dictionaryRepresentation().filter { key, _ in
            Self.keyPrefixes.contains { key.hasPrefix($0) }
        }
        guard !snapshot.isEmpty else { return }
        do {
            let data = try PropertyListSerialization.data(
                fromPropertyList: snapshot,
                format: .binary,
                options: 0
            )
            try data.write(to: url, options: .atomic)
        } catch {
            print("[SaveData] backup failed: \(error.localizedDescription)")
        }
    }

    /// Restores the backup into UserDefaults when defaults have no save data
    /// but a backup file exists. Must run before MetaStore/ScoreStore reads.
    func restoreIfNeeded() {
        guard defaults.object(forKey: Self.sentinelKey) == nil,
              let url = backupURL,
              fileManager.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            guard let snapshot = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any] else { return }
            for (key, value) in snapshot where Self.keyPrefixes.contains(where: { key.hasPrefix($0) }) {
                defaults.set(value, forKey: key)
            }
            print("[SaveData] restored \(snapshot.count) keys from backup")
        } catch {
            print("[SaveData] restore failed: \(error.localizedDescription)")
        }
    }
}
