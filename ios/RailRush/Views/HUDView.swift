import SwiftUI

/// In-run overlay (mockup 3): pause top-left, multiplier star + score and the
/// note counter top-right, power-up badge, spray boost meter bottom-left, and
/// the Paint Rush full-screen glow.
struct HUDView: View {
    let state: GameState
    let onPause: () -> Void

    var body: some View {
        ZStack {
            // Paint Rush: neon paint glow hugging the screen edges.
            if state.paintRushActive {
                PaintRushOverlay()
                    .transition(.opacity)
            }

            VStack(spacing: 0) {
                // Distance progress toward the next 500m milestone.
                RunDistanceBar(distance: state.distanceRun)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                HStack(alignment: .top) {
                    Button(action: onPause) {
                        Image(systemName: state.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(.white)
                            .shadow(color: GameTheme.outline.opacity(0.9), radius: 0, y: 2)
                    }
                    .buttonStyle(ChunkyButtonStyle(palette: .magenta, height: 48, cornerRadius: 14))
                    .frame(width: 48)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 7) {
                        // "x30 ⭐ 012345" score row like the mockup.
                        HStack(spacing: 6) {
                            OutlinedText(
                                text: "x\(state.multiplier)",
                                size: 20,
                                fill: AnyShapeStyle(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.88, blue: 0.35), GameTheme.goldDeep],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            )
                            AssetIcon(name: "star_sparkle_3d", size: 21, fallbackSymbol: "star.fill")
                                .shadow(color: GameTheme.outline.opacity(0.5), radius: 0, y: 1.5)
                            OutlinedText(text: Self.paddedScore(state.score), size: 30)
                                .animation(.snappy(duration: 0.2), value: state.score)
                        }

                        HUDChip {
                            CountingOutlinedText(value: state.coins, size: 18, formatter: { "\($0)" })
                            MusicCoinIcon(size: 18)
                        }
                    }
                }
                .padding(.horizontal, 16)

                if state.comboCount >= 3 {
                    ComboBanner(count: state.comboCount, progress: state.comboProgress)
                        .padding(.top, 10)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                }

                if let powerUp = state.activePowerUp {
                    PowerUpBadge(type: powerUp, progress: state.powerUpProgress)
                        .padding(.top, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if state.inspectorClose {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(GameTheme.gold)
                        OutlinedText(text: "Inspector is right behind you!", size: 14)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.80, green: 0.14, blue: 0.14).opacity(0.92), in: Capsule())
                    .overlay(Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1.5))
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                // Bottom-left spray boost meter.
                HStack {
                    SprayMeter(
                        filled: state.sprayMeter,
                        rushActive: state.paintRushActive,
                        rushProgress: state.paintRushProgress
                    )
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
        .animation(.spring(duration: 0.35), value: state.activePowerUp)
        .animation(.spring(duration: 0.35), value: state.inspectorClose)
        .animation(.spring(duration: 0.3, bounce: 0.45), value: state.comboCount >= 3)
        .animation(.spring(duration: 0.3), value: state.multiplier)
        .animation(.spring(duration: 0.3), value: state.paintRushActive)
    }

    private static func paddedScore(_ score: Int) -> String {
        String(format: "%06d", min(score, 999999))
    }
}

/// Spray icon + 8-segment charge bar (mockup 3 bottom-left). While Paint Rush
/// is active the bar becomes a draining rainbow timer.
private struct SprayMeter: View {
    let filled: Int
    let rushActive: Bool
    let rushProgress: Double

    var body: some View {
        HStack(spacing: 8) {
            AssetIcon(name: "spray_can_lightning", size: 34, fallbackSymbol: "paintbrush.fill")
                .shadow(color: rushActive ? GameTheme.magenta.opacity(0.9) : .clear, radius: 8)

            HStack(spacing: 3) {
                ForEach(0..<GameState.sprayMeterMax, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(segmentStyle(index: index))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(.white.opacity(isLit(index) ? 0.5 : 0.12), lineWidth: 1)
                        )
                        .frame(width: 13, height: 20)
                }
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(GameTheme.chip, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    rushActive ? GameTheme.magenta.opacity(0.9) : .white.opacity(0.16),
                    lineWidth: rushActive ? 2.5 : 1.5
                )
        )
        .animation(.snappy(duration: 0.2), value: filled)
    }

    private func isLit(_ index: Int) -> Bool {
        if rushActive {
            return Double(index) < rushProgress * Double(GameState.sprayMeterMax)
        }
        return index < filled
    }

    private func segmentStyle(index: Int) -> AnyShapeStyle {
        guard isLit(index) else {
            return AnyShapeStyle(Color(red: 0.10, green: 0.05, blue: 0.24))
        }
        if rushActive {
            let rainbow: [Color] = [GameTheme.magenta, Color(red: 0.72, green: 0.35, blue: 0.98), GameTheme.teal, GameTheme.gold]
            return AnyShapeStyle(rainbow[index % rainbow.count])
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.85, blue: 0.30), GameTheme.goldDeep],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

/// Neon paint vignette + PAINT RUSH! callout while invincible.
private struct PaintRushOverlay: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .strokeBorder(
                    AngularGradient(
                        colors: [GameTheme.magenta, Color(red: 0.72, green: 0.35, blue: 0.98), GameTheme.teal, GameTheme.gold, GameTheme.magenta],
                        center: .center
                    ),
                    lineWidth: pulse ? 14 : 8
                )
                .blur(radius: 12)
                .opacity(0.85)
                .ignoresSafeArea()

            VStack {
                Spacer()
                OutlinedText(
                    text: "PAINT RUSH!",
                    size: 26,
                    fill: AnyShapeStyle(
                        LinearGradient(
                            colors: [GameTheme.magenta, Color(red: 0.72, green: 0.35, blue: 0.98)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    ),
                    outline: .white.opacity(0.9)
                )
                .shadow(color: GameTheme.magenta.opacity(0.9), radius: pulse ? 16 : 8)
                .scaleEffect(pulse ? 1.06 : 0.97)
                .padding(.bottom, 64)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

/// Slim top-of-screen distance tracker: fills toward the next 500m milestone
/// with a sneaker marker riding the fill edge and a checkered flag that pops
/// (plus a haptic thump) every time a milestone is crossed.
private struct RunDistanceBar: View {
    let distance: Int

    @State private var flagPop = false

    private static let segmentLength = 500

    private var milestoneIndex: Int { distance / Self.segmentLength }
    private var nextMilestone: Int { (milestoneIndex + 1) * Self.segmentLength }
    private var progress: Double {
        Double(distance % Self.segmentLength) / Double(Self.segmentLength)
    }

    var body: some View {
        HStack(spacing: 8) {
            OutlinedText(text: "\(distance)m", size: 13)
                .frame(minWidth: 52, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.38))
                        .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [GameTheme.teal, Color(red: 1.0, green: 0.88, blue: 0.35)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * progress))

                    // Sneaker marker riding the fill edge.
                    AssetIcon(name: "red_white_sneaker_lightning", size: 20, fallbackSymbol: "figure.run")
                        .shadow(color: GameTheme.outline.opacity(0.6), radius: 0, y: 1)
                        .offset(x: min(max(0, geo.size.width * progress - 10), geo.size.width - 20), y: -6)
                }
            }
            .frame(height: 8)

            HStack(spacing: 4) {
                AssetIcon(name: "racing_flag_checkered", size: 19, fallbackSymbol: "flag.checkered")
                    .scaleEffect(flagPop ? 1.45 : 1.0)
                    .rotationEffect(.degrees(flagPop ? -12 : 0))
                OutlinedText(text: Self.milestoneLabel(nextMilestone), size: 12)
            }
        }
        .allowsHitTesting(false)
        .animation(.linear(duration: 0.1), value: progress)
        .onChange(of: milestoneIndex) { oldValue, newValue in
            guard newValue > oldValue else { return }
            HapticsService.shared.powerUp()
            flagPop = true
            withAnimation(.spring(duration: 0.45, bounce: 0.6).delay(0.05)) {
                flagPop = false
            }
        }
    }

    /// "1K", "1.5K" past 1000m; plain meters below that.
    private static func milestoneLabel(_ meters: Int) -> String {
        guard meters >= 1000 else { return "\(meters)m" }
        let km = Double(meters) / 1000
        return km.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(km))K"
            : String(format: "%.1fK", km)
    }
}

/// Escalating "COMBO xN" callout for consecutive note pickups — pops on every
/// pickup, climbs through color tiers, and drains a thin timer bar underneath.
private struct ComboBanner: View {
    let count: Int
    let progress: Double

    @State private var pop = false
    @State private var glowPulse = false

    private enum Tier {
        case nice, great, awesome, onFire

        init(count: Int) {
            switch count {
            case ..<10: self = .nice
            case ..<20: self = .great
            case ..<30: self = .awesome
            default: self = .onFire
            }
        }

        var label: String? {
            switch self {
            case .nice: return nil
            case .great: return "GREAT!"
            case .awesome: return "AWESOME!"
            case .onFire: return "ON FIRE!"
            }
        }

        var colors: [Color] {
            switch self {
            case .nice: return [Color(red: 1.0, green: 0.88, blue: 0.35), GameTheme.goldDeep]
            case .great: return [GameTheme.teal, Color(red: 0.05, green: 0.55, blue: 0.52)]
            case .awesome: return [GameTheme.magenta, Color(red: 0.72, green: 0.35, blue: 0.98)]
            case .onFire: return [Color(red: 1.0, green: 0.55, blue: 0.15), GameTheme.magenta]
            }
        }

        var glow: Color {
            switch self {
            case .nice: return GameTheme.gold
            case .great: return GameTheme.teal
            case .awesome: return GameTheme.magenta
            case .onFire: return Color(red: 1.0, green: 0.45, blue: 0.1)
            }
        }
    }

    private var tier: Tier { Tier(count: count) }

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 7) {
                MusicCoinIcon(size: 22)
                    .rotationEffect(.degrees(pop ? -14 : 0))

                OutlinedText(
                    text: "COMBO x\(count)",
                    size: 22,
                    fill: AnyShapeStyle(
                        LinearGradient(colors: tier.colors, startPoint: .top, endPoint: .bottom)
                    )
                )

                if let label = tier.label {
                    OutlinedText(
                        text: label,
                        size: 15,
                        fill: AnyShapeStyle(Color.white)
                    )
                    .rotationEffect(.degrees(pop ? 6 : -2))
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
                }
            }
            .scaleEffect(pop ? 1.22 : 1.0)

            // Combo window drain bar — grab the next note before it empties!
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.4))
                    Capsule()
                        .fill(
                            LinearGradient(colors: tier.colors, startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: max(6, geo.size.width * progress))
                }
            }
            .frame(width: 130, height: 5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(GameTheme.chip.opacity(0.85), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(tier.glow.opacity(tier == .onFire ? 0.95 : 0.55), lineWidth: tier == .onFire ? 2.5 : 1.5)
        )
        .shadow(
            color: tier.glow.opacity(tier == .onFire ? (glowPulse ? 0.95 : 0.5) : 0.35),
            radius: tier == .onFire ? (glowPulse ? 18 : 9) : 8
        )
        .allowsHitTesting(false)
        .animation(.spring(duration: 0.25, bounce: 0.4), value: count)
        .onChange(of: count) { _, _ in
            pop = true
            withAnimation(.spring(duration: 0.28, bounce: 0.55).delay(0.06)) {
                pop = false
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

private struct PowerUpBadge: View {
    let type: PowerUpType
    let progress: Double

    var body: some View {
        HStack(spacing: 8) {
            AssetIcon(name: type.iconAssetName, size: 22, fallbackSymbol: type.symbolName)
                .shadow(color: GameTheme.outline.opacity(0.5), radius: 0, y: 1.5)
            OutlinedText(text: type.displayName, size: 14)
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.white)
                .frame(width: 70)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(badgeColor.opacity(0.92), in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1.5))
    }

    private var badgeColor: Color {
        switch type {
        case .magnet: return Color(red: 0.06, green: 0.62, blue: 0.58)
        case .doubleScore: return Color(red: 0.55, green: 0.24, blue: 0.85)
        case .superJump: return Color(red: 0.88, green: 0.62, blue: 0.02)
        case .jetpack: return Color(red: 0.95, green: 0.45, blue: 0.08)
        }
    }
}
