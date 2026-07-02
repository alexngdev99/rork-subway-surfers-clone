import SwiftUI

/// Root view: the 3D world stays mounted while overlays switch with the phase.
struct ContentView: View {
    @State private var gameState = GameState()
    @State private var world: RunnerWorld?

    var body: some View {
        ZStack {
            Color(red: 0.45, green: 0.78, blue: 0.92)
                .ignoresSafeArea()

            if let world {
                GameView(world: world)

                switch gameState.phase {
                case .home:
                    HomeView(state: gameState) {
                        world.startRun()
                    }
                    .transition(.opacity)
                case .running:
                    HUDView(state: gameState) {
                        world.togglePause()
                    }
                    if gameState.isPaused {
                        PauseOverlay(
                            onResume: { world.togglePause() },
                            onHome: { world.returnHome() }
                        )
                        .transition(.opacity)
                    }
                case .gameOver:
                    GameOverView(
                        state: gameState,
                        onRunAgain: { world.startRun() },
                        onHome: { world.returnHome() }
                    )
                    .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gameState.phase)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear {
            if world == nil {
                world = RunnerWorld(state: gameState)
            }
        }
    }
}

/// Dimmed pause menu shown over the frozen run.
private struct PauseOverlay: View {
    let onResume: () -> Void
    let onHome: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 16) {
                Text("PAUSED")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Button(action: onResume) {
                    Text("RESUME")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.1, green: 0.85, blue: 0.8), Color(red: 0.0, green: 0.6, blue: 0.65)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: RoundedRectangle(cornerRadius: 18)
                        )
                }
                .buttonStyle(PressableButtonStyle())

                Button(action: onHome) {
                    Text("Quit Run")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(26)
            .frame(maxWidth: 320)
        }
    }
}

#Preview {
    ContentView()
}
