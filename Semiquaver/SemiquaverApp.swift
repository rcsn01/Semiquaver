//
//  SemiquaverApp.swift
//  Semiquaver
//
//  Created by Ivan on 24/4/2026.
//

import SwiftUI

@main
struct SemiquaverApp: App {
    @AppStorage("appTheme") private var appTheme: AppTheme = .automatic

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appTheme.colorScheme)
        }
    }
}
