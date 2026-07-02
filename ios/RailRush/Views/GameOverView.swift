import SwiftUI

/// Post-run results overlay with restart and home actions.
struct GameOverView: View {
    let state: GameState
    let onRunAgain: () -> Void
    let onHome: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 18) {
                Text(state.endReason.message)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                if state.lastRunWasBest {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                        Text("NEW BEST!")
                    }
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(red: 1.0, green: 0.78, blue: 0.1), in: Capsule())
                    .scaleEffect(appeared ? 1 : 0.4)
                }

                Text("\(state.lastRunScore)")
                    .font(.system(size: 62, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 4, y: 2)

                HStack(spacing: 14) {
                    StatChip(
                        icon: "circle.circle.fill",
                        iconColor: Color(red: 1.0, green: 0.82, blue: 0.1),
                        label: "Run Coins",
                        value: "\(state.lastRunCoins)"
                    )
                    StatChip(
                        icon: "trophy.fill",
                        iconColor: Color(red: 1.0, green: 0.75, blue: 0.1),
                        label: "Best",
                        value: "\(state.bestScore)"
                    )
                }

                VStack(spacing: 12) {
                    Button(action: onRunAgain) {
                        Text("RUN AGAIN")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 62)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.55, blue: 0.1), Color(red: 0.95, green: 0.35, blue: 0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                in: RoundedRectangle(cornerRadius: 20)
                            )
                    }
                    .buttonStyle(PressableButtonStyle())

                    Button(action: onHome) {
                        Text("Home")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .padding(.top, 6)
            }
            .padding(26)
            .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 30))
            .padding(.horizontal, 26)
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
