import SwiftUI

/// In-run overlay: score, coins, pause, power-up status, and inspector warning.
struct HUDView: View {
    let state: GameState
    let onPause: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Button(action: onPause) {
                    Image(systemName: state.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white)
                        .shadow(color: GameTheme.outline.opacity(0.9), radius: 0, y: 2)
                        .frame(width: 56)
                }
                .buttonStyle(ChunkyButtonStyle(palette: .blue, height: 46, cornerRadius: 14))

                Spacer()

                VStack(alignment: .trailing, spacing: 7) {
                    OutlinedText(text: "\(state.score)", size: 36)
                        .animation(.snappy(duration: 0.2), value: state.score)

                    HUDChip {
                        GoldCoinIcon(size: 18)
                        OutlinedText(text: "\(state.coins)", size: 18)
                            .animation(.snappy(duration: 0.2), value: state.coins)
                    }

                    if state.multiplier > 1 {
                        OutlinedText(
                            text: "x\(state.multiplier)",
                            size: 16,
                            fill: AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.88, blue: 0.35), GameTheme.goldDeep],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        )
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(GameTheme.chip, in: Capsule())
                        .overlay(Capsule().strokeBorder(GameTheme.gold.opacity(0.7), lineWidth: 1.5))
                        .transition(.scale.combined(with: .opacity))
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
        }
        .animation(.spring(duration: 0.35), value: state.activePowerUp)
        .animation(.spring(duration: 0.35), value: state.inspectorClose)
        .animation(.spring(duration: 0.3), value: state.multiplier)
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
        case .magnet: return Color(red: 0.2, green: 0.55, blue: 1.0)
        case .doubleScore: return Color(red: 0.9, green: 0.6, blue: 0.05)
        case .jetpack: return Color(red: 0.95, green: 0.35, blue: 0.1)
        }
    }
}
