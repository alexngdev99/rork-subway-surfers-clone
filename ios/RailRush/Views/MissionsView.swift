import SwiftUI

/// Season Hunt screen (mockup 4): graffiti logo, season countdown, season
/// progress panel, DAILY / SEASON mission lists with claimable rewards, and
/// the "complete all missions" chest banner.
struct MissionsView: View {
    let meta: MetaState

    @State private var tab: MissionTab = .season

    enum MissionTab: String, CaseIterable, Identifiable {
        case daily
        case season

        var id: String { rawValue }
        var label: String { self == .daily ? "DAILY" : "SEASON" }
        var symbol: String { self == .daily ? "checklist" : "sun.max.fill" }
    }

    private var missions: [Mission] {
        tab == .daily ? meta.dailyMissions : meta.seasonMissions
    }

    var body: some View {
        MetaScreen {
            VStack(spacing: 0) {
                CurrencyBar(meta: meta)
                    .padding(.horizontal, 14)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerLogo

                        countdownChip

                        seasonProgressPanel

                        tabPicker

                        ForEach(missions) { mission in
                            MissionRow(mission: mission) {
                                withAnimation(.spring(duration: 0.35)) {
                                    meta.claimMission(mission)
                                }
                            }
                        }

                        chestBanner
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }

                BottomNavBar(active: .missions, meta: meta) { tab in
                    meta.route = tab.route
                }
                .padding(.bottom, 4)
            }
        }
    }

    private var headerLogo: some View {
        Group {
            if let logo = UIImage(named: "season_hunt_graffiti_logo") {
                Image(uiImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 118)
            } else {
                VStack(spacing: 0) {
                    OutlinedText(text: "SEASON", size: 40, fill: AnyShapeStyle(GameTheme.gold))
                    OutlinedText(text: "HUNT", size: 34)
                }
            }
        }
    }

    private var countdownChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "stopwatch.fill")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(GameTheme.gold)
            OutlinedText(text: Self.countdownText(to: meta.seasonEnd), size: 15)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .background(GameTheme.chip, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1.5))
    }

    private var seasonProgressPanel: some View {
        HStack(spacing: 12) {
            AssetIcon(name: "gold_sun_medal_s", size: 62, fallbackSymbol: "seal.fill")

            VStack(alignment: .leading, spacing: 6) {
                OutlinedText(text: "SEASON PROGRESS", size: 15)
                MetaProgressBar(
                    progress: meta.seasonPoints,
                    target: MetaState.seasonTarget,
                    fillColors: [Color(red: 1.0, green: 0.82, blue: 0.25), GameTheme.goldDeep]
                )
                Text("Complete missions to earn Season Points")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(GameTheme.gold)
            }

            ZStack {
                HexagonShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.62, green: 0.36, blue: 0.92), Color(red: 0.38, green: 0.16, blue: 0.66)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                HexagonShape()
                    .stroke(.white.opacity(0.35), lineWidth: 2)
                OutlinedText(text: "\(meta.seasonLevel)", size: 20)
            }
            .frame(width: 46, height: 50)
        }
        .padding(14)
        .background(panelBackground)
    }

    private var tabPicker: some View {
        HStack(spacing: 8) {
            ForEach(MissionTab.allCases) { item in
                Button {
                    withAnimation(.spring(duration: 0.3)) { tab = item }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(item == tab ? GameTheme.gold : .white.opacity(0.6))
                        OutlinedText(text: item.label, size: 15)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                item == tab
                                    ? AnyShapeStyle(
                                        LinearGradient(
                                            colors: [Color(red: 0.30, green: 0.52, blue: 0.95), Color(red: 0.16, green: 0.30, blue: 0.72)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    : AnyShapeStyle(GameTheme.chip)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                item == tab ? GameTheme.gold.opacity(0.9) : .white.opacity(0.14),
                                lineWidth: item == tab ? 2 : 1.5
                            )
                    )
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    private var chestBanner: some View {
        HStack(spacing: 12) {
            AssetIcon(name: "spray_can_lightning", size: 52, fallbackSymbol: "paintbrush.fill")

            VStack(spacing: 3) {
                OutlinedText(text: "COMPLETE ALL MISSIONS", size: 14)
                Text("TO UNLOCK SEASON REWARD!")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(GameTheme.gold)

                if meta.seasonChestReady {
                    Button {
                        withAnimation(.spring(duration: 0.4)) {
                            meta.claimSeasonChest()
                        }
                    } label: {
                        OutlinedText(text: "OPEN CHEST!", size: 15)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ChunkyButtonStyle(palette: .green, height: 40, cornerRadius: 12))
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)

            AssetIcon(name: "mystery_cube_box_coins", size: 58, fallbackSymbol: "shippingbox.fill")
                .shadow(color: GameTheme.magenta.opacity(meta.seasonChestReady ? 0.8 : 0.3), radius: 10)
        }
        .padding(14)
        .background(panelBackground)
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color(red: 0.20, green: 0.10, blue: 0.40).opacity(0.92))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
    }

    private static func countdownText(to date: Date) -> String {
        let remaining = max(0, date.timeIntervalSinceNow)
        let days = Int(remaining) / 86400
        let hours = (Int(remaining) % 86400) / 3600
        return "\(days)d \(hours)h"
    }
}

/// One mission card: icon, title, progress bar, and reward / claim button.
private struct MissionRow: View {
    let mission: Mission
    let onClaim: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            missionIcon
                .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 6) {
                OutlinedText(text: mission.title, size: 14)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                MetaProgressBar(progress: min(mission.progress, mission.target), target: mission.target, height: 19)
            }

            Divider()
                .frame(width: 1, height: 44)
                .overlay(.white.opacity(0.15))

            VStack(spacing: 3) {
                if mission.claimed {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(Color(red: 0.45, green: 0.82, blue: 0.28))
                    OutlinedText(text: "DONE", size: 11)
                } else if mission.canClaim {
                    Button(action: onClaim) {
                        OutlinedText(text: "CLAIM", size: 14)
                            .frame(width: 74)
                    }
                    .buttonStyle(ChunkyButtonStyle(palette: .green, height: 36, cornerRadius: 11))
                } else {
                    Text("REWARD")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.72, green: 0.58, blue: 0.95))
                    RewardLabel(reward: mission.reward, iconSize: 15, textSize: 15)
                }
            }
            .frame(width: 84)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.20, green: 0.10, blue: 0.40).opacity(mission.claimed ? 0.55 : 0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            mission.canClaim ? GameTheme.gold.opacity(0.8) : .white.opacity(0.15),
                            lineWidth: mission.canClaim ? 2 : 1.5
                        )
                )
        )
        .opacity(mission.claimed ? 0.75 : 1)
    }

    @ViewBuilder
    private var missionIcon: some View {
        switch mission.kind {
        case .collectNotes:
            AssetIcon(name: "gold_coins_pile", size: 44, fallbackSymbol: "music.note")
        case .collectSprays:
            AssetIcon(name: "spray_can_lightning", size: 44, fallbackSymbol: "paintbrush.fill")
        case .jumpTimes:
            symbolIcon("figure.jumprope")
        case .slideTimes:
            symbolIcon("figure.skiing.downhill")
        case .scoreSingleRun:
            symbolIcon("star.circle.fill")
        case .completeRuns:
            symbolIcon("flag.checkered")
        case .usePowerUps:
            symbolIcon("bolt.circle.fill")
        }
    }

    private func symbolIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 24, weight: .black))
            .foregroundStyle(Color(red: 0.55, green: 0.75, blue: 1.0))
            .shadow(color: GameTheme.outline.opacity(0.8), radius: 0, y: 1.5)
    }
}

/// Flat-top hexagon used for the season level badge.
struct HexagonShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        var path = Path()
        path.move(to: CGPoint(x: width * 0.5, y: 0))
        path.addLine(to: CGPoint(x: width, y: height * 0.25))
        path.addLine(to: CGPoint(x: width, y: height * 0.75))
        path.addLine(to: CGPoint(x: width * 0.5, y: height))
        path.addLine(to: CGPoint(x: 0, y: height * 0.75))
        path.addLine(to: CGPoint(x: 0, y: height * 0.25))
        path.closeSubpath()
        return path
    }
}

extension NavTab {
    /// Maps a bottom-nav tab to its meta route (nil = home).
    var route: MetaRoute? {
        switch self {
        case .missions: return .missions
        case .me: return .me
        case .home: return nil
        case .store: return .store(.offers)
        case .events: return .events
        }
    }
}
