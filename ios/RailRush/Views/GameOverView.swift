import SwiftUI

/// Post-run results dialog in the arcade panel style: navy banner title over
/// a bright blue panel with an inset score well and chunky action buttons.
struct GameOverView: View {
    let state: GameState
    let onRunAgain: () -> Void
    let onHome: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack {
            Spacer()

            ZStack(alignment: .top) {
                GamePanel {
                    VStack(spacing: 16) {
                        Text(state.endReason.message)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                            .shadow(color: GameTheme.outline.opacity(0.6), radius: 0, y: 1)

                        if state.lastRunWasBest {
                            HStack(spacing: 6) {
                                AssetIcon(name: "crown_gems_sticker", size: 20, fallbackSymbol: "crown.fill")
                                Text("NEW BEST!")
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .foregroundStyle(GameTheme.outline)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: [GameTheme.gold, GameTheme.goldDeep],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                in: Capsule()
                            )
                            .overlay(Capsule().strokeBorder(.white.opacity(0.7), lineWidth: 1.5))
                            .scaleEffect(appeared ? 1 : 0.4)
                        }

                        PanelWell {
                            VStack(spacing: 2) {
                                Text("SCORE")
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .foregroundStyle(GameTheme.gold)
                                OutlinedText(text: "\(state.lastRunScore)", size: 52)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }

                        HStack(spacing: 12) {
                            StatWell(title: "RUN NOTES") {
                                HStack(spacing: 6) {
                                    MusicCoinIcon(size: 17)
                                    OutlinedText(text: "\(state.lastRunCoins)", size: 20)
                                }
                            }
                            StatWell(title: "BEST") {
                                HStack(spacing: 6) {
                                    AssetIcon(name: "trophy_cup_star", size: 19, fallbackSymbol: "trophy.fill")
                                    OutlinedText(text: "\(state.bestScore)", size: 20)
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            StatWell(title: "DISTANCE") {
                                HStack(spacing: 6) {
                                    AssetIcon(name: "racing_flag_checkered", size: 19, fallbackSymbol: "flag.checkered")
                                    OutlinedText(text: "\(state.lastRunDistance)m", size: 20)
                                }
                            }
                            StatWell(title: "BEST COMBO") {
                                HStack(spacing: 6) {
                                    AssetIcon(name: "gold_star_2x_multiplier", size: 19, fallbackSymbol: "flame.fill")
                                    OutlinedText(text: "x\(max(state.lastRunBestCombo, 1))", size: 20)
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            Button(action: onHome) {
                                HStack(spacing: 7) {
                                    AssetIcon(name: "cozy_house_icon", size: 24, fallbackSymbol: "house.fill")
                                        .shadow(color: GameTheme.outline.opacity(0.5), radius: 0, y: 1.5)
                                    OutlinedText(text: "HOME", size: 19)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(ChunkyButtonStyle(palette: .yellow, height: 58, cornerRadius: 18))

                            Button(action: onRunAgain) {
                                HStack(spacing: 7) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 17, weight: .black))
                                        .foregroundStyle(.white)
                                        .shadow(color: GameTheme.outline.opacity(0.9), radius: 0, y: 1.5)
                                    OutlinedText(text: "RUN AGAIN", size: 19)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(ChunkyButtonStyle(palette: .green, height: 58, cornerRadius: 18))
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 34)
                    .padding(.bottom, 20)
                }

                BannerTitle(text: "SO CLOSE!")
                    .offset(y: -24)
            }
            .padding(.horizontal, 24)
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.35)) {
                appeared = true
            }
        }
    }
}

/// Small labeled well used for run stats inside the results panel.
private struct StatWell<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        PanelWell {
            VStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                content
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
        }
    }
}
