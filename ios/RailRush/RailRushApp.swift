//
//  RailRushApp.swift
//  RailRush
//
//  Created by Rork on July 2, 2026.
//

import SwiftUI

@main
struct RailRushApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Must run before any store reads UserDefaults: replays the on-disk
        // backup if the defaults database was lost or wiped.
        SaveDataService.shared.restoreIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Snapshot all progress whenever the app leaves the foreground so
            // a force-quit or crash never loses the latest save data.
            if newPhase == .background || newPhase == .inactive {
                SaveDataService.shared.backupNow()
            }
        }
    }
}
