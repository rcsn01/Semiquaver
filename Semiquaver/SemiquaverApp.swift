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
    @AppStorage("appTheme") private var appTheme: AppTheme = .automatic

    init() {
        AppMusicDirectory.ensureExists()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appTheme.colorScheme)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                AppMusicDirectory.ensureExists()
            }
        }
    }
}
