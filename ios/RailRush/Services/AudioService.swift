import AVFoundation

/// Bundled sound effects generated for the game.
enum SoundEffect: String, CaseIterable {
    case coin = "coin_pickup_ding"
    case jump = "cartoon_jump_whoosh"
    case crash = "cartoon_crash_clang"
    case powerUp = "magic_powerup_pop"
    case reward = "reward_claim_jingle"
}

/// A bundled festival soundtrack entry.
struct MusicTrack: Identifiable, Equatable {
    /// Bundle resource name (mp3).
    let id: String
    let title: String
    let genre: String
}

/// Music manager + SFX player: rotates a festival playlist with independent,
/// user-adjustable music and SFX volume.
final class AudioService: NSObject {
    static let shared = AudioService()

    /// Festival playlist in rotation order. Missing files are skipped at load.
    static let playlist: [MusicTrack] = [
        MusicTrack(id: "festival_edm_anthem", title: "FESTIVAL ANTHEM", genre: "Big Room EDM"),
        MusicTrack(id: "funky_runner_theme", title: "FUNKY RUNNER", genre: "Funk House"),
        MusicTrack(id: "carnival_brass_samba", title: "CARNIVAL BRASS", genre: "Samba Party"),
        MusicTrack(id: "neon_synthwave_funk", title: "NEON GROOVE", genre: "Synthwave Funk"),
    ]

    private var musicPlayer: AVAudioPlayer?
    private var sfxPlayers: [String: [AVAudioPlayer]] = [:]
    private var sfxIndex: [String: Int] = [:]

    private var jetpackPlayer: AVAudioPlayer?
    private var isJetpackLoopActive = false

    /// True while the game wants music (home / running); false after a crash.
    private var musicSessionActive = false

    private(set) var currentTrackIndex = 0

    var currentTrack: MusicTrack { Self.playlist[currentTrackIndex] }

    /// Notifies the meta layer when the playlist rotates on its own (track
    /// finished naturally) so the now-playing UI and saved track stay in sync.
    var onTrackAutoAdvanced: ((MusicTrack) -> Void)?

    // MARK: Settings

    /// Settings toggles: music and SFX are muted independently.
    var musicEnabled = true {
        didSet { applyMusicVolume() }
    }

    var sfxEnabled = true {
        didSet { applySfxVolumes() }
    }

    /// User music volume 0...1 (scaled down so SFX stay readable over it).
    var musicVolume: Float = 0.7 {
        didSet { applyMusicVolume() }
    }

    /// User SFX volume 0...1.
    var sfxVolume: Float = 1.0 {
        didSet { applySfxVolumes() }
    }

    private static let musicGain: Float = 0.65
    private static let sfxGain: Float = 0.9
    private static let jetpackGain: Float = 0.75
    private let jetpackLoopResourceName = "jetpack_thruster_loop"

    private override init() {
        super.init()
        configureSession()
        preloadEffects()
    }

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AudioService] session setup failed: \(error.localizedDescription)")
        }
    }

    private func preloadEffects() {
        for effect in SoundEffect.allCases {
            let name = effect.rawValue
            guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { continue }
            // Two players per effect so rapid pickups (coins) can overlap.
            var players: [AVAudioPlayer] = []
            for _ in 0..<2 {
                if let player = try? AVAudioPlayer(contentsOf: url) {
                    player.prepareToPlay()
                    player.volume = Self.sfxGain * sfxVolume
                    players.append(player)
                }
            }
            sfxPlayers[name] = players
            sfxIndex[name] = 0
        }
    }

    // MARK: Music manager

    /// Begins (or resumes) the playlist. Does not restart a playing track.
    func startMusic() {
        musicSessionActive = true
        if let musicPlayer, musicPlayer.isPlaying {
            applyMusicVolume()
            return
        }
        playTrack(at: currentTrackIndex, fromStart: musicPlayer == nil)
    }

    /// Run kickoff: advances to the next playlist track and plays it from the
    /// beginning so every run starts with fresh start-game energy. Notifies the
    /// meta layer so the now-playing UI and saved track stay in sync.
    func startRunMusic() {
        musicSessionActive = true
        currentTrackIndex = (currentTrackIndex + 1) % Self.playlist.count
        playTrack(at: currentTrackIndex, fromStart: true)
        onTrackAutoAdvanced?(currentTrack)
    }

    func stopMusic() {
        musicSessionActive = false
        musicPlayer?.stop()
    }

    /// Restores the saved track at launch without starting playback.
    func setInitialTrack(id: String) {
        if let index = Self.playlist.firstIndex(where: { $0.id == id }) {
            currentTrackIndex = index
        }
    }

    /// Jumps to a specific track; keeps playing if a session is active.
    func selectTrack(id: String) {
        guard let index = Self.playlist.firstIndex(where: { $0.id == id }),
              index != currentTrackIndex || musicPlayer == nil else { return }
        currentTrackIndex = index
        if musicSessionActive {
            playTrack(at: index, fromStart: true)
        } else {
            musicPlayer = nil
        }
    }

    /// Steps forward/backward through the playlist (wraps around).
    func stepTrack(_ delta: Int) -> MusicTrack {
        let count = Self.playlist.count
        let index = ((currentTrackIndex + delta) % count + count) % count
        currentTrackIndex = index
        if musicSessionActive {
            playTrack(at: index, fromStart: true)
        } else {
            musicPlayer = nil
        }
        return currentTrack
    }

    private func playTrack(at index: Int, fromStart: Bool) {
        let track = Self.playlist[index]
        guard let url = Bundle.main.url(forResource: track.id, withExtension: "mp3") else {
            // Missing file: fall through to the next track that exists.
            if Self.playlist.contains(where: { Bundle.main.url(forResource: $0.id, withExtension: "mp3") != nil }) {
                currentTrackIndex = (index + 1) % Self.playlist.count
                playTrack(at: currentTrackIndex, fromStart: true)
            }
            return
        }

        if fromStart || musicPlayer?.url != url {
            musicPlayer = try? AVAudioPlayer(contentsOf: url)
            musicPlayer?.delegate = self
            musicPlayer?.numberOfLoops = 0
            musicPlayer?.currentTime = 0
        }
        applyMusicVolume()
        musicPlayer?.play()
    }

    /// Playlist rotation once a track finishes naturally.
    fileprivate func advanceAfterTrackEnd() {
        guard musicSessionActive else { return }
        currentTrackIndex = (currentTrackIndex + 1) % Self.playlist.count
        playTrack(at: currentTrackIndex, fromStart: true)
        onTrackAutoAdvanced?(currentTrack)
    }

    private func applyMusicVolume() {
        musicPlayer?.volume = musicEnabled ? musicVolume * Self.musicGain : 0
    }

    private func applySfxVolumes() {
        for players in sfxPlayers.values {
            for player in players {
                player.volume = Self.sfxGain * sfxVolume
            }
        }
        jetpackPlayer?.volume = sfxEnabled ? Self.jetpackGain * sfxVolume : 0
    }

    // MARK: SFX

    /// Starts the looping jetpack thruster sound (plays until stopped).
    func startJetpackLoop() {
        guard !isJetpackLoopActive else { return }
        if jetpackPlayer == nil,
           let url = Bundle.main.url(forResource: jetpackLoopResourceName, withExtension: "mp3") {
            jetpackPlayer = try? AVAudioPlayer(contentsOf: url)
            jetpackPlayer?.numberOfLoops = -1
            jetpackPlayer?.prepareToPlay()
        }
        guard let jetpackPlayer else { return }
        isJetpackLoopActive = true
        jetpackPlayer.volume = sfxEnabled ? Self.jetpackGain * sfxVolume : 0
        jetpackPlayer.currentTime = 0
        jetpackPlayer.play()
    }

    /// Stops the jetpack thruster loop with a quick natural cutoff.
    func stopJetpackLoop() {
        guard isJetpackLoopActive else { return }
        isJetpackLoopActive = false
        jetpackPlayer?.stop()
    }

    func play(_ effect: SoundEffect) {
        let name = effect.rawValue
        guard sfxEnabled, let players = sfxPlayers[name], !players.isEmpty else { return }
        let index = (sfxIndex[name] ?? 0) % players.count
        sfxIndex[name] = index + 1
        let player = players[index]
        player.currentTime = 0
        player.play()
    }
}

extension AudioService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            AudioService.shared.advanceAfterTrackEnd()
        }
    }
}
