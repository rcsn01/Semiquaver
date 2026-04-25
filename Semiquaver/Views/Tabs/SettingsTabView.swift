import SwiftUI

struct SettingsTabView: View {
    @State private var playVideoFullscreen = true
    @State private var enableTextScrolling = false
    @State private var rememberPlayerState = true
    @State private var restoreLastPlayedMedia = false
    @State private var showFilesOpenHelp = false
    @ObservedObject var player: AudioPlayerController

    var body: some View {
        ZStack {
            PlayerBackground()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 0) {
                        sectionHeader("Appearance")

                        SettingsLinkRow(
                            title: "Theme",
                            subtitle: "Automatic"
                        )

                        Divider().overlay(Color.playerDivider)

                        sectionGap

                        sectionHeader("Playback")

                        SettingsToggleRow(
                            title: "Shuffle new queues",
                            subtitle: "Automatically shuffle when starting new playback",
                            isOn: $player.shuffleByDefault
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsToggleRow(
                            title: "Repeat mode",
                            subtitle: "Current: \(player.repeatMode.rawValue)",
                            isOn: .constant(false)
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsToggleRow(
                            title: "Play video fullscreen",
                            subtitle: nil,
                            isOn: $playVideoFullscreen
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsLinkRow(
                            title: "Default playback speed",
                            subtitle: "1.00x"
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsToggleRow(
                            title: "Remember player state",
                            subtitle: "Shuffle and loop settings",
                            isOn: $rememberPlayerState
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsToggleRow(
                            title: "Restore last played media",
                            subtitle: "On app launch",
                            isOn: $restoreLastPlayedMedia
                        )

                        sectionGap

                        sectionHeader("Support")

                        SettingsLinkRow(
                            title: "Make a Donation",
                            subtitle: "Support free and open source multimedia"
                        )

                        sectionGap

                        sectionHeader("Library")

                        Button {
                            openLibraryInFiles()
                        } label: {
                            SettingsLinkRow(
                                title: "Open library in Files",
                                subtitle: "On My iPhone > Semiquaver > Music"
                            )
                        }
                        .buttonStyle(PressScaleButtonStyle())

                        Divider().overlay(Color.playerDivider)

                        SettingsLinkRow(
                            title: "Privacy Policy",
                            subtitle: nil
                        )
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .alert("Open Files to View Library", isPresented: $showFilesOpenHelp) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Open Files and go to On My iPhone > Semiquaver > Music.")
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            Text("Settings")
                .font(.display())
                .foregroundStyle(Color.playerTextPrimary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(Color.playerAccent)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 8)
    }

    private var sectionGap: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: 16)
    }

    private func openLibraryInFiles() {
        guard AppMusicDirectory.ensureExists() != nil else {
            showFilesOpenHelp = true
            return
        }

        guard let filesRootURL = URL(string: "shareddocuments://") else {
            showFilesOpenHelp = true
            return
        }

        UIApplication.shared.open(filesRootURL, options: [:]) { success in
            if !success {
                DispatchQueue.main.async {
                    showFilesOpenHelp = true
                }
            }
        }
    }
}
