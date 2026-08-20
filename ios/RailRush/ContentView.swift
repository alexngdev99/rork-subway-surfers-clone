import SwiftUI

/// Root view: the 3D world stays mounted while overlays switch with the phase.
struct ContentView: View {
    @State private var gameState = GameState()
    @State private var world: RunnerWorld?

    var body: some View {
        ZStack {
            GameTheme.bgDeep
                .ignoresSafeArea()

            if let world {
                GameView(world: world)

                switch gameState.phase {
                case .loading:
                    EmptyView()
                case .home:
                    HomeView(
                        state: gameState,
                        onSelectCharacter: { world.selectCharacter($0) },
                        onRun: { world.startRun() }
                    )
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

            // Opaque splash covers the scene until every 3D model is preloaded,
            // so the player never sees a half-built white world.
            if gameState.phase == .loading {
                LoadingView(progress: gameState.loadingProgress)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: gameState.phase)
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

            ZStack(alignment: .top) {
                GamePanel {
                    VStack(spacing: 12) {
                        Button(action: onResume) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundStyle(.white)
                                    .shadow(color: GameTheme.outline.opacity(0.9), radius: 0, y: 1.5)
                                OutlinedText(text: "RESUME", size: 22)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ChunkyButtonStyle(palette: .green, height: 60, cornerRadius: 18))

                        Button(action: onHome) {
                            OutlinedText(text: "QUIT RUN", size: 17)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ChunkyButtonStyle(palette: .slate, height: 50, cornerRadius: 16))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                }

                BannerTitle(text: "PAUSED")
                    .offset(y: -24)
            }
            .frame(maxWidth: 330)
        }
    }
}

#Preview {
    ContentView()
}
