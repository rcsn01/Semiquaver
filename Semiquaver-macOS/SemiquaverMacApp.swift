import SwiftUI

@main
struct SemiquaverMacApp: App {
    @StateObject private var model: MacAppModel
    @AppStorage("appTheme") private var theme: AppTheme = .automatic

    init() {
        _model = StateObject(wrappedValue: MacAppModel())
    }

    var body: some Scene {
        Window("Semiquaver", id: "main") {
            MacContentView(model: model).preferredColorScheme(theme.colorScheme)
        }
        .defaultSize(width: 1050, height: 700)
        .commands { MacCommands(model: model) }

        Settings { MacSettingsView(model: model).preferredColorScheme(theme.colorScheme) }
    }
}

private struct MacCommands: Commands {
    let model: MacAppModel
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Add Library Folder…") { model.chooseFolders() }.keyboardShortcut("o")
            Button("Rescan Library") { Task { await model.rescan(force: true) } }.keyboardShortcut("r")
        }
        CommandMenu("Playback") {
            Button("Play/Pause") { model.player.togglePlayPause() }.keyboardShortcut(.space, modifiers: [])
            Button("Previous") { model.player.playPrevious() }.keyboardShortcut(.leftArrow, modifiers: .command)
            Button("Next") { model.player.playNext() }.keyboardShortcut(.rightArrow, modifiers: .command)
            Button("Toggle Queue") { model.isQueueVisible.toggle() }.keyboardShortcut("u")
        }
        CommandGroup(after: .textEditing) {
            Button("Search Library") { NotificationCenter.default.post(name: .focusLibrarySearch, object: nil) }.keyboardShortcut("f")
        }
    }
}
