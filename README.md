# BEAT RUNNER 🎵👟

**A Subway Surfers–style 3D endless runner for iOS, built entirely with SwiftUI + RealityKit.**

Sprint through a graffiti-covered street-music festival city, dodge trains and security guards, collect music-note coins, chain combos, and climb the season pass — all wrapped in a chunky, glossy 3D cartoon sticker aesthetic.

> 100% Swift. No game engine, no third-party dependencies. The whole game — rendering, gameplay, UI, audio, persistence — runs on Apple's native frameworks.

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Requirements](#requirements)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Game Systems](#game-systems)
- [Asset Pipeline](#asset-pipeline)
- [Save System](#save-system)
- [Design Language](#design-language)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

---

## Features

### Core Gameplay
- 🏃 **3-lane endless runner** — swipe left/right to change lanes, swipe up to jump, swipe down to slide
- 🚇 **Procedurally assembled track** — subway trains, boxcars, barriers, and hang-bars spawn in escalating difficulty waves
- 🎵 **Music-note coins** — collectible gold coins with a custom 3D music-note model and satisfying pickup effects
- 🔥 **Combo system** — chain coin pickups within a 2-second window; combo banner tiers up (gold → teal → magenta → orange) from x3 upward; crashing breaks the chain
- 📏 **Distance tracking** — a HUD progress bar with a sneaker marker races toward 500 m milestones; distance is measured in raw meters, independent of score multipliers

### Power-Ups
- 🧲 **Coin Magnet** — pulls nearby coins in with an accelerating swirl-and-shrink animation and a teal burst
- 👟 **Super Sneakers** — higher jumps
- 🚀 **Jetpack** — soar above the track with a looping thruster sound
- ⭐ **2x Score Multiplier**
- 🎨 **Paint Rush** — a coin-frenzy sprint mode (magnet-assisted)

### Meta Game
- 🧍 **Playable characters** — fully animated 3D runners (idle, run, jump, slide, knock-down, bar-hang) with an unlock/purchase flow
- 🎯 **Missions** — daily and season mission boards (jump, slide, score, timed challenges)
- 🏆 **Season pass** — season levels, rewards, and a "Season Hunt" event
- 🛍️ **Store** — coins, offers, power-up upgrades, and mystery boxes
- 🎁 **Daily login rewards** and events hub
- 🥇 **Records** — best score, best distance, and best combo, shown on the game-over screen

### Polish
- 🎧 **Dynamic soundtrack** — multiple music tracks with auto-advance and in-game track switching
- 📳 **Haptic feedback** on taps, pickups, crashes, and power-ups
- 🎨 **60+ hand-generated 3D sticker art icons** — every content icon in the app is a glossy cartoon sticker; small functional glyphs stay SF Symbols for legibility
- 🛟 **Bulletproof fallbacks** — every generated asset (3D model, image, audio) has a procedural or SF Symbol fallback, so a missing asset never breaks the UI or crashes the game

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift (strict concurrency, `MainActor` default isolation) |
| UI | SwiftUI |
| 3D Rendering & Gameplay | RealityKit (`RealityView`) |
| 3D Assets | USDZ models with baked animations |
| Audio | AVFoundation (`AVAudioPlayer`) |
| Haptics | UIKit feedback generators |
| Persistence | `UserDefaults` + binary plist backup (two-tier save system) |
| Icons | Generated 3D sticker art + SF Symbols fallback |
| Dependencies | **None** — pure Apple frameworks |

---

## Requirements

- **Xcode 16+**
- **iOS 18.0+** deployment target
- A physical device is recommended for the full experience (haptics, performance); the simulator works fine for development

---

## Getting Started

1. **Clone the repository**

   ```bash
   git clone <your-repo-url>
   cd <repo>
   ```

2. **Open the Xcode project**

   ```bash
   open ios/RailRush.xcodeproj
   ```

3. **Set your signing team** — select the `RailRush` target → *Signing & Capabilities* → choose your development team, and change the bundle identifier if needed.

4. **Build & run** (`⌘R`) on a simulator or device. That's it — there are no packages to resolve and no configuration files to fill in.

---

## Project Structure

```text
ios/
├── RailRush/
│   ├── RailRushApp.swift            # @main entry — restores save backup, snapshots on background
│   ├── ContentView.swift            # Root phase router (loading → home → game → game over)
│   │
│   ├── Game/                        # The "engine" layer (RealityKit)
│   │   ├── RunnerWorld.swift        # Core game world: entity spawning, physics, collisions,
│   │   │                            #   lane logic, coins, power-ups, combo & distance tracking
│   │   ├── TrackBuilder.swift       # Procedural track segment assembly
│   │   └── GeneratedAssets.swift    # Registry of generated 3D models + orientation config
│   │
│   ├── ViewModels/
│   │   ├── GameState.swift          # Run lifecycle, score, combo, distance, records
│   │   └── MetaState.swift          # Meta hub: wallet, characters, missions, season,
│   │                                #   settings, music track sync
│   │
│   ├── Models/
│   │   ├── GameModels.swift         # Gameplay value types
│   │   └── MetaModels.swift         # Store items, missions, characters, events
│   │
│   ├── Services/
│   │   ├── AudioService.swift       # Music + SFX playback, track auto-advance
│   │   ├── HapticsService.swift     # Centralized haptic feedback
│   │   ├── MetaStore.swift          # Meta progression persistence (beatrunner.* keys)
│   │   ├── ScoreStore.swift         # Records persistence (railrush.* keys)
│   │   └── SaveDataService.swift    # Two-tier backup/restore save system
│   │
│   ├── Utilities/
│   │   ├── GeneratedModelSupport.swift          # USDZ loading, orientation fixes, scaling
│   │   └── GeneratedModelAnimationPlayer.swift  # Animation clip playback for characters
│   │
│   ├── Views/                       # All SwiftUI screens
│   │   ├── GameView.swift           # RealityView host + gesture input
│   │   ├── HUDView.swift            # In-run HUD: score, combo banner, distance bar
│   │   ├── HomeView.swift           # Main menu
│   │   ├── LoadingView.swift        # Animated boot screen
│   │   ├── GameOverView.swift       # Results, records, revive/restart
│   │   ├── CharactersView.swift     # Character select & unlock
│   │   ├── StoreView.swift          # Store tabs (offers, coins, power-ups, mystery)
│   │   ├── MissionsView.swift       # Daily & season missions
│   │   ├── RewardsViews.swift       # Reward chests & login rewards
│   │   ├── MeEventsSettingsViews.swift  # Profile, events hub, settings
│   │   ├── GameUIKit.swift          # Design system: GameTheme, OutlinedText, GameLogo,
│   │   │                            #   AssetIcon (with SF Symbol fallback), panels, buttons
│   │   └── MetaUIKit.swift          # Meta-screen shared components
│   │
│   ├── Resources/                   # ~50 bundled assets: USDZ models (characters + anims,
│   │                                #   trains, buildings, props) and MP3 music/SFX
│   └── Assets.xcassets/             # 60+ generated sticker art icons, logo, app icon
│
├── RailRushTests/                   # Unit test target
└── RailRushUITests/                 # UI test target
```

---

## Architecture

The project follows **MVVM** with a clean separation between the RealityKit game world and the SwiftUI shell:

```text
┌───────────────────────────────────────────────────┐
│                   SwiftUI Views                   │
│   (HomeView, HUDView, StoreView, GameOverView…)   │
└───────────────▲───────────────────▲───────────────┘
                │ observes          │ observes
┌───────────────┴───────┐   ┌───────┴───────────────┐
│      GameState        │   │      MetaState        │
│  run lifecycle, score │   │ wallet, missions,     │
│  combo, distance      │   │ season, settings      │
└───────────────▲───────┘   └───────▲───────────────┘
                │ callbacks         │ reads/writes
┌───────────────┴───────┐   ┌───────┴───────────────┐
│     RunnerWorld       │   │  MetaStore/ScoreStore │
│  RealityKit entities, │   │  UserDefaults         │
│  spawning, collisions │   │  + SaveDataService    │
└───────────────────────┘   └───────────────────────┘
```

- **`RunnerWorld`** owns the RealityKit scene: entity pooling (70-coin pool), track segment recycling, collision detection, lane/jump/slide state machines, and power-up timers. It reports events (coin picked up, crash, distance tick) upward via callbacks.
- **`GameState`** is the run-scoped observable: phase (`menu → running → gameOver`), score, combo counters, and record-keeping on `finishRun`.
- **`MetaState`** is the app-scoped observable hub for everything outside a run.
- **Everything UI-facing is `@MainActor`** (project-wide default isolation); data types and background work opt out with `nonisolated`.

---

## Game Systems

### Combo System
Picking up coins within a rolling **2-second window** builds a combo. The HUD banner appears at **x3** and escalates through color tiers (gold → teal → magenta → orange). Hitting an obstacle breaks the chain. Your best combo per run is recorded and shown on the game-over screen.

### Distance & Records
Distance accumulates in raw world meters, deliberately independent of score multipliers. The HUD shows a progress bar toward the next **500 m** milestone with a sneaker marker and checkered-flag goal. Best score, best distance, and best combo persist across sessions.

### Coin Magnet
When the magnet is active, coins inside the attraction radius ramp toward the player with increasing pull speed, a swirl offset, and a shrink-out, finishing with a teal particle burst. Teal is the magnet's signature color throughout the UI.

### Music
`AudioService` manages a multi-track soundtrack with automatic track advance (the next song starts when one ends, and the selection syncs back to the settings screen). SFX (coin ding, jump whoosh, crash clang, jetpack loop, power-up pop) play through a lightweight player pool.

---

## Asset Pipeline

All art was AI-generated and then hand-integrated with strict conventions:

- **3D models (USDZ)** are registered in `GeneratedAssets.swift` with per-model orientation metadata (e.g. `frontAxis`) so models face the right way regardless of how they were exported. Symmetric models (like the coin) are marked directionless and skip yaw correction.
- **Character animations** ship as separate USDZ clips (`*-anim-idle`, `*-anim-jump-run`, …) loaded and blended by `GeneratedModelAnimationPlayer`.
- **2D sticker icons** live in `Assets.xcassets` and render through the `AssetIcon` component, which takes a `fallbackSymbol:` — if the image is missing, an SF Symbol renders instead. **The UI can never break from a missing asset.**
- **The game logo** is a generated graffiti lockup with a code-drawn `OutlinedText` fallback.
- 3D gameplay objects follow the same rule: if a USDZ fails to load, procedural geometry stands in.

---

## Save System

A defensive **two-tier** persistence design in `SaveDataService`:

1. **Primary:** all progression lives in `UserDefaults` under two namespaces — `beatrunner.*` (meta: wallet, missions, season, settings) and `railrush.*` (records).
2. **Backup:** every key in those namespaces is snapshotted to a **binary plist** at `Application Support/BeatRunner/beatrunner_save.plist` (atomic writes) — after every finished run and whenever the app leaves the foreground.
3. **Restore:** on launch, *before any store reads*, if the sentinel key is missing (fresh install or wiped defaults) the backup is replayed into `UserDefaults`. The sentinel guard ensures an old backup never overwrites newer live data.

---

## Design Language

- **Palette:** deep purple canvas, hot magenta + gold-orange accents, teal for magnet/energy — committed and consistent via `GameTheme`.
- **Type & shapes:** chunky outlined display text (`OutlinedText`), thick borders, hard offset shadows, slight rotations — a playful "street sticker" feel.
- **Motion:** squish-on-press buttons (`PressableButtonStyle`) with haptic taps, animated combo banners, progress bars, and pickup effects.
- **Rule of thumb:** content icons are 3D sticker art; small functional glyphs (checkmarks, arrows, play/pause) stay SF Symbols for clarity.

---

## Testing

Unit and UI test targets are included:

```bash
xcodebuild test \
  -project ios/RailRush.xcodeproj \
  -scheme RailRush \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Contributing

Contributions are welcome! A few ground rules that keep this codebase healthy:

1. **No third-party dependencies** — part of the point of this project is showing what pure SwiftUI + RealityKit can do.
2. **Every asset needs a fallback** — new icons go through `AssetIcon` with a `fallbackSymbol:`; new 3D models need a procedural stand-in.
3. **Keep gameplay and UI changes separate** — don't touch collision/speed tuning in a UI-only PR.
4. **Modern APIs only** — `NavigationStack`, `.foregroundStyle`, `@Observable`; no deprecated SwiftUI.
5. Run a clean build before opening a PR; the project builds warning-clean.

Good first issues: new mission types, additional track segment patterns, new power-ups, Game Center leaderboards, localization.

---

## License

Choose a license before publishing (MIT is a common choice for projects like this). Add a `LICENSE` file at the repository root.

> **Note on assets:** the bundled 3D models, music, and icons were AI-generated for this project. If you fork and redistribute, verify the asset licensing terms fit your use case.

---

*Built with ❤️ using Rork — SwiftUI, RealityKit, and nothing else.*
