import SwiftUI

struct MacSettingsView: View {
    @ObservedObject var model: MacAppModel
    @AppStorage("appTheme") private var theme: AppTheme = .automatic
    @AppStorage("shuffleByDefault") private var shuffleByDefault = false

    var body: some View {
        TabView {
            Form {
                Picker("Theme", selection: $theme) {
                    ForEach(AppTheme.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
            }.padding(20).tabItem { Label("Appearance", systemImage: "paintbrush") }

            Form {
                Toggle("Shuffle new queues by default", isOn: $shuffleByDefault)
                    .onChange(of: shuffleByDefault) { _, value in model.player.shuffleByDefault = value }
                Picker("Repeat", selection: Binding(
                    get: { model.player.repeatMode },
                    set: { model.player.repeatMode = $0 }
                )) {
                    ForEach(RepeatMode.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
            }.padding(20).tabItem { Label("Playback", systemImage: "play.circle") }

            VStack(alignment: .leading, spacing: 12) {
                HStack { Text("Music Folders").font(.headline); Spacer(); Button("Add…") { model.chooseFolders() } }
                if model.locations.records.isEmpty {
                    ContentUnavailableView("No Music Folders", systemImage: "folder", description: Text("Add one or more folders to begin."))
                } else {
                    List(model.locations.records) { record in
                        HStack {
                            Image(systemName: record.status == .available ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(record.status == .available ? .green : .orange)
                                .accessibilityLabel(record.status.rawValue)
                            VStack(alignment: .leading) { Text(record.displayName); Text(record.lastKnownPath).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
                            Spacer()
                            Button("Rescan") { Task { await model.rescan(force: true, only: [record.id]) } }
                            Button("Reveal") { model.locations.reveal(id: record.id) }
                            Button("Relink…") { model.relink(record) }
                            Button("Remove", role: .destructive) { model.removeLocation(record) }
                        }
                    }
                }
                HStack { Spacer(); Button("Rescan Now") { Task { await model.rescan(force: true) } } }
            }.padding(20).tabItem { Label("Library", systemImage: "folder") }

            Form {
                Link("Semiquaver Support", destination: URL(string: "https://github.com/opense")!)
            }.padding(20).tabItem { Label("Support", systemImage: "questionmark.circle") }
        }
        .frame(width: 680, height: 430)
        .onAppear { model.player.shuffleByDefault = shuffleByDefault }
    }
}
