import SwiftUI

// MARK: - ME (profile)

/// Profile screen: avatar card, lifetime stats, and small achievements.
struct MeView: View {
    let state: GameState
    let meta: MetaState

    private var character: RunnerCharacterAssets {
        GeneratedAssets.character(withID: state.selectedCharacterID)
    }

    var body: some View {
        MetaScreen {
            VStack(spacing: 0) {
                CurrencyBar(meta: meta)
                    .padding(.horizontal, 14)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        profileCard

                        Button {
                            meta.route = .characters
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundStyle(.white)
                                    .shadow(color: GameTheme.outline.opacity(0.9), radius: 0, y: 1.5)
                                OutlinedText(text: "CHANGE CHARACTER", size: 17)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ChunkyButtonStyle(palette: .purple, height: 54, cornerRadius: 16))

                        statsPanel

                        achievementsPanel
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }

                BottomNavBar(active: .me, meta: meta) { tab in
                    meta.route = tab.route
                }
                .padding(.bottom, 4)
            }
        }
    }

    private var profileCard: some View {
        HStack(spacing: 14) {
            if let avatarName = character.avatarImageName, let image = UIImage(named: avatarName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 130)
            }

            VStack(alignment: .leading, spacing: 6) {
                OutlinedText(text: character.displayName.uppercased(), size: 30)
                Text("Core Crew Runner")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.72, green: 0.60, blue: 0.95))

                HStack(spacing: 6) {
                    AssetIcon(name: "gold_sun_medal_s", size: 26, fallbackSymbol: "seal.fill")
                    OutlinedText(text: "SEASON \(meta.seasonLevel)", size: 14)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(metaPanelBackground)
    }

    private var statsPanel: some View {
        VStack(spacing: 8) {
            OutlinedText(text: "STATS", size: 17)

            StatRow(symbol: "trophy.fill", label: "BEST SCORE", value: state.bestScore.formatted())
            StatRow(symbol: "flag.checkered", label: "TOTAL RUNS", value: meta.totalRuns.formatted())
            StatRow(symbol: "music.note", label: "LIFETIME NOTES", value: meta.lifetimeNotes.formatted())
            StatRow(symbol: "star.fill", label: "SEASON LEVEL", value: "\(meta.seasonLevel)")
        }
        .padding(14)
        .background(metaPanelBackground)
    }

    private var achievementsPanel: some View {
        VStack(spacing: 10) {
            OutlinedText(text: "ACHIEVEMENTS", size: 17)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                AchievementChip(title: "FIRST RUN", symbol: "figure.run", unlocked: meta.totalRuns >= 1)
                AchievementChip(title: "1K NOTES", symbol: "music.note.list", unlocked: meta.lifetimeNotes >= 1000)
                AchievementChip(title: "SCORE 5,000", symbol: "star.circle.fill", unlocked: state.bestScore >= 5000)
                AchievementChip(title: "SEASON 3", symbol: "crown.fill", unlocked: meta.seasonLevel >= 3)
            }
        }
        .padding(14)
        .background(metaPanelBackground)
    }
}

private struct StatRow: View {
    let symbol: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(GameTheme.gold)
                .frame(width: 26)
            Text(label)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
            OutlinedText(text: value, size: 18)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.10, green: 0.05, blue: 0.24).opacity(0.85))
        )
    }
}

private struct AchievementChip: View {
    let title: String
    let symbol: String
    let unlocked: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: unlocked ? symbol : "lock.fill")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(unlocked ? GameTheme.gold : .white.opacity(0.4))
            OutlinedText(text: title, size: 12)
                .opacity(unlocked ? 1 : 0.55)
            Spacer()
            if unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Color(red: 0.45, green: 0.85, blue: 0.30))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.10, green: 0.05, blue: 0.24).opacity(unlocked ? 0.9 : 0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            unlocked ? GameTheme.gold.opacity(0.5) : .white.opacity(0.1),
                            lineWidth: 1.5
                        )
                )
        )
    }
}

// MARK: - EVENTS

/// Weekly "Festival Frenzy" score race with claimable key tiers.
struct EventsView: View {
    let meta: MetaState

    var body: some View {
        MetaScreen {
            VStack(spacing: 0) {
                CurrencyBar(meta: meta)
                    .padding(.horizontal, 14)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        AssetIcon(name: "trophy_cup_star", size: 110, fallbackSymbol: "trophy.fill")
                            .shadow(color: GameTheme.gold.opacity(0.55), radius: 16)

                        VStack(spacing: 2) {
                            OutlinedText(
                                text: "FESTIVAL FRENZY",
                                size: 30,
                                fill: AnyShapeStyle(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.88, blue: 0.35), GameTheme.goldDeep],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            )
                            Text("WEEKLY SCORE RACE")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(Color(red: 0.72, green: 0.60, blue: 0.95))
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "stopwatch.fill")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(GameTheme.gold)
                            OutlinedText(text: "Resets \(Self.weekEndText())", size: 13)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(GameTheme.chip, in: Capsule())
                        .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1.5))

                        // This week's best score
                        VStack(spacing: 4) {
                            Text("YOUR BEST THIS WEEK")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(GameTheme.gold)
                            OutlinedText(text: meta.weeklyBest.formatted(), size: 44)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(metaPanelBackground)

                        ForEach(EventTier.all) { tier in
                            EventTierRow(
                                tier: tier,
                                weeklyBest: meta.weeklyBest,
                                claimed: meta.claimedTiers.contains(tier.id),
                                onClaim: {
                                    withAnimation(.spring(duration: 0.35)) {
                                        meta.claimEventTier(tier)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }

                BottomNavBar(active: .events, meta: meta) { tab in
                    meta.route = tab.route
                }
                .padding(.bottom, 4)
            }
        }
    }

    private static func weekEndText() -> String {
        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = 2
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return "soon" }
        let remaining = max(0, interval.end.timeIntervalSinceNow)
        let days = Int(remaining) / 86400
        let hours = (Int(remaining) % 86400) / 3600
        return "in \(days)d \(hours)h"
    }
}

private struct EventTierRow: View {
    let tier: EventTier
    let weeklyBest: Int
    let claimed: Bool
    let onClaim: () -> Void

    private var reached: Bool { weeklyBest >= tier.scoreTarget }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "rosette")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(reached ? GameTheme.gold : .white.opacity(0.4))
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 5) {
                OutlinedText(text: "SCORE \(tier.scoreTarget.formatted())", size: 15)
                MetaProgressBar(progress: min(weeklyBest, tier.scoreTarget), target: tier.scoreTarget, height: 17)
            }

            VStack(spacing: 3) {
                if claimed {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(Color(red: 0.45, green: 0.85, blue: 0.30))
                    OutlinedText(text: "DONE", size: 11)
                } else if reached {
                    Button(action: onClaim) {
                        OutlinedText(text: "CLAIM", size: 13)
                            .frame(width: 70)
                    }
                    .buttonStyle(ChunkyButtonStyle(palette: .green, height: 34, cornerRadius: 10))
                } else {
                    HStack(spacing: 3) {
                        OutlinedText(text: "\(tier.keys)", size: 16)
                        AssetIcon(name: "skeleton_key_blue", size: 17, fallbackSymbol: "key.fill")
                    }
                }
            }
            .frame(width: 80)
        }
        .padding(12)
        .background(metaPanelBackground)
        .opacity(claimed ? 0.75 : 1)
    }
}

// MARK: - SETTINGS

/// Settings screen (mockup 6): graffiti logo + purple rows with green toggles.
struct SettingsView: View {
    @Bindable var meta: MetaState

    @State private var infoSheet: InfoSheet?

    private enum InfoSheet: String, Identifiable {
        case privacy
        case support
        var id: String { rawValue }
    }

    var body: some View {
        MetaScreen {
            VStack(spacing: 0) {
                CurrencyBar(meta: meta, showsSettings: false)
                    .padding(.horizontal, 14)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if let logo = UIImage(named: "settings_crown_graffiti") {
                            Image(uiImage: logo)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                        } else {
                            OutlinedText(text: "SETTINGS", size: 40)
                        }

                        SettingToggleRow(
                            symbol: "music.note",
                            symbolColors: [GameTheme.magenta, GameTheme.goldDeep],
                            title: "MUSIC",
                            subtitle: "Toggle background music",
                            isOn: $meta.musicOn
                        )

                        SoundtrackPanel(meta: meta)

                        SettingToggleRow(
                            symbol: "speaker.wave.2.fill",
                            symbolColors: [GameTheme.gold, GameTheme.goldDeep],
                            title: "SOUND EFFECTS",
                            subtitle: "Toggle game sound effects",
                            isOn: $meta.sfxOn
                        )

                        VolumeSliderRow(
                            symbol: "speaker.wave.3.fill",
                            symbolColors: [GameTheme.gold, GameTheme.goldDeep],
                            title: "SFX VOLUME",
                            value: $meta.sfxVolume,
                            enabled: meta.sfxOn
                        )
                        SettingToggleRow(
                            symbol: "iphone.radiowaves.left.and.right",
                            symbolColors: [GameTheme.gold, GameTheme.magenta],
                            title: "VIBRATION",
                            subtitle: "Toggle device vibration",
                            isOn: $meta.hapticsOn
                        )
                        SettingToggleRow(
                            symbol: "battery.100percent.bolt",
                            symbolColors: [Color(red: 0.45, green: 0.85, blue: 0.30), Color(red: 0.20, green: 0.60, blue: 0.15)],
                            title: "BATTERY SAVER",
                            subtitle: "Reduce effects to save battery",
                            isOn: $meta.batterySaver
                        )

                        SettingLinkRow(
                            symbol: "globe",
                            symbolColors: [GameTheme.teal, Color(red: 0.10, green: 0.55, blue: 0.55)],
                            title: "LANGUAGE",
                            subtitle: "Select your preferred language"
                        ) {
                            OutlinedText(text: "ENGLISH", size: 13)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(GameTheme.well, in: Capsule())
                                .overlay(Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 1.5))
                        }

                        Button { infoSheet = .privacy } label: {
                            SettingLinkRow(
                                symbol: "shield.lefthalf.filled",
                                symbolColors: [GameTheme.gold, GameTheme.goldDeep],
                                title: "PRIVACY POLICY",
                                subtitle: "Read our privacy policy"
                            ) {
                                chevron
                            }
                        }
                        .buttonStyle(PressableButtonStyle())

                        Button { infoSheet = .support } label: {
                            SettingLinkRow(
                                symbol: "headphones",
                                symbolColors: [GameTheme.magenta, Color(red: 0.60, green: 0.12, blue: 0.45)],
                                title: "SUPPORT",
                                subtitle: "Get help and contact us"
                            ) {
                                chevron
                            }
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                }

                BottomNavBar(active: .home, meta: meta) { tab in
                    meta.route = tab.route
                }
                .padding(.bottom, 4)
            }
        }
        .sheet(item: $infoSheet) { sheet in
            InfoSheetView(
                title: sheet == .privacy ? "Privacy Policy" : "Support",
                message: sheet == .privacy
                    ? "Beat Runner stores your scores, wallet, and settings only on this device. No personal data is collected, shared, or sent anywhere."
                    : "Need help with Beat Runner? All progress is saved automatically on your device. Restart the app if something looks stuck — your notes, keys, and sprays are safe."
            )
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 16, weight: .black))
            .foregroundStyle(.white.opacity(0.8))
    }
}

/// Music manager panel: now-playing card with track stepper + volume slider.
private struct SoundtrackPanel: View {
    @Bindable var meta: MetaState

    private var currentTrack: MusicTrack {
        AudioService.playlist.first(where: { $0.id == meta.musicTrackID })
            ?? AudioService.playlist[0]
    }

    private var trackNumber: Int {
        (AudioService.playlist.firstIndex(where: { $0.id == meta.musicTrackID }) ?? 0) + 1
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "radio.fill")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(GameTheme.magenta)
                Text("FESTIVAL SOUNDTRACK")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.72, green: 0.60, blue: 0.95))
                Spacer()
                Text("\(trackNumber)/\(AudioService.playlist.count)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }

            HStack(spacing: 10) {
                TrackStepButton(symbol: "backward.fill") {
                    meta.stepMusicTrack(-1)
                    HapticsService.shared.laneChange()
                }

                VStack(spacing: 3) {
                    // Animated equalizer bars flank the title while music is on.
                    HStack(spacing: 7) {
                        EqualizerBars(active: meta.musicOn)
                        OutlinedText(text: currentTrack.title, size: 17)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        EqualizerBars(active: meta.musicOn)
                    }
                    Text(currentTrack.genre.uppercased())
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(GameTheme.gold)
                        .tracking(1.2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.10, green: 0.05, blue: 0.24).opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(GameTheme.magenta.opacity(0.45), lineWidth: 1.5)
                        )
                )

                TrackStepButton(symbol: "forward.fill") {
                    meta.stepMusicTrack(1)
                    HapticsService.shared.laneChange()
                }
            }

            VolumeSlider(
                symbol: "music.quarternote.3",
                value: $meta.musicVolume,
                enabled: meta.musicOn,
                tint: GameTheme.magenta
            )
        }
        .padding(12)
        .background(settingRowBackground)
        .opacity(meta.musicOn ? 1 : 0.6)
    }
}

private struct TrackStepButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(.white)
                .shadow(color: GameTheme.outline.opacity(0.9), radius: 0, y: 1.5)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(ChunkyButtonStyle(palette: .purple, height: 44, cornerRadius: 13))
        .frame(width: 44)
    }
}

/// Tiny 3-bar equalizer that bounces while music is enabled.
private struct EqualizerBars: View {
    let active: Bool
    @State private var animating = false

    private let heights: [CGFloat] = [7, 13, 9]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(GameTheme.gold)
                    .frame(width: 3, height: animating && active ? heights[(index + 1) % 3] : heights[index])
                    .animation(
                        active
                            ? .easeInOut(duration: 0.38).repeatForever(autoreverses: true).delay(Double(index) * 0.12)
                            : .default,
                        value: animating
                    )
            }
        }
        .frame(height: 14)
        .opacity(active ? 1 : 0.35)
        .onAppear { animating = true }
    }
}

/// Standalone volume row styled like the setting rows (for SFX).
private struct VolumeSliderRow: View {
    let symbol: String
    let symbolColors: [Color]
    let title: String
    @Binding var value: Double
    let enabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            SettingIconTile(symbol: symbol, colors: symbolColors)

            VStack(alignment: .leading, spacing: 6) {
                OutlinedText(text: title, size: 16)
                VolumeSlider(symbol: nil, value: $value, enabled: enabled, tint: GameTheme.gold)
            }
        }
        .padding(12)
        .background(settingRowBackground)
        .opacity(enabled ? 1 : 0.6)
    }
}

/// Chunky volume slider with a live percent readout.
private struct VolumeSlider: View {
    let symbol: String?
    @Binding var value: Double
    let enabled: Bool
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(tint)
                    .frame(width: 22)
            }

            Slider(value: $value, in: 0...1, step: 0.05)
                .tint(tint)
                .disabled(!enabled)

            OutlinedText(text: "\(Int((value * 100).rounded()))%", size: 14)
                .frame(width: 48, alignment: .trailing)
                .monospacedDigit()
        }
    }
}

/// Shared purple settings row background.
private var settingRowBackground: some View {
    RoundedRectangle(cornerRadius: 16)
        .fill(Color(red: 0.22, green: 0.12, blue: 0.44).opacity(0.94))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(red: 0.55, green: 0.40, blue: 0.85).opacity(0.55), lineWidth: 1.5)
        )
}

private struct SettingIconTile: View {
    let symbol: String
    let colors: [Color]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11)
                .fill(Color(red: 0.12, green: 0.06, blue: 0.28))
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1.5)
                )
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(
                    LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                )
        }
        .frame(width: 46, height: 46)
    }
}

private struct SettingToggleRow: View {
    let symbol: String
    let symbolColors: [Color]
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            SettingIconTile(symbol: symbol, colors: symbolColors)

            VStack(alignment: .leading, spacing: 2) {
                OutlinedText(text: title, size: 16)
                Text(subtitle)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.62, green: 0.70, blue: 0.95))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(red: 0.35, green: 0.75, blue: 0.20))
        }
        .padding(12)
        .background(settingRowBackground)
    }
}

private struct SettingLinkRow<Trailing: View>: View {
    let symbol: String
    let symbolColors: [Color]
    let title: String
    let subtitle: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            SettingIconTile(symbol: symbol, colors: symbolColors)

            VStack(alignment: .leading, spacing: 2) {
                OutlinedText(text: title, size: 16)
                Text(subtitle)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.62, green: 0.70, blue: 0.95))
            }

            Spacer()

            trailing
        }
        .padding(12)
        .background(settingRowBackground)
    }
}

private struct InfoSheetView: View {
    let title: String
    let message: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            GameTheme.bgDeep.ignoresSafeArea()

            VStack(spacing: 18) {
                OutlinedText(text: title.uppercased(), size: 24)
                    .padding(.top, 28)

                Text(message)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Button { dismiss() } label: {
                    OutlinedText(text: "GOT IT", size: 16)
                        .frame(width: 180)
                }
                .buttonStyle(ChunkyButtonStyle(palette: .green, height: 50, cornerRadius: 15))

                Spacer()
            }
        }
        .presentationDetents([.medium])
    }
}

/// Shared translucent panel background for meta screens.
var metaPanelBackground: some View {
    RoundedRectangle(cornerRadius: 18)
        .fill(Color(red: 0.20, green: 0.10, blue: 0.40).opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
}
