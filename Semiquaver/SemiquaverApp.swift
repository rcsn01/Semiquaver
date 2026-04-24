//
//  SemiquaverApp.swift
//  Semiquaver
//
//  Created by Ivan on 24/4/2026.
//

import SwiftUI

@main
struct SemiquaverApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        AppMusicDirectory.ensureExists()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                AppMusicDirectory.ensureExists()
            }
        }
    }
}
