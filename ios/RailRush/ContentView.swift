import SwiftUI

/// Root view: the 3D world stays mounted while overlays switch with the phase.
/// Meta screens (missions / store / characters / ...) layer over the home hub.
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
                        onRun: { world.startRun() }
                    )
                    .transition(.opacity)
                    // Fully covered by an opaque meta screen — fade the home
                    // layer out so it stops compositing behind the overlay.
                    .opacity(gameState.meta.route?.coversScene == true ? 0 : 1)

                    metaOverlay(world: world)
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
                    .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: gameState.phase)
        .animation(.spring(duration: 0.4), value: gameState.meta.route)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear {
            if world == nil {
                world = RunnerWorld(state: gameState)
            }
        }
        .onChange(of: gameState.meta.batterySaver) { _, _ in
            world?.applyBatterySaver()
        }
    }

    /// Full-screen meta destinations and reward dialogs over the home hub.
    @ViewBuilder
    private func metaOverlay(world: RunnerWorld) -> some View {
        let meta = gameState.meta

        if let route = meta.route {
            if route.coversScene {
                // Stable host identity: switching bottom-nav tabs swaps the
                // content inside with a quick crossfade instead of flying two
                // heavy full screens past each other at once.
                MetaRouteHost(route: route, state: gameState, world: world)
                    .zIndex(1)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Group {
                    if route == .dailyLogin {
                        DailyLoginView(meta: meta) { meta.route = nil }
                    } else {
                        FreeRewardsView(meta: meta) { meta.route = nil }
                    }
                }
                .zIndex(1)
                .transition(.opacity)
            }
        }
    }
}

/// Hosts full-screen meta destinations behind one stable view identity.
/// Opening from home keeps the fly-up transition, but tab-to-tab switches only
/// crossfade the inner content — far cheaper than transitioning two complete
/// screens (graffiti wall + dozens of outlined labels each) simultaneously.
private struct MetaRouteHost: View {
    let route: MetaRoute
    let state: GameState
    let world: RunnerWorld

    var body: some View {
        ZStack {
            switch route {
            case .missions:
                MissionsView(meta: state.meta)
            case .store(let tab):
                StoreView(meta: state.meta, initialTab: tab)
                    .id(tab)
            case .characters:
                CharactersView(
                    meta: state.meta,
                    selectedID: state.selectedCharacterID,
                    onSelect: { world.selectCharacter($0) }
                )
            case .me:
                MeView(state: state, meta: state.meta)
            case .events:
                EventsView(meta: state.meta)
            case .settings:
                SettingsView(meta: state.meta)
            case .dailyLogin, .freeRewards:
                EmptyView()
            }
        }
        // Snappy, opacity-only swap between tabs — overrides the heavier
        // outer spring for content changes inside the host.
        .animation(.easeOut(duration: 0.18), value: route)
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
