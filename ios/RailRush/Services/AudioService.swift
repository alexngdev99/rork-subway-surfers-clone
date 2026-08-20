import AVFoundation

/// Bundled sound effects generated for the game.
enum SoundEffect: String, CaseIterable {
    case coin = "coin_pickup_ding"
    case jump = "cartoon_jump_whoosh"
    case crash = "cartoon_crash_clang"
    case powerUp = "magic_powerup_pop"
}

/// Plays bundled music and sound effects generated for the game.
final class AudioService {
    static let shared = AudioService()

    private var musicPlayer: AVAudioPlayer?
    private var sfxPlayers: [String: [AVAudioPlayer]] = [:]
    private var sfxIndex: [String: Int] = [:]

    private var jetpackPlayer: AVAudioPlayer?
    private var isJetpackLoopActive = false

    /// Settings toggles: music and SFX are muted independently.
    var musicEnabled = true {
        didSet { musicPlayer?.volume = musicEnabled ? musicVolume : 0 }
    }

    var sfxEnabled = true {
        didSet {
            jetpackPlayer?.volume = sfxEnabled ? jetpackVolume : 0
        }
    }

    private let musicVolume: Float = 0.45
    private let jetpackVolume: Float = 0.75
    private let musicResourceName = "funky_runner_theme"
    private let jetpackLoopResourceName = "jetpack_thruster_loop"

    private init() {
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
                    player.volume = 0.9
                    players.append(player)
                }
            }
            sfxPlayers[name] = players
            sfxIndex[name] = 0
        }
    }

    func startMusic() {
        if musicPlayer == nil,
           let url = Bundle.main.url(forResource: musicResourceName, withExtension: "mp3") {
            musicPlayer = try? AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1
        }
        musicPlayer?.volume = musicEnabled ? musicVolume : 0
        musicPlayer?.currentTime = 0
        musicPlayer?.play()
    }

    func stopMusic() {
        musicPlayer?.stop()
    }

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
        jetpackPlayer.volume = sfxEnabled ? jetpackVolume : 0
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
