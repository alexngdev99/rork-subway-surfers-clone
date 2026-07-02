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
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(.black.opacity(0.35), in: Circle())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(state.score)")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.2), value: state.score)

                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.82, blue: 0.1))
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(.orange, lineWidth: 2))
                        Text("\(state.coins)")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.snappy(duration: 0.2), value: state.coins)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.35), in: Capsule())

                    if state.multiplier > 1 {
                        Text("x\(state.multiplier)")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(Color(red: 1.0, green: 0.75, blue: 0.1), in: Capsule())
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
                    Text("Inspector is right behind you!")
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(red: 0.85, green: 0.15, blue: 0.15).opacity(0.9), in: Capsule())
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
                .font(.system(size: 14, weight: .bold))
            Text(type.displayName)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.white)
                .frame(width: 70)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(badgeColor.opacity(0.9), in: Capsule())
    }

    private var badgeColor: Color {
        switch type {
        case .magnet: return Color(red: 0.2, green: 0.55, blue: 1.0)
        case .doubleScore: return Color(red: 0.9, green: 0.6, blue: 0.05)
        case .jetpack: return Color(red: 0.95, green: 0.35, blue: 0.1)
        }
    }
}
