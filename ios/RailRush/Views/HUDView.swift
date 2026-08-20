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
                            Image(systemName: "star.fill")
                                .font(.system(size: 17, weight: .black))
                                .foregroundStyle(GameTheme.gold)
                                .shadow(color: GameTheme.outline.opacity(0.8), radius: 0, y: 1.5)
                            OutlinedText(text: Self.paddedScore(state.score), size: 30)
                                .animation(.snappy(duration: 0.2), value: state.score)
                        }

                        HUDChip {
                            OutlinedText(text: "\(state.coins)", size: 18)
                                .animation(.snappy(duration: 0.2), value: state.coins)
                            MusicCoinIcon(size: 18)
                        }
                    }
                }
                .padding(.horizontal, 16)

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

private struct PowerUpBadge: View {
    let type: PowerUpType
    let progress: Double

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.symbolName)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white)
                .shadow(color: GameTheme.outline.opacity(0.8), radius: 0, y: 1.5)
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
