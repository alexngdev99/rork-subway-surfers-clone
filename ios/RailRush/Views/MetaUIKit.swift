import SwiftUI

// MARK: - Asset-backed icon

/// Generated sticker icon from the asset catalog with an SF Symbol fallback.
struct AssetIcon: View {
    let name: String
    var size: CGFloat = 32
    var fallbackSymbol: String = "questionmark.circle.fill"

    var body: some View {
        if let image = UIImage(named: name) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: fallbackSymbol)
                .font(.system(size: size * 0.7, weight: .black))
                .foregroundStyle(GameTheme.gold)
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Counting number

/// Outlined number that rolls toward its target instead of jumping — with a
/// small pop and a gold flash while counting up. Used for wallet chips and
/// the in-run coin counter so collected rewards feel earned tick by tick.
struct CountingOutlinedText: View {
    let value: Int
    var size: CGFloat = 14
    var fill: AnyShapeStyle = AnyShapeStyle(.white)
    var formatter: (Int) -> String = { $0.formatted() }

    @State private var displayed: Int?
    @State private var isCountingUp = false
    @State private var pop = false

    var body: some View {
        OutlinedText(
            text: formatter(displayed ?? value),
            size: size,
            fill: isCountingUp
                ? AnyShapeStyle(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.88, blue: 0.35), GameTheme.goldDeep],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                : fill
        )
        .scaleEffect(pop ? 1.16 : 1.0)
        .task(id: value) { await roll(to: value) }
    }

    /// Eases the displayed number toward `target` over ~0.55s. `.task(id:)`
    /// cancels a running roll when a newer value arrives, so rapid pickups
    /// simply retarget mid-count from wherever the number currently is.
    private func roll(to target: Int) async {
        guard let start = displayed, start != target else {
            displayed = target
            return
        }
        isCountingUp = target > start
        withAnimation(.spring(duration: 0.22, bounce: 0.55)) { pop = true }

        let distance = abs(target - start)
        let steps = max(1, min(24, distance))
        let stepTime = 0.55 / Double(steps)
        for step in 1...steps {
            if Task.isCancelled { return }
            let t = Double(step) / Double(steps)
            let eased = 1 - pow(1 - t, 3)
            displayed = start + Int((Double(target - start) * eased).rounded())
            try? await Task.sleep(for: .seconds(stepTime))
        }
        if Task.isCancelled { return }
        displayed = target
        withAnimation(.spring(duration: 0.3)) { pop = false }
        isCountingUp = false
    }
}

// MARK: - Notification badge

/// Small red notification bubble pinned to a corner.
struct RedBadge: View {
    let count: Int

    var body: some View {
        if count > 0 {
            Text("\(min(count, 9))")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color(red: 0.88, green: 0.16, blue: 0.16), in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.85), lineWidth: 1.5))
                .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
        }
    }
}

// MARK: - Currency bar

/// Top-of-screen wallet strip: keys / notes / sprays with + buttons, the
/// season star, and the settings gear — shared by home and meta screens.
struct CurrencyBar: View {
    let meta: MetaState
    var showsSettings = true

    var body: some View {
        HStack(spacing: 7) {
            CurrencyChip(
                icon: { AssetIcon(name: "skeleton_key_blue", size: 20, fallbackSymbol: "key.fill") },
                value: meta.keys,
                onPlus: { meta.route = .store(.mystery) }
            )
            CurrencyChip(
                icon: { MusicCoinIcon(size: 18) },
                value: meta.notes,
                onPlus: { meta.route = .store(.coins) }
            )
            CurrencyChip(
                icon: { AssetIcon(name: "spray_can_lightning", size: 20, fallbackSymbol: "paintbrush.fill") },
                value: meta.sprays,
                onPlus: { meta.route = .store(.offers) }
            )

            Spacer(minLength: 4)

            HStack(spacing: 2) {
                OutlinedText(
                    text: "x\(meta.seasonLevel)",
                    size: 15,
                    fill: AnyShapeStyle(GameTheme.gold)
                )
                Image(systemName: "star.fill")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(GameTheme.gold)
                    .shadow(color: GameTheme.outline.opacity(0.8), radius: 0, y: 1.5)
            }

            if showsSettings {
                Button {
                    meta.route = .settings
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(.white.opacity(0.92))
                        .frame(width: 36, height: 36)
                        .background(GameTheme.chip, in: Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.2), lineWidth: 1.5))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }
}

/// One wallet chip with an icon, formatted amount, and a green + button.
private struct CurrencyChip<Icon: View>: View {
    @ViewBuilder let icon: Icon
    let value: Int
    let onPlus: () -> Void

    var body: some View {
        Button(action: onPlus) {
            HStack(spacing: 4) {
                icon
                CountingOutlinedText(value: value, size: 14, formatter: Self.compact)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.55, green: 0.85, blue: 0.25), Color(red: 0.27, green: 0.62, blue: 0.10)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white)
                }
                .frame(width: 17, height: 17)
            }
            .padding(.leading, 7)
            .padding(.trailing, 4)
            .padding(.vertical, 5)
            .background(GameTheme.chip, in: RoundedRectangle(cornerRadius: 11))
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .strokeBorder(.white.opacity(0.16), lineWidth: 1.5)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    /// 12,345 → "12,345"; 1,234,567 → "1.2M" to keep chips narrow.
    private static func compact(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        }
        return value.formatted()
    }
}

// MARK: - Reward label

/// Inline reward summary like "1,500 ♪  2 🔑" built from a bundle.
struct RewardLabel: View {
    let reward: RewardBundle
    var iconSize: CGFloat = 18
    var textSize: CGFloat = 17

    var body: some View {
        HStack(spacing: 8) {
            if reward.notes > 0 {
                HStack(spacing: 3) {
                    OutlinedText(text: reward.notes.formatted(), size: textSize)
                    MusicCoinIcon(size: iconSize)
                }
            }
            if reward.keys > 0 {
                HStack(spacing: 3) {
                    OutlinedText(text: "\(reward.keys)", size: textSize)
                    AssetIcon(name: "skeleton_key_blue", size: iconSize, fallbackSymbol: "key.fill")
                }
            }
            if reward.sprays > 0 {
                HStack(spacing: 3) {
                    OutlinedText(text: "\(reward.sprays)", size: textSize)
                    AssetIcon(name: "spray_can_lightning", size: iconSize, fallbackSymbol: "paintbrush.fill")
                }
            }
        }
    }
}

// MARK: - Meta screen scaffold

/// Full-screen graffiti-wall backdrop with a dark readability overlay —
/// the shared stage for missions / store / settings / characters screens.
struct MetaScreen<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            GameTheme.bgDeep.ignoresSafeArea()

            if let wall = UIImage(named: "graffiti_brick_wall_bg") {
                GeometryReader { proxy in
                    Image(uiImage: wall)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [
                                    GameTheme.bgDeep.opacity(0.55),
                                    GameTheme.bgDeep.opacity(0.72),
                                    GameTheme.bgDeep.opacity(0.9),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .ignoresSafeArea()
            }

            content
        }
    }
}

// MARK: - Bottom navigation

/// Global bottom tab bar shown on home and every meta screen.
enum NavTab: String, CaseIterable, Identifiable {
    case missions
    case me
    case home
    case store
    case events

    var id: String { rawValue }

    var label: String {
        switch self {
        case .missions: return "MISSIONS"
        case .me: return "ME"
        case .home: return "HOME"
        case .store: return "STORE"
        case .events: return "EVENTS"
        }
    }

    var symbol: String {
        switch self {
        case .missions: return "list.clipboard.fill"
        case .me: return "person.fill"
        case .home: return "house.fill"
        case .store: return "cart.fill"
        case .events: return "ticket.fill"
        }
    }

    var symbolColor: Color {
        switch self {
        case .missions: return Color(red: 0.95, green: 0.87, blue: 0.70)
        case .me: return Color(red: 0.45, green: 0.80, blue: 0.30)
        case .home: return GameTheme.gold
        case .store: return GameTheme.gold
        case .events: return GameTheme.gold
        }
    }
}

struct BottomNavBar: View {
    let active: NavTab
    let meta: MetaState
    let onSelect: (NavTab) -> Void

    var body: some View {
        HStack(spacing: 7) {
            ForEach(NavTab.allCases) { tab in
                NavTabButton(
                    tab: tab,
                    isActive: tab == active,
                    badge: badgeCount(for: tab),
                    action: { onSelect(tab) }
                )
            }
        }
        .padding(.horizontal, 10)
    }

    private func badgeCount(for tab: NavTab) -> Int {
        switch tab {
        case .missions: return meta.missionBadgeCount
        case .events: return meta.eventsBadgeCount
        case .me, .home, .store: return 0
        }
    }
}

private struct NavTabButton: View {
    let tab: NavTab
    let isActive: Bool
    let badge: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(tab.symbolColor)
                    .shadow(color: GameTheme.outline.opacity(0.8), radius: 0, y: 1.5)
                OutlinedText(text: tab.label, size: 10)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isActive
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
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isActive ? GameTheme.gold.opacity(0.9) : .white.opacity(0.14),
                        lineWidth: isActive ? 2.5 : 1.5
                    )
            )
            .overlay(alignment: .topTrailing) {
                RedBadge(count: badge)
                    .offset(x: 6, y: -6)
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Progress bar

/// Rounded progress bar with a centered "7/10"-style label, mockup colors.
struct MetaProgressBar: View {
    let progress: Int
    let target: Int
    var height: CGFloat = 22
    var fillColors: [Color] = [Color(red: 0.55, green: 0.85, blue: 0.25), Color(red: 0.30, green: 0.65, blue: 0.10)]

    var body: some View {
        GeometryReader { proxy in
            let fraction = target > 0 ? min(1, CGFloat(progress) / CGFloat(target)) : 0
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(red: 0.08, green: 0.03, blue: 0.18).opacity(0.9))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.12), lineWidth: 1.5))

                if fraction > 0 {
                    Capsule()
                        .fill(LinearGradient(colors: fillColors, startPoint: .top, endPoint: .bottom))
                        .frame(width: max(height, proxy.size.width * fraction))
                        .padding(3)
                }

                OutlinedText(text: "\(progress.formatted())/\(target.formatted())", size: height * 0.55)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Level pips

/// Seven-segment upgrade level bar (mockup 7 style yellow blocks).
struct LevelPipsBar: View {
    let level: Int
    var maxLevel: Int = UpgradeKind.maxLevel

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<maxLevel, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        index < level
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.85, blue: 0.30), GameTheme.goldDeep],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            : AnyShapeStyle(Color(red: 0.10, green: 0.06, blue: 0.24))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(.white.opacity(index < level ? 0.4 : 0.1), lineWidth: 1)
                    )
                    .frame(width: 18, height: 15)
            }
        }
    }
}

// MARK: - Section ribbon

/// Magenta banner ribbon like "COIN PACKS" / "SPECIAL OFFERS" in the mockups.
struct SectionRibbon: View {
    let text: String

    var body: some View {
        OutlinedText(text: text, size: 18)
            .padding(.horizontal, 30)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.85, green: 0.25, blue: 0.62), Color(red: 0.62, green: 0.12, blue: 0.48)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 9)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(.white.opacity(0.25), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.35), radius: 4, y: 3)
    }
}

// MARK: - Toast

/// Short floating notice ("Not enough keys!") that fades on its own.
struct ToastView: View {
    let text: String

    var body: some View {
        OutlinedText(text: text, size: 16)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(red: 0.80, green: 0.14, blue: 0.14).opacity(0.94), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
    }
}
