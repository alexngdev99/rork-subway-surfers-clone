import SwiftUI

/// Home hub overlay (mockup 1): currency bar, side menu buttons, glowing
/// TAP TO PLAY, the season card, and the global bottom navigation. The live
/// 3D scene with the selected runner stays visible behind everything.
struct HomeView: View {
    let state: GameState
    let onRun: () -> Void

    @State private var pulse = false

    private var meta: MetaState { state.meta }

    var body: some View {
        VStack(spacing: 0) {
            CurrencyBar(meta: meta)
                .padding(.horizontal, 14)
                .padding(.top, 6)

            GameLogo(size: 46)
                .padding(.top, 12)

            // Middle band: side buttons + big tap-to-play area.
            HStack(alignment: .top, spacing: 0) {
                VStack(spacing: 12) {
                    SideMenuButton(
                        iconAsset: "gift_box_coins_bow",
                        fallbackSymbol: "gift.fill",
                        label: "FREE\nREWARDS!",
                        badge: meta.freeRewardReady ? 1 : 0
                    ) {
                        meta.route = .freeRewards
                    }
                    SideMenuButton(
                        iconAsset: "calendar_checkmark",
                        fallbackSymbol: "calendar",
                        label: "DAILY\nLOGIN",
                        badge: meta.dailyLoginReady ? 1 : 0
                    ) {
                        meta.route = .dailyLogin
                    }
                    SideMenuButton(
                        iconAsset: "duffel_bag_paint_splashes",
                        fallbackSymbol: "cart.fill",
                        label: "SHOP",
                        badge: 0
                    ) {
                        meta.route = .store(.offers)
                    }
                }
                .padding(.leading, 12)

                // Big invisible tap surface over the 3D runner.
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onRun)

                VStack(spacing: 12) {
                    SideMenuButton(
                        iconAsset: "trophy_cup_star",
                        fallbackSymbol: "trophy.fill",
                        label: "EVENTS",
                        badge: meta.eventsBadgeCount
                    ) {
                        meta.route = .events
                    }
                    SideMenuButton(
                        iconAsset: nil,
                        avatarAsset: GeneratedAssets.character(withID: state.selectedCharacterID).avatarImageName,
                        fallbackSymbol: "person.fill",
                        label: "CREW",
                        badge: 0
                    ) {
                        meta.route = .characters
                    }
                }
                .padding(.trailing, 12)
            }
            .frame(maxHeight: .infinity)

            // Glowing TAP TO PLAY — also tappable.
            Button(action: onRun) {
                OutlinedText(
                    text: "TAP TO PLAY",
                    size: 38,
                    fill: AnyShapeStyle(.white),
                    outline: Color(red: 0.45, green: 0.15, blue: 0.85)
                )
                .shadow(color: Color(red: 0.65, green: 0.30, blue: 1.0).opacity(0.9), radius: pulse ? 18 : 8)
                .shadow(color: GameTheme.magenta.opacity(0.55), radius: pulse ? 26 : 12)
                .scaleEffect(pulse ? 1.04 : 0.98)
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.bottom, 12)

            seasonCard
                .padding(.horizontal, 14)
                .padding(.bottom, 10)

            BottomNavBar(active: .home, meta: meta) { tab in
                meta.route = tab.route
            }
            .padding(.bottom, 4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
            meta.refreshTimedContent()
            // Auto-open the login sheet once per session on a new day.
            if meta.dailyLoginReady && !meta.didAutoShowLogin {
                meta.didAutoShowLogin = true
                Task {
                    try? await Task.sleep(for: .milliseconds(650))
                    if meta.route == nil { meta.route = .dailyLogin }
                }
            }
        }
    }

    /// "SEASON 1 — FESTIVAL VIBES" strip with the season progress bar.
    private var seasonCard: some View {
        Button {
            meta.route = .missions
        } label: {
            HStack(spacing: 10) {
                AssetIcon(name: "gold_sun_medal_s", size: 46, fallbackSymbol: "seal.fill")

                VStack(alignment: .leading, spacing: 1) {
                    Text("SEASON \(meta.seasonLevel)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.72, green: 0.60, blue: 0.95))
                    OutlinedText(text: "FESTIVAL", size: 14)
                    OutlinedText(text: "VIBES", size: 14)
                }

                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.35, green: 0.55, blue: 0.95), Color(red: 0.20, green: 0.35, blue: 0.75)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: RoundedRectangle(cornerRadius: 7)
                        )
                    MetaProgressBar(
                        progress: meta.seasonPoints,
                        target: MetaState.seasonTarget,
                        height: 19,
                        fillColors: [Color(red: 1.0, green: 0.82, blue: 0.25), GameTheme.goldDeep]
                    )
                }
                .frame(maxWidth: .infinity)

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
                    OutlinedText(text: "\(meta.seasonLevel)", size: 16)
                }
                .frame(width: 36, height: 40)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.22, green: 0.13, blue: 0.44).opacity(0.94))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1.5)
                    )
            )
            .overlay(alignment: .topTrailing) {
                RedBadge(count: meta.missionBadgeCount)
                    .offset(x: 5, y: -5)
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Square side-menu button (mockup 1 left column): icon sticker, tiny label,
/// and an optional red notification badge.
private struct SideMenuButton: View {
    var iconAsset: String?
    var avatarAsset: String?
    let fallbackSymbol: String
    let label: String
    let badge: Int
    let action: () -> Void

    init(
        iconAsset: String?,
        avatarAsset: String? = nil,
        fallbackSymbol: String,
        label: String,
        badge: Int,
        action: @escaping () -> Void
    ) {
        self.iconAsset = iconAsset
        self.avatarAsset = avatarAsset
        self.fallbackSymbol = fallbackSymbol
        self.label = label
        self.badge = badge
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if let avatarAsset, let image = UIImage(named: avatarAsset) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 42, height: 42)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(GameTheme.gold.opacity(0.8), lineWidth: 2))
                } else if let iconAsset {
                    AssetIcon(name: iconAsset, size: 42, fallbackSymbol: fallbackSymbol)
                } else {
                    Image(systemName: fallbackSymbol)
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(GameTheme.gold)
                }

                OutlinedText(text: label, size: 9)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 76, height: 82)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(red: 0.24, green: 0.15, blue: 0.48).opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .strokeBorder(Color(red: 0.58, green: 0.44, blue: 0.90).opacity(0.6), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 5, y: 3)
            )
            .overlay(alignment: .topTrailing) {
                RedBadge(count: badge)
                    .offset(x: 6, y: -6)
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}
